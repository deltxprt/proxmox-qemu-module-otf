terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}

resource "proxmox_vm_qemu" "qemu_vm" {
  name        = var.specs.name
  target_node = var.specs.node
  cicustom    = "${concat("user=",var.specs.cicustom.user,"network=",var.specs.cicustom.network,"metadata=",var.specs.cicustom.metdata)}" #"user=NAS:snippets/user-debian.yml"
  clone       = var.specs.image
  bios        = var.specs.bios
  tags        = var.specs.tags

  cores   = var.cpu.cores
  sockets = var.cpu.sockets
  numa    = var.cpu.numa
  memory  = var.memory

  smbios {
    serial = "ds=nocloud;h=${var.specs.name}"
  }

# Disks setup
  scsihw = var.disks.controller
  disks {
    virtio {
      virtio0 {
        disk {
          backup  = var.disks.bootdrive.backup
          storage = var.disks.bootdrive.storage
          size    = var.disks.bootdrive.size
        }
      }
      virtio1 {
        disk {
          backup  = var.disks.data.backup
          storage = var.disks.data.storage
          size    = var.disks.data.size
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.disks.cloudinit.storage
        }
      }
    }
  }

# networking
  ipconfig0 = "${concat("ip=",var.network.ip_address,"gw=",var.network.ip_gateway)}" #"ip=10.0.50.79/24,gw=10.0.50.1"
  network {
    bridge   = var.network.bridge
    firewall = var.network.firewall
    model    = var.network.card_model
  }
}

resource "dns_a_record_set" "a_record" {
  zone = concat(var.network.dns,".")
  name = var.specs.name
  addresses = [ 
    var.network.ip_address
   ]
   ttl = 300
}

resource "dns_ptr_record" "ptr_record" {
  zone = concat(split(".", var.network.ip_gateway)[0],".in-addr.arpa")
  name = split(".",var.network.ip_address)[3]
  ptr = concat(var.network.dns, ".")
}