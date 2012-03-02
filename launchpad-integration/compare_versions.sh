#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/launchpad-integration' -O - | sed -n 's/.*>launchpad-integration_\(.*\)\.tar\.gz<.*/\1/p'))

#echo "Getting latest upstream version..."
#UPSTREAM_VER=$(wget -q 'https://launchpad.net/launchpad-integration/+download' -O - | sed -n 's/.*launchpad-integration-\(.*\)\.tar\.bz2.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver}"
#echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
