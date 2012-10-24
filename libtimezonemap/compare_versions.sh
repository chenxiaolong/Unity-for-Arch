#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q -O - 'https://launchpad.net/ubuntu/quantal/+source/libtimezonemap' | sed -n 's/^.*current\ release\ (\(.*\)).*$/\1/p'))

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
