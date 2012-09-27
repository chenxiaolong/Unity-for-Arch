#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/quantal/source/libqtbamf' -O - | sed -n 's/.*>libqtbamf_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
