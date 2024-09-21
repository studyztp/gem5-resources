#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

PACKER_VERSION="1.10.0"

# This part installs the packer binary on the arm64 machine as we are assuming
# that we are building the disk image on an arm64 machine.
if [ ! -f ./packer ]; then
    mkdir -p packers;
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip;
    unzip packer_${PACKER_VERSION}_linux_arm64.zip;
    rm packer_${PACKER_VERSION}_linux_arm64.zip;
    mv packer packers/;
    mv packers/packer packers/arm-packer;
fi

# make the flash0.sh file
cd ./files
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=flash0.img conv=notrunc
cd ..

# Install the needed plugins
./packers/arm-packer init ./packer-scripts/arm-ubuntu.pkr.hcl

# Build the image with the specified Ubuntu version
./packers/arm-packer build ./packer-scripts/arm-ubuntu.pkr.hcl
