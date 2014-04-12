#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Downloading Ubuntu 14.04 Source Package Database..."
[ -f Sources.bz2 ] && rm Sources.bz2
[ -f Sources ] && rm Sources
curl -O http://archive.ubuntu.com/ubuntu/dists/trusty/main/source/Sources.bz2
bunzip2 Sources.bz2
PACKAGES=($(grep "Package: language-pack" Sources | sed 's/Package: language-pack-//g'))

printline() {
  COLS=$(tput cols)
  while [ ${COLS} -gt 0 ]; do
    echo -n ${1}
    let COLS--
  done
  echo
}

LINE_THICK=$(printline '=')
LINE_THIN=$(printline '-')

for i in ${PACKAGES[@]}; do
  UBUNTU_VER=$(grep -A2 "Package: language-pack-${i}$" Sources | sed -n 's/^Version: \(.*\)/\1/p')

  PKGBUILD_VER=$(eval "echo \${_ver_${i//-/_}}")

  # Skip non-14.04 packages
  if ! grep -q 14.04 <<< ${UBUNTU_VER}; then
    continue
  fi

  if [[ "${PKGBUILD_VER}" != "${UBUNTU_VER#*:}" ]]; then
    echo "${LINE_THICK}"
    echo "Package: language-pack-${i}"
    echo "${LINE_THIN}"
    echo "PKGBUILD version: ${PKGBUILD_VER}"
    echo "Ubuntu version:   ${UBUNTU_VER}"
  fi
done

rm Sources
