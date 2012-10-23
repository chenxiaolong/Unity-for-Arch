#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q -O - 'https://launchpad.net/ubuntu/quantal/+source/check' | sed -n 's/^.*current\ release\ (\(.*\)-\(.*\)).*$/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q 'http://sourceforge.net/projects/check/files/check/' -O - | sed -n 's/.*Download check-\(.*\)\.tar\.gz (.*/\1/p')

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
