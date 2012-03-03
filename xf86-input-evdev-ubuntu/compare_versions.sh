#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/xserver-xorg-input-evdev' -O - | sed -n 's/.*>xserver-xorg-input-evdev_\(.*\)-\(.*\)\.diff\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q http://xorg.freedesktop.org/releases/individual/driver/ -O - | sed -n 's/.*xf86-input-evdev-\(.*\).tar.bz2.*/\1/p' | tail -n 1)

echo ""

echo -e "PKGBUILD version: ${_actual_ver}${_ubuntu_ver} ${_ubuntu_rel}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
