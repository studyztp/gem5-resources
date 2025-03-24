#!/bin/bash

# Copyright (c) 2024 The Regents of the University of California.
# SPDX-License-Identifier: BSD 3-Clause

echo 'Post Installation Started'

# Installing the packages in this script instead of the user-data
# file dueing ubuntu autoinstall. The reason is that sometimes
# the package install failes. This method is more reliable.
echo 'installing packages'
apt-get update
apt-get install -y scons
apt-get install -y git
apt-get install -y vim
apt-get install -y build-essential

echo "Installing serial service for autologin after systemd"
mv /home/gem5/serial-getty@.service /lib/systemd/system/

# Make sure the headers are installed to extract the kernel that DKMS
# packages will be built against.
sudo apt -y install "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"

echo "Extracting linux kernel $(uname -r) to /home/gem5/vmlinux-x86-ubuntu"
sudo bash -c "/usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux /boot/vmlinuz-$(uname -r) > /home/gem5/vmlinux-x86-ubuntu"

echo "Installing the gem5 init script in /sbin"
mv /home/gem5/gem5_init.sh /sbin
mv /sbin/init /sbin/init.old
ln -s /sbin/gem5_init.sh /sbin/init

# Add after_boot.sh to bashrc in the gem5 user account
# This will run the script after the user automatically logs in
echo -e "\nif [ -z \"\$AFTER_BOOT_EXECUTED\" ]; then\n   export AFTER_BOOT_EXECUTED=1\n    /home/gem5/after_boot.sh\nfi\n" >> /home/gem5/.bashrc

# Remove the motd
rm /etc/update-motd.d/*

# Build and install the gem5-bridge (m5) binary, library, and headers
echo "Building and installing gem5-bridge (m5) and libm5"

# Ensure the ISA environment variable is set
if [ -z "$ISA" ]; then
  echo "Error: ISA environment variable is not set."
  exit 1
fi

# Just get the files we need
git clone https://github.com/gem5/gem5.git --depth=1 --filter=blob:none --no-checkout --sparse --single-branch --branch=stable
pushd gem5
# Checkout just the files we need
git sparse-checkout add util/m5
git sparse-checkout add include
git checkout
# Install the headers globally so that other benchmarks can use them
cp -r include/gem5 /usr/local/include/\

# Build the library and binary
pushd util/m5
scons build/${ISA}/out/m5
cp build/${ISA}/out/m5 /usr/local/bin/
cp build/${ISA}/out/libm5.a /usr/local/lib/
popd   # util/m5
popd   # gem5

# rename the m5 binary to gem5-bridge
mv /usr/local/bin/m5 /usr/local/bin/gem5-bridge
# Set the setuid bit on the m5 binary
chmod 4755 /usr/local/bin/gem5-bridge
chmod u+s /usr/local/bin/gem5-bridge

#create a symbolic link to the gem5 binary for backward compatibility
ln -s /usr/local/bin/gem5-bridge /usr/local/bin/m5

# delete the git repo for gem5
rm -rf gem5
echo "Done building and installing gem5-bridge (m5) and libm5"

# You can extend this script to install your own packages here or by modifying the `x86-ubuntu.pkr.hcl`
# or `arm-ubuntu.pkr.hcl` file depending on the disk you are building.

# Install nugget-protocol-NPB ==========================================
echo "Installing nugget-protocol-NPB"

echo "Installing LLVM 18, clang-18, flang-18, python3-pip, python3.12-venv, gfortran, libomp-dev"
sudo apt-get -y install llvm-18 clang-18 flang-18 python3-pip python3.12-venv gfortran libomp-dev

echo "Creating a virtual environment for cmake"
python3 -m venv cmake-env

echo "Activating the virtual environment"
source cmake-env/bin/activate

echo "Installing cmake"
pip3 install cmake

export LD_LIBRARY_PATH=/usr/lib/llvm-18/lib

# not using --recurse-submodules because nugget_util is a ssh submodule
git clone https://github.com/darchr/nugget-protocol-NPB.git --single-branch --branch=saphir-based-experiments
cd nugget-protocol-NPB
# change to use the http submodule
git config --file .gitmodules submodule.nugget_util.url https://github.com/studyztp/nugget_util.git 
git submodule update --init --recursive

cd nugget_util
# first, we build the llc-command guide for this system
cd cmake/check-cpu-features/
export LLVM_BIN=/usr/lib/llvm-18/bin
export LLVM_LIB=/usr/lib/llvm-18/lib
export LLVM_INCLUDE=/usr/lib/llvm-18/include
make 
./check-cpu-features

# then, we build the gem5-bridge for the linking of the hooks
cd ../../hook_helper/other_tools/gem5/
ISAS=${ISA} ./get-gem5-util.sh

# now we return to the base of the repo
cd ../../../../
# we need to replace the base-config with the one that matches this system's library layout
cp /home/gem5/base_config.cmake experiments/cmake/base_config.cmake

# lastly, we build the nugget-protocol-NPB
cd cbuild
NUGGET_PROCESS_TYPE=npb-naive-exe NUGGET_CONFIG_FILE=${PWD}/../experiments/multi-threaded-m5-naive/cmake/naive-exe.cmake cmake ..
cmake --build . --target=m5_naive_exe 

# all built binaries can be found in the cbuild directory
cd llvm-exec
ls */
echo ${PWD}

echo "Done installing nugget-protocol-NPB"

# Finish the installation of the nugget-protocol-NPB ==========================================


# Disable network by default
echo "Disabling network by default"
echo "See README.md for instructions on how to enable network"
if [ -f /etc/netplan/50-cloud-init.yaml ]; then
    mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
elif [ -f /etc/netplan/00-installer-config.yaml ]; then
    mv /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
    netplan apply
fi
# Disable systemd service that waits for network to be online
systemctl disable systemd-networkd-wait-online.service
systemctl mask systemd-networkd-wait-online.service

if [ "${ISA}" = "x86" ]; then
    echo "Disabling systemd services for x86 architecture..."

    # Disable multipathd service
    systemctl disable multipathd.service

    # Disable thermald service
    systemctl disable thermald.service

    # Disable snapd services and socket
    systemctl disable snapd.service snapd.socket

    # Disable unnecessary timers
    systemctl disable apt-daily.timer apt-daily-upgrade.timer fstrim.timer

    # Disable accounts-daemon
    systemctl disable accounts-daemon.service

    # Disable LVM monitoring service
    systemctl disable lvm2-monitor.service

    # Switch default target to multi-user (no GUI)
    systemctl set-default multi-user.target

    # Optionally disable AppArmor if not required
    systemctl disable apparmor.service snapd.apparmor.service

    echo "completed disabling systemd services for x86."
fi

echo "Post Installation Done"
