#!/usr/bin/env bash

IGNORE_NO_QTWEBKIT=yes source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q -O - 'https://launchpad.net/ubuntu/quantal/+source/qt4-x11' | sed -n 's/^.*current\ release\ (\(.*\)-\(.*\)).*$/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "http://get.qt.nokia.com/qt/source/" -O - | sed -n 's/.*>qt-everywhere-opensource-src-\(.*\)\.tar\.gz<.*/\1/p' | tail -n 1)

echo ""

echo -e "PKGBUILD version: ${_actual_ver} ${_ubuntu_rel}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
