#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q -O - 'https://launchpad.net/ubuntu/quantal/+source/nautilus' | sed -n 's/^.*current\ release\ (\(.*\)-\(.*\)).*$/\1 \2/p'))

echo "Getting latest Arch Linux version..."
ARCHLINUX_VER=($(wget -q 'https://www.archlinux.org/packages/extra/x86_64/nautilus/' -O - | sed -n '/<title>/ s/^.*nautilus\ \(.*\)-\(.*\)\ (.*$/\1 \2/p'))

echo "Getting latest GNOME 3 PPA version..."
PPA_VER=($(wget -q 'http://ppa.launchpad.net/gnome3-team/gnome3/ubuntu/pool/main/n/nautilus/' -O - | sed -n 's/.*>nautilus_\(.*\)-\(.*\)\.debian\.tar\.gz<.*/\1 \2/p' | tail -n 1))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q "http://ftp.gnome.org/pub/GNOME/sources/nautilus/${_actual_ver%.*}/" -O - | sed -n 's/.*>LATEST-IS-\(.*\)<.*/\1/p')

echo ""

echo -e "PKGBUILD version:   ${_actual_ver} ${_ppa_rel}"
echo -e "Upstream version:   ${UPSTREAM_VER}"
echo -e "Arch Linux version: ${ARCHLINUX_VER[@]}"
echo -e "Ubuntu version:     ${UBUNTU_VER[@]}"
echo -e "PPA version:        ${PPA_VER[@]}"
