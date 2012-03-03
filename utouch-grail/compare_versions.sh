#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/utouch-grail' -O - | sed -n 's/.*>utouch-grail_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q 'https://launchpad.net/utouch-grail/+download' -O - | sed -n 's/.*utouch-grail-\(.*\)\.tar\.gz.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
