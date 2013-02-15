#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version:   ${pkgver}"
echo -e "Arch Linux version: $(get_archlinux_version ${_realpkgname} community x86_64)"
