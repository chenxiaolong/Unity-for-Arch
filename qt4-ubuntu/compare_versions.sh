#!/usr/bin/env bash

IGNORE_NO_QTWEBKIT=yes source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version: ${pkgver} Ubuntu ${_ubuntu}"
echo -e "Upstream version: $(get_qt4_version)"
echo -e "Ubuntu version:   $(get_ubuntu_version qt4-x11 ${1:-trusty})"
