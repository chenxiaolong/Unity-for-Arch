#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/quantal/source/unity' -O - | sed -n 's/.*>unity_\(.*\)-\(.*\)\.diff\.gz<.*/\1 \2/p'))

echo "Getting latest upstream version..."
# Please name the tarballs appropriately... previously is was all
# name-version.tar.bz2 and now there's name_version.orig.tar.bz2. Please let the
# debian source naming go in the repos only, not upstream!
UPSTREAM_VER=$(wget 'https://launchpad.net/unity/+download' -q -O - | sed -n 's/.*unity[-_]\([\.0-9]*[0-9]\).*\.tar\.bz2.*/\1/p' | head -n 1)

echo ""

echo -e "PKGBUILD version: ${_actual_ver} ${_ubuntu_rel}"
echo -e "Upstream version: ${UPSTREAM_VER}"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
