variable "nodes" {
  type = map(object({
    vmid   = number
    ip      = string
    cores   = number
    memory  = number
    disk    = string
    role    = string
  }))
}

variable "pm_api_url" {
  type      = string
  sensitive = true
}

variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_tls_insecure" {
  type    = bool
  default = true
}

variable "target_node" {
  type = string
}

variable "template_name" {
  type = string
}

variable "ssh_key" {
  type      = string
  sensitive = true
}

variable "vm_count" {
  type    = number
  default = 1
}

variable "vm_name" {
  type    = string
  default = "jump-vm"
}

variable "vm_cores" {
  type    = number
  default = 1
}

variable "vm_sockets" {
  type    = number
  default = 1
}

variable "vm_cpu" {
  type    = string
  default = "host"
}

variable "vm_memory" {
  type    = number
  default = 2048
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}

variable "vm_ide_disk_size" {
  type    = string
  default = "2G"
}

variable "vm_storage" {
  type    = string
  default = "local-lvm"
}

variable "vm_bridge" {
  type    = string
  default = "vmbr1"
}

# variable "vm_ip" {
#   type = string
# }

variable "vm_gateway" {
  type = string
  default = "10.67.10.1"
}

variable "vm_ciuser" {
  type = string
  default = "ops"
}

variable "private_key_path" {
  type      = string
  default   = "~/.ssh/promox-tf"
  sensitive = true
}
