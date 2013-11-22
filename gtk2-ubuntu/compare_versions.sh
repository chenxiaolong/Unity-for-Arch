#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${pkgver} ${_ubuntu_rel}"
echo -e "Upstream version:   $(get_gnome_version gtk+ 2.24)"
echo -e "Arch Linux version: $(get_archlinux_version gtk2 extra x86_64)"
echo -e "Ubuntu version:     $(get_ubuntu_version gtk+2.0 ${1:-trusty})"
