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
  default = "x86-24.04-NPB3.4-OMP"
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
  accelerator      = "kvm"
  boot_command     = ["e<wait>",
                      "<down><down><down>",
                      "<end><bs><bs><bs><bs><wait>",
                      "autoinstall  ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
                      "<f10><wait>"
                    ]
  cpus             = "4"
  disk_size        = "10G"
  format           = "raw"
  headless         = "true"
  http_directory   = "http/x86"
  iso_url          = "https://old-releases.ubuntu.com/releases/noble/ubuntu-24.04-live-server-amd64.iso"
  iso_checksum     = "sha256:8762f7e74e4d64d72fceb5f70682e6b069932deedb4949c6975d0f0fe0a91be3"
  output_directory = "x86-disk-image-24-04"
  memory           = "8192"
  qemu_binary      = "/usr/bin/qemu-system-x86_64"
  qemuargs         = [["-cpu", "host"], ["-display", "none"]]
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
    source      = "files/exit.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/x86/gem5_init.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/x86/after_boot.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/serial-getty@.service"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["scripts/x86/post-installation.sh"]
    environment_vars = ["ISA=x86"]
  }

  provisioner "file" {
    destination = "/home/gem5/NPB3.4-OMP"
    source      = "files/x86/NPB3.4-OMP-custom-makefile"
  }
}
