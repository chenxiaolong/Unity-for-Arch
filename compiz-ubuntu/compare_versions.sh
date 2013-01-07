#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q -O - 'https://launchpad.net/ubuntu/raring/+source/compiz' | sed -n 's/^.*current\ release\ (\(.*\)-\(.*\)).*$/\1 \2/p'))

echo ""

echo -e "PKGBUILD version: ${_actual_ver}+bzr${_bzr_rev} ${_ubuntu_rel}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   ${UBUNTU_VER[@]}"
