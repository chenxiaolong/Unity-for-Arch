#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/quantal/source/ibus' -O - | sed -n 's/.*>ibus_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo "Getting latest Arch Linux version..."
ARCHLINUX_VER=($(wget -q 'https://www.archlinux.org/packages/community/x86_64/ibus/' -O - | sed -n '/<title>/ s/^.*ibus\ \(.*\)-\(.*\)\ (.*$/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "https://code.google.com/p/ibus/downloads/list" -O - | sed -n 's/.*ibus-\(.*\).tar.gz.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version:   ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version:   ${UPSTREAM_VER}"
echo -e "Arch Linux version: ${ARCHLINUX_VER[@]}"
echo -e "Ubuntu version:     ${UBUNTU_VER[@]}"
