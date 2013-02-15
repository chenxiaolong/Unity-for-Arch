#!/bin/bash

# Please add the following to build-in-chroot.conf:
# 
# PACKAGER="Your Name <your@email>"
# GPGKEY=""
# LOCALREPO="/path/to/repo"

################################################################################

# Note to developers modifying this script: Do not break the script! Please make
# sure that it works for every single package.

# Please make sure that the script:
# * Locks ${LOCALREPO}/cache.lock before touching anything in
#   /var/cache/pacman/pkg/
#   - Separate download actions if necessary
# * Locks ${LOCALREPO}/repo.lock before updating the local repo

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

# Check if the shell is interactive
if tty -s; then
  PROGRESSBAR=""
else
  PROGRESSBAR="--noprogressbar"
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
# TODO: Enable signature verification
if [ -f ${LOCALREPO}/Unity-for-Arch.db ]; then
  cat >> ${CHROOT}/etc/pacman.conf << EOF
[Unity-for-Arch]
SigLevel = Never
Server = file://$(readlink -f ${LOCALREPO})
EOF
fi

# Copy packaging
mkdir ${CHROOT}/tmp/${PACKAGE}/
cp -v "${PACKAGE_DIR}/PKGBUILD" ${CHROOT}/tmp/${PACKAGE}/
install=$(bash -c "source ${PACKAGE_DIR}/PKGBUILD && echo \${install}")
sources=$(bash -c "source ${PACKAGE_DIR}/PKGBUILD && echo \${source[@]}")
extrafiles=$(bash -c "source ${PACKAGE_DIR}/PKGBUILD && echo \${extrafiles[@]}")
if [ -f "${PACKAGE_DIR}/${install}" ]; then
  cp -v "${PACKAGE_DIR}/${install}" ${CHROOT}/tmp/${PACKAGE}/
fi
for i in ${sources}; do
  if [ -f "${PACKAGE_DIR}/${i}" ]; then
    cp -v "${PACKAGE_DIR}/${i}" ${CHROOT}/tmp/${PACKAGE}/
  fi
done
for i in ${extrafiles}; do
  cp -v "${PACKAGE_DIR}/${i}" ${CHROOT}/tmp/${PACKAGE}/
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
  (
    flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)
    mkarchroot -r "pacman -Sy ${PROGRESSBAR}" ${CHROOT}
  ) 321>${LOCALREPO}/cache.lock
fi

# Download sources and install build dependencies
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)
  mkarchroot \
    -r "
    su - builder -c 'cd /tmp/${PACKAGE} && \
                     makepkg --syncdeps --nobuild --nocolor --noconfirm \
                             ${PROGRESSBAR}'
    " \
    ${CHROOT}
) 321>${LOCALREPO}/cache.lock

# Build package
# TODO: Enable signing
mkarchroot \
  -r "
  su - builder -c 'cd /tmp/${PACKAGE} && \
                   makepkg --clean --check --noconfirm --nocolor --noextract \
                           ${PROGRESSBAR}'
  " \
  ${CHROOT}

# Move out packages
rm -f ${LOCALREPO}/*.db*
rm -f ${LOCALREPO}/*.files*
mv ${CHROOT}${RESULT_DIR}/* ${LOCALREPO}/

# Update repo. Make sure that a lock is acquired before performing the operation
echo "Attempting to acquire lock on local repo..."
(
  flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
  echo "Acquired lock on local repo"
  # We must clear out existing packages in the cache. Rebuilds without changing
  # the package version and release will cause the sha256sums in ${LOCALREPO}
  # and /var/cache/pacman/pkg/ to mismatch causing pacman to fail. It would be
  # better if it was possible to tell pacman not to cache the local repo.
  (
    flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)
    for i in ${LOCALREPO}/*.pkg.tar.xz; do
      if [ -f /var/cache/pacman/pkg/$(basename ${i}) ]; then
        rm /var/cache/pacman/pkg/$(basename ${i})
      fi
    done
  ) 321>${LOCALREPO}/cache.lock
  # TODO: Enable signing
  repo-add ${LOCALREPO}/Unity-for-Arch.db.tar.xz ${LOCALREPO}/*.pkg.tar.xz
) 123>${LOCALREPO}/repo.lock
