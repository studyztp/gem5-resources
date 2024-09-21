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
  default = "arm-24.04-NPB3.4-OMP"
}

variable "ssh_password" {
  type    = string
  default = "12345"
}

variable "ssh_username" {
  type    = string
  default = "gem5"
}

variable "use_kvm" {
  type    = string
  default = "true"
  validation {
    condition     = contains(["true", "false"], var.use_kvm)
    error_message = "KVM option must be either 'true' or 'false'."
  }
}

locals {
  qemuargs_base = [
    ["-boot", "order=dc"],
    ["-bios", "./files/flash0.img"],
    ["-machine", "virt"],
    ["-machine", "gic-version=3"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
  ]

  qemuargs_kvm = concat(local.qemuargs_base,[
    ["-cpu", "host"],
    ["-enable-kvm"]
  ])

  qemuargs_no_kvm = concat(local.qemuargs_base,[
    ["-cpu", "cortex-a57"]
  ])

  qemuargs = var.use_kvm == "true" ? local.qemuargs_kvm : local.qemuargs_no_kvm
}

source "qemu" "initialize" {
  boot_command     = [
                      "c<wait>",
                      "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ --- ",
                      "<enter><wait>",
                      "initrd /casper/initrd",
                      "<enter><wait>",
                      "boot",
                      "<enter>",
                      "<wait>"
                      ]
  cpus             = "4"
  disk_size        = "10G"
  format           = "raw"
  headless         = "true"
  http_directory   = "http/arm"
  iso_url          = "https://old-releases.ubuntu.com/releases/noble/ubuntu-24.04-live-server-arm64.iso"
  iso_checksum     = "sha256:d2d9986ada3864666e36a57634dfc97d17ad921fa44c56eeaca801e7dab08ad7"
  memory           = "8192"
  output_directory = "arm-disk-image-24-04"
  qemu_binary      = "/usr/bin/qemu-system-aarch64"
  qemuargs         = local.qemuargs
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
    source      = "files/arm/gem5_init.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/arm/after_boot.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/serial-getty@.service"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["scripts/arm/post-installation.sh"]
    environment_vars = ["ISA=arm64"]
    expect_disconnect = true
  }

  provisioner "file" {
    destination = "/home/gem5/NPB3.4-OMP"
    source      = "files/arm/NPB3.4-OMP-custom-makefile"
  }

}
