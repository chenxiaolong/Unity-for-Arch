#!/bin/bash

# Note to developers modifying this script: Do not break the script! Please make
# sure that it works for every single package.

# Please add the following to build-in-chroot.conf:
# 
# PACKAGER="Your Name <your@email>"
# GPGKEY=""
# LOCALREPO="/path/to/repo"

################################################################################

if [ -z "${1}" ]; then
  echo "No argument provided!"
  exit 1
fi

if [ ! -f "${1}/PKGBUILD" ]; then
  echo "${1} does not contain PKGBUILD!"
  exit 1
fi

if [ ! -f "$(dirname ${0})/build-in-chroot.conf" ]; then
  echo "$(dirname ${0})/build-in-chroot.conf is missing! Please see the comment in this script."
  exit 1
fi

if [ "x$(whoami)" != "xroot" ]; then
  echo "This script must be run as root!"
  exit 1
fi

source "$(dirname ${0})/build-in-chroot.conf"

set -ex

cleanup() {
  umount ${CHROOT}${LOCALREPO}/ || true &>/dev/null

  # Clean up chroot
  rm -rf ${CHROOT}
  rm -f ${CHROOT}.lock
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

PACKAGE_DIR="$(readlink -f ${1})"
PACKAGE=$(basename ${PACKAGE_DIR})

CHROOT=$(mktemp -d --tmpdir=.)
CHROOT=$(basename ${CHROOT})

RESULT_DIR=/tmp/packages

# Necessary, or the chroot user created below won't be able to execute anything
chmod -R 0755 ${CHROOT}

# Create base chroot
mkarchroot -f ${CHROOT} base base-devel sudo curl

# Set up /etc/makepkg.conf
cat >> ${CHROOT}/etc/makepkg.conf << EOF
INTEGRITY_CHECK=(sha512)
PKGDEST="${RESULT_DIR}"
PACKAGER="${PACKAGER}"
GPGKEY="${GPGKEY}"
EOF

# Set up /etc/pacman.conf if local repo already exists
if [ -f ${LOCALREPO}/Unity-for-Arch.db ]; then
  cat >> ${CHROOT}/etc/pacman.conf << EOF
[Unity-for-Arch]
SigLevel = Optional TrustAll
Server = file://$(readlink -f ${LOCALREPO})
EOF
fi

# Copy packaging
mkdir ${CHROOT}/tmp/${PACKAGE}/
cp -v "${PACKAGE_DIR}/PKGBUILD" ${CHROOT}/tmp/${PACKAGE}/
install=$(bash -c "source ${PACKAGE_DIR}/PKGBUILD && echo \${install}")
sources=$(bash -c "source ${PACKAGE_DIR}/PKGBUILD && echo \${source[@]}")
if [ -f "${install}" ]; then
  cp -v "${PACKAGE_DIR}/${install}" ${CHROOT}/tmp/${PACKAGE}/
fi
for i in ${sources}; do
  if [ -e "${PACKAGE_DIR}/${i}" ]; then
    cp -v "${PACKAGE_DIR}/${i}" ${CHROOT}/tmp/${PACKAGE}/
  fi
done

# Create new user
mkarchroot \
  -r "useradd --create-home --shell /bin/bash --user-group builder" \
  ${CHROOT}

# Fix permissions
mkdir ${CHROOT}${RESULT_DIR}/
mkarchroot -r "chown -R builder:builder ${RESULT_DIR} \
                                        /tmp/${PACKAGE}/" ${CHROOT}

# Make sure the builder user can run "pacman" to install the build dependencies
echo "builder ALL=(ALL) ALL,NOPASSWD: /usr/bin/pacman" \
  > ${CHROOT}/etc/sudoers.d/chrootbuild

# Make sure local repo exists
mkdir -p ${LOCALREPO}/ ${CHROOT}${LOCALREPO}/
mount --bind ${LOCALREPO}/ ${CHROOT}${LOCALREPO}/
if [ -f ${LOCALREPO}/Unity-for-Arch.db ]; then
  mkarchroot -r "pacman -Sy" ${CHROOT}
fi

# Build package
mkarchroot \
  -r "
  su - builder -c 'cd /tmp/${PACKAGE} && \
                   makepkg --clean --syncdeps --check \
                           --sign --noconfirm --nocolor'
  " \
  ${CHROOT}

# Move out packages
rm -f ${LOCALREPO}/*.db*
rm -f ${LOCALREPO}/*.files*
mv ${CHROOT}${RESULT_DIR}/* ${LOCALREPO}/
# TODO: Enable signing
repo-add ${LOCALREPO}/Unity-for-Arch.db.tar.xz ${LOCALREPO}/*.pkg.tar.xz
