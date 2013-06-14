#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${pkgver}"
echo -e "Upstream version:   $(get_gnome_version glib 2.37)"
echo -e "Arch Linux version: $(get_archlinux_version glib2 core x86_64)"
echo -e "Ubuntu version:     $(get_ubuntu_version glib2.0 ${1:-saucy})"
