#!/bin/bash

# TODO: Must update host cache before downloading!!!

# Please add the following to build-in-chroot.conf:
# 
# PACKAGER="Your Name <your@email>"
# GPGKEY=""
# MAKEFLAGS=""
# REPO="Unity-for-Arch"
# LOCALREPO="/path/to/${REPO}/@ARCH@" # The @ARCH@ is required
# OTHERREPOS=('Unity-for-Arch::file:///path/to/repo/@ARCH@'
#             'My-Favorite-Repo::http://www.something.org/pub/@ARCH@')
# USE_CCACHE="true"
# CCACHE_DIR="/path/to/ccache/cache/@ARCH@" # The @ARCH@ is required
# # Note that this script will change the ownership of ${CCACHE_DIR} to
# # 10000:10000 with permissions 0755.

################################################################################

# Note to developers modifying this script: Do not break the script! Please make
# sure that it works for every single package.

# Please make sure that the script:
# * Locks ${LOCALREPO}/cache.lock before touching anything in
#   /var/cache/pacman/pkg/
#   - Separate download actions if necessary
# * Locks ${LOCALREPO}/repo.lock before updating the local repo

show_help() {
  echo "Usage build-in-chroot.sh -p <package> [-a <arch>] [-c <config>]"
  echo ""
  echo "Options:"
  echo "  -p,--package  Path to the directory containing the PKGBUILD file"
  echo "  -a,--arch     Architecture to build for"
  echo "  -c,--config   Use this file instead of build-in-chroot.conf as the config"
  echo "  -k,--keepcopy Keep a copy of the built packages in the directory of the"
  echo "                PKGBUILD file"
  echo "  -r,--keeproot Do not delete chroot after building"
}

MKARCHROOT_SUPPORTED=('e3c943d3fe1c196e2380ac0e98449877b447c8848cf049f9c9752a6e0a1e379f98b112efc66633b73c5dd8bffb11d958929befb7f2694ead1677b0301e69cb06')
ARCH_SUPPORTED=('i686' 'x86_64')
ARCH=""
PACKAGE_DIR=""
CHROOT_PACKAGES=('base' 'base-devel' 'sudo' 'curl')
CONFIG_FILE="$(dirname ${0})/build-in-chroot.conf"
KEEP_COPY=false
KEEP_ROOT=false

ARGS=$(getopt -o p:a:c:kr -l package:arch:config:keepcopy,keeproot -n build-in-chroot.sh -- "${@}")

if [ ${?} -ne 0 ]; then
  echo "Failed to parse arguments!"
  show_help
  exit 1
fi

eval set -- "${ARGS}"

while true; do
  case "${1}" in
  -a|--arch)
    shift
    ARCH="${1}"
    shift
    ;;
  -p|--package)
    shift
    PACKAGE_DIR="${1}"
    shift
    ;;
  -c|--config)
    shift
    CONFIG_FILE="${1}"
    shift
    ;;
  -k|--keepcopy)
    KEEP_COPY=true
    shift
    ;;
  -r|--keeproot)
    KEEP_ROOT=true
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

if [ -z "${PACKAGE_DIR}" ]; then
  echo "No package was provided!"
  show_help
  exit 1
fi

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi

# Make sure architecture is supported
SUPPORTED=false
for i in ${ARCH_SUPPORTED[@]}; do
  if [ "x${i}" == "x${ARCH}" ]; then
    SUPPORTED=true
    break
  fi
done
if [ "x${SUPPORTED}" != "xtrue" ]; then
  echo "Unsupported architecture ${ARCH}!"
  exit 1
fi

# Make sure the version of mkarchroot is supported
SUPPORTED=false
for i in ${MKARCHROOT_SUPPORTED[@]}; do
  if echo "${i} /usr/bin/mkarchroot" | sha512sum -c --status; then
    SUPPORTED=true
    break
  fi
done
if [ "x${SUPPORTED}" != "xtrue" ]; then
  echo "Unsupported version of mkarchroot!"
  exit 1
fi

PACKAGE_DIR="$(readlink -f ${PACKAGE_DIR})"
PACKAGE=$(basename ${PACKAGE_DIR})

if [ ! -f "${PACKAGE_DIR}/PKGBUILD" ]; then
  echo "${PACKAGE_DIR} does not contain PKGBUILD!"
  exit 1
fi

if [ ! -f "${CONFIG_FILE}" ]; then
  echo "${CONFIG_FILE} is missing! Please see the comment in this script."
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

CCACHE_DIR=""
source "${CONFIG_FILE}"

if [ "x${USE_CCACHE}" = "xtrue" ]; then
  CHROOT_PACKAGES+=('ccache')
  CCACHE_DIR=${CCACHE_DIR/@ARCH@/${ARCH}}
  mkdir -p "${CCACHE_DIR}"
  chown -R 10000:10000 "${CCACHE_DIR}"
fi

LOCALREPO=${LOCALREPO/@ARCH@/${ARCH}}

set -ex

cleanup() {
  umount ${CHROOT}${LOCALREPO}/ || true &>/dev/null

  for i in ${OTHERREPOS[@]} ${OTHERREPOS_PRE[@]}; do
    LOCATION=${i#*::}
    TYPE=${LOCATION%://*}
    LOCATION=${LOCATION#*://}
    LOCATION=${LOCATION/@ARCH@/${ARCH}}
    if [ "x${TYPE}" = "xfile" ]; then
      umount ${CHROOT}${LOCATION}/ || true &>/dev/null
    fi
  done

  if [ "x${USE_CCACHE}" = "xtrue" ]; then
    umount ${CHROOT}${CCACHE_DIR}/ || true &>/dev/null
  fi

  # Clean up chroot
  if [ "x${KEEP_ROOT}" != "xtrue" ]; then
    rm -rf ${CHROOT}
  fi
  rm -f ${CHROOT}.lock
  rm -rf ${CACHE_DIR}
  rm -rf ${TEMP_CHROOT}
  rm -f ${TEMP_PKGBUILD}
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

CHROOT=$(mktemp -d --tmpdir=$(pwd))
CHROOT=$(basename ${CHROOT})

RESULT_DIR=/tmp/packages

CACHE_DIR=$(mktemp -d --tmpdir=$(pwd))

TEMP_CHROOT=$(mktemp -d --tmpdir=$(pwd))
TEMP_PKGBUILD=$(mktemp)

# Necessary, or the chroot user created below won't be able to execute anything
chmod -R 0755 ${CHROOT}

# Make sure the chroot pacman can write to the cache dir
chmod -R 0755 ${CACHE_DIR}

### Download ###################################################################

# Everything writing to /var/cache/pacman/pkg/ MUST be done here to avoid
# threading/parallel execution issues
# TODO: Use clean pacman configuration file
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)

  set +x

  # Remove any packages in the local repo from the pacman cache. The chroot
  # should download them into its own cache.
  for i in ${LOCALREPO}/*.pkg.tar.xz; do
    if [ -f "/var/cache/pacman/pkg/$(basename ${i})" ]; then
      rm /var/cache/pacman/pkg/$(basename ${i})
    fi
  done

  set -x

  # Create temporary mini-chroot to store database files
  mkdir -p ${TEMP_CHROOT}/var/lib/pacman/

  pacman --arch ${ARCH} --sync --refresh --downloadonly --noconfirm \
         --root ${TEMP_CHROOT} --cachedir /var/cache/pacman/pkg/ \
         ${CHROOT_PACKAGES[@]}

  cat ${PACKAGE_DIR}/PKGBUILD > ${TEMP_PKGBUILD}
  chown nobody:nobody ${TEMP_PKGBUILD}

  set +x

  depends=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                    echo \${depends[@]}")
  makedepends=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                        echo \${makedepends[@]}")
  checkdepends=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                         echo \${checkdepends[@]}")
  available="$(pacman -Sl core extra community | cut -d' ' -f2)"
  list=""
  for i in ${depends} ${makedepends} ${checkdepends}; do
    i=${i%<*}
    i=${i%>*}
    i=${i%=*}
    if echo "${available}" | tr ' ' '\n' | grep -q "^${i}$"; then
      list+=" ${i}"
    fi
  done

  set -x

  pacman --arch ${ARCH} --sync --refresh --downloadonly --noconfirm \
         --root ${TEMP_CHROOT} --cachedir /var/cache/pacman/pkg/ ${list}

  # Copy /var/cache/pacman/pkg/ to the chroot-specific cache directory
  cp /var/cache/pacman/pkg/*-${ARCH}.pkg.tar.xz ${CACHE_DIR}/
  cp /var/cache/pacman/pkg/*-any.pkg.tar.xz ${CACHE_DIR}/
) 321>$(dirname ${0})/cache.lock

################################################################################

### Create chroot ##############################################################

# Patch mkarchroot to allow the creation of a chroot into an existing directory.
# This avoids potential issues when building two packages in the same directory.
mkarchroot_initial() {
  TEMP_MKARCHROOT=$(mktemp --tmpdir=$(pwd))
  cat /usr/bin/mkarchroot > ${TEMP_MKARCHROOT}
  TEMP_MKARCHROOT=$(basename ${TEMP_MKARCHROOT})
  (echo -e "--- ${TEMP_MKARCHROOT}.bak\n+++ ${TEMP_MKARCHROOT}" && \
   base64 -d << EOF
QEAgLTUxLDggKzUxLDYgQEAgZmkKIAogdW1hc2sgMDAyMgogCi1bWyAtZSAkd29ya2luZ19kaXIg
XV0gJiYgZGllICJXb3JraW5nIGRpcmVjdG9yeSAnJHdvcmtpbmdfZGlyJyBhbHJlYWR5IGV4aXN0
cyIKLQogbWtkaXIgLXAgIiR3b3JraW5nX2RpciIKIAogbG9jayA5ICIke3dvcmtpbmdfZGlyfS5s
b2NrIiAiTG9ja2luZyBjaHJvb3QiCkBAIC02Niw3ICs2NCw3IEBAIGlmIFtbICQoc3RhdCAtZiAt
YyAlVCAiJHdvcmtpbmdfZGlyIikgPT0gYnRyZnMgXV07IHRoZW4KIGZpCiAKIHBhY3N0cmFwIC1H
TWNkICR7cGFjX2NvbmY6Ky1DICIkcGFjX2NvbmYifSAiJHdvcmtpbmdfZGlyIiBcCi0gICIke2Nh
Y2hlX2RpcnNbQF0vIy8tLWNhY2hlZGlyPX0iICIkQCIgfHwgZGllICdGYWlsZWQgdG8gaW5zdGFs
bCBhbGwgcGFja2FnZXMnCisgICIke2NhY2hlX2RpcnNbQF0vIy8tLWNhY2hlZGlyPX0iIC0tZm9y
Y2UgIiRAIiB8fCBkaWUgJ0ZhaWxlZCB0byBpbnN0YWxsIGFsbCBwYWNrYWdlcycKIAogcHJpbnRm
ICclcy5VVEYtOCBVVEYtOFxuJyBlbl9VUyBkZV9ERSA+ICIkd29ya2luZ19kaXIvZXRjL2xvY2Fs
ZS5nZW4iCiBlY2hvICdMQU5HPUMnID4gIiR3b3JraW5nX2Rpci9ldGMvbG9jYWxlLmNvbmYiCg==
EOF
) | patch -p0
  cat ${TEMP_MKARCHROOT} | setarch ${ARCH} bash -s -- ${*}
  rm ${TEMP_MKARCHROOT}
  rm -f ${TEMP_MKARCHROOT}.{orig,rej}
}

# Create base chroot
mkarchroot_initial -c ${CACHE_DIR} ${CHROOT} ${CHROOT_PACKAGES[@]}

# Set up /etc/makepkg.conf
cat >> ${CHROOT}/etc/makepkg.conf << EOF
INTEGRITY_CHECK=(sha512)
PKGDEST="${RESULT_DIR}"
PACKAGER="${PACKAGER}"
GPGKEY="${GPGKEY}"
MAKEFLAGS="${MAKEFLAGS}"
EOF

if [ "x${USE_CCACHE}" = "xtrue" ]; then
  sed -i '/^\s*BUILDENV/ s/!ccache/ccache/g' ${CHROOT}/etc/makepkg.conf
fi

for i in ${OTHERREPOS[@]}; do
  i=${i/@ARCH@/${ARCH}}
  cat >> ${CHROOT}/etc/pacman.conf << EOF
[${i%::*}]
SigLevel = Never
Server = ${i#*::}
EOF
done

for i in ${OTHERREPOS_PRE[@]}; do
  i=${i/@ARCH@/${ARCH}}
  sed -i "/^\[core\]/ i\\
[${i%::*}] \\
SigLevel = Never \\
Server = ${i#*::} \\
" ${CHROOT}/etc/pacman.conf
done

# Copy packaging
mkdir ${CHROOT}/tmp/${PACKAGE}/
cp -v "${PACKAGE_DIR}/PKGBUILD" ${CHROOT}/tmp/${PACKAGE}/
install=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                  echo \${install}")
sources=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                  echo \${source[@]}")
extrafiles=$(sudo -u nobody bash -c "source ${TEMP_PKGBUILD} && \
                                     echo \${extrafiles[@]}")
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
arch-nspawn ${CHROOT} \
            useradd --create-home --shell /bin/bash --user-group builder \
                    -u 10000

# Fix permissions
mkdir ${CHROOT}${RESULT_DIR}/
arch-nspawn ${CHROOT} chown -R builder:builder ${RESULT_DIR} /tmp/${PACKAGE}/

# Make sure the builder user can run "pacman" to install the build dependencies
echo "builder ALL=(ALL) ALL,NOPASSWD: /usr/bin/pacman" \
  > ${CHROOT}/etc/sudoers.d/chrootbuild

# Make sure local repo exists
mkdir -p ${LOCALREPO}/ ${CHROOT}${LOCALREPO}/
mount --bind ${LOCALREPO}/ ${CHROOT}${LOCALREPO}/
for i in ${OTHERREPOS[@]} ${OTHERREPOS_PRE[@]}; do
  LOCATION=${i#*::}
  TYPE=${LOCATION%://*}
  LOCATION=${LOCATION#*://}
  LOCATION=${LOCATION/@ARCH@/${ARCH}}
  if [ "x${TYPE}" = "xfile" ]; then
    mkdir -p ${CHROOT}${LOCATION}/
    mount --bind ${LOCATION}/ ${CHROOT}${LOCATION}/
  fi
done

if [ "x${USE_CCACHE}" = "xtrue" ]; then
  mkdir -p ${CHROOT}${CCACHE_DIR}/
  chown -R 10000:10000 ${CHROOT}${CCACHE_DIR}/
  mount --bind ${CCACHE_DIR}/ ${CHROOT}${CCACHE_DIR}/
fi

# Must lock the local repo or (local repo) packages may be deleted as they are
# being downloaded
(
  flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
  if [ -f "${LOCALREPO}/${REPO}.db" ] || [[ ! -z "${OTHERREPOS[@]}" ]] \
                                      || [[ ! -z "${OTHERREPOS_PRE[@]}" ]]; then
    # Set up /etc/pacman.conf if local repo already exists
    # TODO: Enable signature verification
    if [ -f "${LOCALREPO}/${REPO}.db" ]; then
      cat >> ${CHROOT}/etc/pacman.conf << EOF
[${REPO}]
SigLevel = Never
Server = file://$(readlink -f ${LOCALREPO})
EOF
    fi

    arch-nspawn -c ${CACHE_DIR} ${CHROOT} pacman -Sy ${PROGRESSBAR}
  fi

  # Download sources and install build dependencies
  cat > ${CHROOT}/stage1.sh << EOF
su - builder -c 'export CCACHE_DIR="${CCACHE_DIR}" && cd /tmp/${PACKAGE} && \\
                 makepkg --syncdeps --nobuild --nocolor \\
                         --noconfirm ${PROGRESSBAR}'
EOF
  arch-nspawn -c ${CACHE_DIR} ${CHROOT} sh /stage1.sh
) 123>${LOCALREPO}/repo.lock

# Workaround makepkg bug for SCM packages
cat > ${CHROOT}/stage2.sh << EOF
su - builder -c 'cd /tmp/${PACKAGE} && \\
                 find -maxdepth 1 -type d -empty -name src \
                      -exec touch {}/stupid-makepkg \\;'
EOF
arch-nspawn -c ${CACHE_DIR} ${CHROOT} sh /stage2.sh

# Build package
# TODO: Enable signing
cat > ${CHROOT}/stage3.sh << EOF
su - builder -c 'export CCACHE_DIR="${CCACHE_DIR}" && cd /tmp/${PACKAGE} && \\
                 makepkg --clean --check --noconfirm --nocolor --noextract \\
                 ${PROGRESSBAR}'
EOF
arch-nspawn -c ${CACHE_DIR} ${CHROOT} sh /stage3.sh

################################################################################

### Create or update local repo ################################################

# Move out packages
if [ "x${KEEP_COPY}" = "xtrue" ]; then
  cp ${CHROOT}${RESULT_DIR}/* ${PACKAGE_DIR}/
fi

# Update repo. Make sure that a lock is acquired before performing the operation
# TODO: Remove old packages
echo "Attempting to acquire lock on local repo..."
(
  flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
  rm -f ${LOCALREPO}/*.db*
  rm -f ${LOCALREPO}/*.files*
  cp ${CHROOT}${RESULT_DIR}/* ${LOCALREPO}/
  # Old packages must be removed, so that the '*' glob in the repo-add command
  # below will not use old packages. For example, '*' would match:
  #   0ubuntu10 0ubuntu11 0ubuntu9
  # causing repo-add to only add 0ubuntu9 when it should clearly add 0ubuntu11
  paccache -vvv -k 1 -r -c ${LOCALREPO}/ || true

  # Avoid the epoch colon in the filename
  for i in ${LOCALREPO}/*.pkg.tar.xz; do
    if [ "x${i}" != "x${i/:/_}" ]; then
      mv ${i} ${i/:/_}
    fi
  done

  # TODO: Enable signing
  repo-add ${LOCALREPO}/${REPO}.db.tar.xz ${LOCALREPO}/*.pkg.tar.xz
) 123>${LOCALREPO}/repo.lock
