#!/bin/bash
sudo apt-get update -q

declare -a PACKAGES=(
    ant
    ant-optional
    asciidoc
    checkinstall
    curl
    cvs
    debhelper
    dh-make
    gawk
    git-core
    git-svn
    gnulib
    libapr1-dev
    libaprutil1-dev
    libcapstone-dev
    libcurl4-openssl-dev
    libdaq-dev
    libdaq2
    libdnet
    libdnet-dev
    libdumbnet-dev
    libdumbnet1
    libfuse-dev
    libghc-regex-posix-prof
    libgl1-mesa-dev
    libglu1-mesa-dev
    libgtkglext1
    libgtkglext1-dev
    libluajit-5.1-2
    libluajit-5.1-dev
    liblzo2-dev
    libncurses5
    libncurses5-dev
    libncurses6
    libncursesw5
    libncursesw5-dev
    libncursesw6
    libnghttp2-dev
    libpcap-dev
    libpopt-dev
    libqt5x11extras5
    libreadline-dev
    librsvg2-2
    librsvg2-dev
    libssl-dev
    libterm-readline-gnu-perl
    libtinfo-dev
    libx11-xcb-dev
    libxcb-xinerama0-dev
    libxi-dev
    libxkbcommon-dev
    libxkbcommon-x11-dev
    libxrender-dev
    libzip-dev
    nasm yasm
    ncurses-dev
    openssl
    pkg-config
    postfix
    python3-pkgconfig
    qtbase5-dev
    reprepro
    sharutils
    ssh
    subversion
    xmlto
)

for PACKAGE in "${PACKAGES[@]}"; do
    sudo apt-get install -y -q "$PACKAGE"
done

## to compile dataset
#sudo apt-get install gcc-multilib
#sudo apt-get install gcc-multilib-arm-linux-gnueabi
#sudo apt-get install gcc-multilib-mipsel-linux-gnu

