#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${_actual_ver}${_extra_ver}"
echo -e "Arch Linux version: $(get_archlinux_version ${pkgname%-*} community x86_64)"
echo -e "Ubuntu version:     $(get_ubuntu_version gnome-control-center-signon ${1:-saucy})"
echo -e "Translations:       ${_translations}"
