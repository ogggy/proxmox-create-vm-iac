#!/usr/bin/env bash
set -euo pipefail

echo "==== [Step 1] Disable swap temporarily"
# Kubernetes requires predictable memory behavior.
# Swap can make kubelet scheduling and memory accounting unreliable.
sudo swapoff -a

echo "==== [Step 2] Disable swap permanently in /etc/fstab"
# Comment out swap entries so swap will not come back after reboot.
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

echo "==== [Step 3] Load required kernel modules"
# overlay: required by container runtimes for layered container images.
# br_netfilter: allows bridged traffic to be processed by iptables/nftables.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "==== [Step 4] Configure Kubernetes networking sysctl settings"
# bridge-nf-call-iptables: allows Kubernetes/CNI traffic on Linux bridges
# to be inspected by iptables.
# ip_forward: allows this node to route packets between interfaces.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "==== [Step 5] Apply sysctl settings"
sudo sysctl --system

echo "==== [Step 6] Install containerd"
# containerd is the container runtime used by kubelet.
sudo apt-get update
sudo apt-get install -y containerd

echo "==== [Step 7] Configure containerd to use systemd cgroup driver"
# kubelet and containerd should use the same cgroup driver.
# systemd is recommended on modern Ubuntu/systemd-based systems.
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

echo "==== [Step 8] Install kubeadm, kubelet, and kubectl"
# kubeadm: bootstraps the cluster
# kubelet: node agent
# kubectl: CLI client
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

echo "==== [Step 9] Hold Kubernetes packages"
# Prevent accidental upgrades that may break version compatibility.
sudo apt-mark hold kubelet kubeadm kubectl

echo "==== [Done] This node is ready for kubeadm."