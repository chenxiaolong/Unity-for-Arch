#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

#echo "Getting latest Ubuntu version..."
#UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/gtk+2.0' -O - | sed -n 's/.*>gtk+2.0_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "http://ftp.gnome.org/pub/gnome/sources/gsettings-desktop-schemas/${pkgver%.*}/" -O - | sed -n 's/.*>LATEST-IS-\(.*\)<.*/\1/p')

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   (n/a)"
