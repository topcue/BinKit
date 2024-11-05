#!/bin/bash
sudo apt-get update -q

declare -a PACKAGES=(
    autoconf
    autogen
    automake
    binutils
    bison
    build-essential
    cmake
    flex
    gcc-multilib
    git
    gperf
    help2man
    libncurses-dev
    libtool
    libtool-bin
    parallel
    tar
    texinfo
    unzip
    wget
)

for PACKAGE in "${PACKAGES[@]}"; do
    sudo apt-get install -y -q "$PACKAGE"
done

