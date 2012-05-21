#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise-updates/source/unity-2d' -O - | sed -n 's/.*>unity-2d_\(.*\)-\(.*\)\.diff\.gz<.*/\1 \2/p'))

#echo "Getting latest upstream version..."
#UPSTREAM_VER=$(wget 'https://launchpad.net/unity-2d/+download' -q -O - | sed -n 's/.*unity[-_]\([\.0-9]*[0-9]\).*\.tar\.bz2.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver%.*} ${_ubuntu_rel}"
#echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
