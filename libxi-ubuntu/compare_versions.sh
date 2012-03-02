#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/libxi' -O - | sed -n 's/.*>libxi_\(.*\)-\(.*\)\.diff\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q http://xorg.freedesktop.org/releases/individual/lib/ -O - | sed -n 's/.*libXi-\(.*\).tar.bz2.*/\1/p' | tail -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
