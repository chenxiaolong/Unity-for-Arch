#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/quantal/source/xfce4-indicator-plugin' -O - | sed -n 's/.*>xfce4-indicator-plugin_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "http://goodies.xfce.org/projects/panel-plugins/xfce4-indicator-plugin" -O - | sed -n 's/.*xfce4-indicator-plugin-\(.*\)\.tar\.bz2.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
