#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version: ${_actual_ver}${_extra_ver} ${_ubuntu_rel}"
echo -e "Upstream version: $(get_googlecode_version googlemock gmock)"
echo -e "Ubuntu version:   $(get_ubuntu_version google-mock ${1:-saucy})"
