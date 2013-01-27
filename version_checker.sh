#!/bin/bash

# Do not run this manually

get_ubuntu_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  if [ -z "${2}" ]; then
    echo "No Ubuntu version was provided"
    exit 1
  fi
  if [ "x${3}" == "xnative" ]; then
    wget -q -O - "https://launchpad.net/ubuntu/${2}/+source/${1}" | \
      sed -n 's/^.*current\ release\ (\(.*\)).*$/\1/p'
  else
    wget -q -O - "https://launchpad.net/ubuntu/${2}/+source/${1}" | \
      sed -n 's/^.*current\ release\ (\(.*\)-\(.*\)).*$/\1 \2/p'
  fi
}

get_launchpad_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  local PACKAGE=${1}
  local TARBALL=${1}
  if [ ! -z "${2}" ]; then
    TARBALL=${2}
  fi
  wget -q -O - "https://launchpad.net/${PACKAGE}/+download" | \
    sed -n "s/.*${TARBALL}[-_]\+\(.*\)\.tar.*/\1/p" | head -n 1
}

get_pypi_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  wget -q -O - "http://pypi.python.org/pypi/${1}" | \
    sed -n "s/.*>${1}-\(.*\)\.\(tar\.\|zip\).*<.*/\1/p" | head -n 1
}

get_gnome_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  if [ -z "${2}" ]; then
    echo "No major version was provided"
    exit 1
  fi
  wget -q -O - "http://ftp.gnome.org/pub/GNOME/sources/${1}/${2}/" | \
    sed -n 's/.*>LATEST-IS-\(.*\)<.*/\1/p'
}

get_archlinux_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  if [ -z "${2}" ]; then
    echo "No repository was provided"
    exit 1
  fi
  if [ -z "${3}" ]; then
    echo "No architecture was provided"
    exit 1
  fi
  wget -q -O - "https://www.archlinux.org/packages/${2}/${3}/${1}/" | \
    sed -n "/<title>/ s/^.*${1}\ \(.*\)-\(.*\)\ (.*$/\1 \2/p"
}

get_xorg_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  if [ -z "${2}" ]; then
    echo "No category was provided"
    exit 1
  fi
  wget -q -O - "http://xorg.freedesktop.org/releases/individual/${2}/" |
    sed -n "s/.*${1}-\(.*\)\.tar.*/\1/p" | tail -n 1
}

get_ppa_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  if [ -z "${2}" ]; then
    echo "No PPA was provided"
    exit 1
  fi
  wget -q -O - \
    "http://ppa.launchpad.net/${2/#ppa:/}/ubuntu/pool/main/${1:0:1}/${1}/" | \
    sed -n "s/.*>${1}_\(.*\)-\(.*\)\.\(debian\|diff\)\.[a-z\.]\+<.*/\1 \2/p" | \
    tail -n 1
}

get_qt4_version() {
  wget -q -O - 'http://releases.qt-project.org/qt4/source/' | \
    sed -n 's/.*>\ qt-everywhere-opensource-src-\(.*\)\.tar\.gz<.*/\1/p' | \
    tail -n 1
}

get_freedesktop_version() {
  if [ -z "${1}" ]; then
    echo "No package was provided"
    exit 1
  fi
  wget -q -O - "http://cgit.freedesktop.org/${1}/" | \
    sed -n "s/.*>${1}-\(.*\)\.tar\.gz<.*/\1/p" | head -n 1
}
