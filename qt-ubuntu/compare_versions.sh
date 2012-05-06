#!/usr/bin/env bash

IGNORE_NO_QTWEBKIT=yes source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/qt4-x11' -O - | sed -n 's/.*>qt4-x11_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "http://get.qt.nokia.com/qt/source/" -O - | sed -n 's/.*>qt-everywhere-opensource-src-\(.*\)\.tar\.gz<.*/\1/p' | tail -n 1)

echo ""

echo -e "PKGBUILD version: ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
