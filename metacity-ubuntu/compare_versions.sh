#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version:   $(get_gnome_version ${pkgname%-*} 2.34)"
echo -e "Arch Linux version: $(get_archlinux_version ${pkgname%-*} community x86_64)"
echo -e "Ubuntu version:     $(get_ubuntu_version ${pkgname%-*} ${1:-saucy})"
echo -e "Translations:       ${_translations}"
