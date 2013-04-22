#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${pkgver} PPA ${_ppa_ver} ${_ppa_rel}"
echo -e "Upstream version:   $(get_gnome_version ${pkgname%-*} 3.8)"
echo -e "Arch Linux version: $(get_archlinux_version ${pkgname%-*} extra x86_64)"
echo -e "Ubuntu version:     $(get_ubuntu_version ${pkgname%-*} ${1:-raring})"
echo -e "PPA version:        $(get_ppa_version ${pkgname%-*} ppa:gnome3-team/gnome3)"
echo -e "Translations:       ${_translations}"
