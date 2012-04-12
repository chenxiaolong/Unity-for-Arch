#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Getting latest Ubuntu version..."
UBUNTU_VER=($(wget -q 'http://packages.ubuntu.com/precise/source/pulseaudio' -O - | sed -n 's/.*>pulseaudio_\(.*\)-\(.*\)\.diff\.gz<.*/\1 \2/p'))

echo "Getting latest Arch Linux version..."
ARCHLINUX_VER=($(wget -q 'https://www.archlinux.org/packages/extra/x86_64/pulseaudio/' -O - | sed -n '/<title>/ s/^.*pulseaudio\ \(.*\)-\(.*\)\ (.*$/\1 \2/p'))

echo "Getting latest upstream version..."
UPSTREAM_VER=$(wget -q 'http://freedesktop.org/software/pulseaudio/releases/' -O - | sed -n 's/.*pulseaudio-\(.*\).tar.xz.*/\1/p' | tail -n 1)

echo ""

echo -e "PKGBUILD version:   ${pkgver%.*} ${_ubuntu_rel}"
echo -e "Upstream version:   ${UPSTREAM_VER}"
echo -e "Arch Linux version: ${ARCHLINUX_VER[@]}"
echo -e "Ubuntu version:     ${UBUNTU_VER[@]}"
