#!/usr/bin/env bash

source "$(dirname ${0})/PKGBUILD"

echo "Downloading Ubuntu 13.10 Source Package Database..."
[ -f Sources.bz2 ] && rm Sources.bz2
[ -f Sources ] && rm Sources
curl -O http://archive.ubuntu.com/ubuntu/dists/saucy/main/source/Sources.bz2
bunzip2 Sources.bz2
PACKAGES=($(grep "Package: unity-scope" Sources | sed 's/Package: unity-scope-//g'))

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
  UBUNTU_VER=$(grep -A2 "Package: unity-scope-${i}$" Sources | sed -n 's/^Version: \(.*\)/\1/p')

  PKGBUILD_VER=$(eval "echo \${_ver_${i}} \${_rel_${i}}")

  echo "${LINE_THICK}"
  echo "Package: unity-scope-${i}"
  echo "${LINE_THIN}"
  echo "PKGBUILD version: ${PKGBUILD_VER}"
  echo "Ubuntu version:   ${UBUNTU_VER}"
done

rm Sources
