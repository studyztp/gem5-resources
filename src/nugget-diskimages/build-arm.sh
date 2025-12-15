#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

PACKER_VERSION="1.10.0"

ARCH=$(uname -m)
# Set ARCH to arm64 if the architecture is aarch64
if [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# This part installs the packer binary on the arm64 machine as we are assuming
# that we are building the disk image on an arm64 machine.
if [ ! -f ./packer-binaries/${ARCH}-packer ]; then
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${ARCH}.zip;
    unzip packer_${PACKER_VERSION}_linux_${ARCH}.zip;
    rm packer_${PACKER_VERSION}_linux_${ARCH}.zip;
    mkdir packer-binaries
    mv packer packer-binaries/${ARCH}-packer
fi

# make the flash0.sh file
cd ./files
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=flash0.img conv=notrunc
cd ..

# Install the needed plugins
./packer-binaries/${ARCH}-packer init ./packer-scripts/arm-ubuntu.pkr.hcl

# Build the image with the specified Ubuntu version
./packer-binaries/${ARCH}-packer build ./packer-scripts/arm-ubuntu.pkr.hcl
