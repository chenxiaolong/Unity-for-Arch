#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version: ${_realver}"
echo -e "Upstream version: $(get_launchpad_version dbusmenu libdbusmenu)"
echo -e "Ubuntu version:   $(get_ubuntu_version libdbusmenu ${1:-trusty})"
