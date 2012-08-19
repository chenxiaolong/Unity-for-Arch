#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo ""

echo -e "PKGBUILD version: ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version: (none)"
echo -e "Ubuntu version:   (none)"
