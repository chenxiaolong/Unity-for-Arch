#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"
source "$(dirname ${0})/../version_checker.sh"

echo -e "PKGBUILD version: ${pkgver} ${_ubuntu_rel}"
UPSTREAM_VER=$(wget -q -O - 'http://sourceforge.net/projects/cmusphinx/files/sphinxbase/' | sed -n 's/^.*a href="\/projects\/cmusphinx\/files\/sphinxbase\/\(.*\)\/".*$/\1/p' | head -n 1)
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   $(get_ubuntu_version ${pkgname} ${1:-saucy})"
