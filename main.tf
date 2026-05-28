terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "k8s" {
  for_each = var.nodes

  vmid        = each.value.vmid
  name        = "k8s-${each.key}"
  target_node = var.target_node
  clone       = var.template_name

  agent   = 1
  os_type = "cloud-init"

  cores   = each.value.cores
  sockets = 1
  cpu     = "host"
  memory  = each.value.memory

  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = "scsi0"
    type     = "disk"
    size     = each.value.disk
    storage  = var.vm_storage
    iothread = true
  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.vm_storage
  }

  network {
    model  = "virtio"
    bridge = var.vm_bridge
  }

  ipconfig0 = "ip=${each.value.ip}/24,gw=${var.vm_gateway}"
  ciuser    = var.vm_ciuser
  sshkeys   = var.ssh_key

  provisioner "file" {
    source      = "prepare-k8s-node.sh"
    destination = "/tmp/prepare-k8s-node.sh"

    connection {
      type        = "ssh"
      host        = each.value.ip
      user        = var.vm_ciuser
      private_key = file(var.private_key_path)
    }
  }

  provisioner "remote-exec" {
     inline = [
      "chmod +x /tmp/prepare-k8s-node.sh",
      "sudo bash /tmp/prepare-k8s-node.sh > /tmp/prepare-k8s-node.log 2>&1",
      "grep '^\\==== [Step' /tmp/prepare-k8s-node.log || true",
      "tail -1 /tmp/prepare-k8s-node.log || true"
    ]

    connection {
      type        = "ssh"
      host        = each.value.ip
      user        = var.vm_ciuser
      private_key = file(var.private_key_path)
    }
  }

  tags = each.value.role
}