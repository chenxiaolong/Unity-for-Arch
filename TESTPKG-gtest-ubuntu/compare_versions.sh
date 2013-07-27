#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version: ${pkgver} ${_ubuntu_rel}"
echo -e "Upstream version: $(get_googlecode_version googletest gtest)"
echo -e "Ubuntu version:   $(get_ubuntu_version gtest ${1:-saucy})"
