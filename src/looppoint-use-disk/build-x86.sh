#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

PACKER_VERSION="1.10.0"

if [ ! -f ./x86-packer ]; then
    mkdir -p packers;
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip;
    unzip packer_${PACKER_VERSION}_linux_amd64.zip;
    rm packer_${PACKER_VERSION}_linux_amd64.zip;
    mv packer packers;
    mv packers/packer packers/x86-packer;
fi

# Install the needed plugins
./packers/x86-packer init ./packer-scripts/x86-ubuntu.pkr.hcl

# Build the image with the specified Ubuntu version
./packers/x86-packer build ./packer-scripts/x86-ubuntu.pkr.hcl
