packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "image_name" {
  type    = string
  default = "riscv-24.04-NPB3.4-OMP"
}

variable "ssh_password" {
  type    = string
  default = "12345"
}

variable "ssh_username" {
  type    = string
  default = "gem5"
}

source "qemu" "initialize" {
  cpus             = "4"
  disk_size        = "10G"
  format           = "raw"
  headless         = "true"
  disk_image       = "true"
  boot_command = [
                  "<wait120>",
                  "ubuntu<enter><wait>",
                  "ubuntu<enter><wait>",
                  "ubuntu<enter><wait>",
                  "12345678<enter><wait>",
                  "12345678<enter><wait>",
                  "<wait20>",
                  "sudo adduser gem5<enter><wait10>",
                  "12345<enter><wait10>",
                  "12345<enter><wait10>",
                  "<enter><enter><enter><enter><enter>y<enter><wait>",
                  "sudo usermod -aG sudo gem5<enter><wait>"
                ]
  iso_url          = "./ubuntu-24.04-preinstalled-server-riscv64.img"
  iso_checksum     = "sha256:9f1010bfff3d3b2ed3b174f121c5b5002f76ae710a6647ebebbc1f7eb02e63f5"
  output_directory = "riscv-disk-image-24-04"
  memory           = "8192"
  qemu_binary      = "/usr/bin/qemu-system-riscv64"

  qemuargs       = [  ["-bios", "/usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf"],
                      ["-machine", "virt"],
                      ["-kernel","/usr/lib/u-boot/qemu-riscv64_smode/uboot.elf"],
                      ["-device", "virtio-vga"],
                      ["-device", "qemu-xhci"],
                      ["-device", "usb-kbd"]
                  ]
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  vm_name          = "${var.image_name}"
  ssh_handshake_attempts = "1000"
}

build {
  sources = ["source.qemu.initialize"]


  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/riscv/gem5_init.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/riscv/after_boot.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/riscv/serial-getty@.service"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["scripts/riscv/post-installation.sh"]
  }

  provisioner "file" {
    destination = "/home/gem5/NPB3.4-OMP"
    source      = "files/riscv/NPB3.4-OMP-custom-makefile"
  }

}
