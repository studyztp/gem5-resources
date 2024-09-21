#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

PACKER_VERSION="1.10.0"

if [ ! -f ./packers/x86-packer ]; then
    mkdir -p packers;
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip;
    unzip packer_${PACKER_VERSION}_linux_amd64.zip;
    rm packer_${PACKER_VERSION}_linux_amd64.zip;
    mv packer packers/;
    mv packers/packer packers/x86-packer;
fi

if [ ! -f ./ubuntu-24.04-preinstalled-server-riscv64.img ]; then
    wget https://old-releases.ubuntu.com/releases/noble/ubuntu-24.04-preinstalled-server-riscv64.img.xz
    unxz ubuntu-24.04-preinstalled-server-riscv64.img.xz
fi

# Install the needed plugins
./packers/x86-packer init ./packer-scripts/riscv-ubuntu.pkr.hcl

# Build the image
./packers/x86-packer build ./packer-scripts/riscv-ubuntu.pkr.hcl
