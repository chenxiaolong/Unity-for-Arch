#!/bin/bash

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

arch_supported=(i686 x86_64)
arch=""
package_dir=""
chroot_packages=(base base-devel sudo curl)
config_file="$(dirname "${0}")/build-in-chroot.conf"
keep_copy=false
keep_root=false

args=$(getopt -o p:a:c:kr -l package:arch:config:keepcopy,keeproot -n build-in-chroot.sh -- "${@}")

if [[ ${?} -ne 0 ]]; then
  echo "Failed to parse arguments!"
  show_help
  exit 1
fi

eval set -- "${args}"

while true; do
  case "${1}" in
  -a|--arch)
    shift
    arch="${1}"
    shift
    ;;
  -p|--package)
    shift
    package_dir="${1}"
    shift
    ;;
  -c|--config)
    shift
    config_file="${1}"
    shift
    ;;
  -k|--keepcopy)
    keep_copy=true
    shift
    ;;
  -r|--keeproot)
    keep_root=true
    shift
    ;;
  --)
    shift
    break
    ;;
  esac
done

if [[ ! -x /usr/bin/pacstrap ]]; then
  echo "arch-install-scripts is not installed!"
  exit 1
fi

if [[ -z "${package_dir}" ]]; then
  echo "No package was provided!"
  show_help
  exit 1
fi

if [[ -z "${arch}" ]]; then
  arch="$(uname -m)"
fi

# Make sure architecture is supported
supported=false
for i in "${arch_supported[@]}"; do
  if [[ "${i}" == "${arch}" ]]; then
    supported=true
    break
  fi
done
if [[ "${supported}" != "true" ]]; then
  echo "Unsupported architecture ${arch}!"
  exit 1
fi

package_dir="$(readlink -f "${package_dir}")"
package=$(basename "${package_dir}")

if [[ ! -f "${package_dir}/PKGBUILD" ]]; then
  echo "${package_dir} does not contain PKGBUILD!"
  exit 1
fi

if [[ ! -f "${config_file}" ]]; then
  echo "${config_file} is missing! Please see the comment in this script."
  exit 1
fi

if [[ "$(whoami)" != "root" ]]; then
  echo "This script must be run as root!"
  exit 1
fi

# Check if the shell is interactive
if tty -s; then
  progressbar=""
else
  progressbar="--noprogressbar"
fi

source "${config_file}"

conf_packager="${PACKAGER}"
conf_gpgkey="${GPGKEY}"
conf_makeflags="${MAKEFLAGS}"
conf_repo="${REPO}"
conf_localrepo="${LOCALREPO}"
conf_otherrepos=("${OTHERREPOS[@]}")
conf_otherrepos_pre=("${OTHERREPOS_PRE[@]}")
conf_use_ccache="${USE_CCACHE}"
conf_ccache_dir="${CCACHE_DIR}"

unset PACKAGER
unset GPGKEY
unset MAKEFLAGS
unset REPO
unset LOCALREPO
unset OTHERREPOS
unset OTHERREPOS_PRE
unset USE_CCACHE
unset CCACHE_DIR

if [[ "${conf_use_ccache}" = "true" ]]; then
  chroot_packages+=(ccache)
  conf_ccache_dir=${conf_ccache_dir/@ARCH@/${arch}}
  mkdir -p "${conf_ccache_dir}"
  chown -R 10000:10000 "${conf_ccache_dir}"
fi

conf_localrepo=${conf_localrepo/@ARCH@/${arch}}

set -ex

cleanup() {
  umount "${chroot_dir}${conf_localrepo}/" || true &>/dev/null

  for i in "${conf_otherrepos[@]}" "${conf_otherrepos_pre[@]}"; do
    local location=${i#*::}
    local type=${location%://*}
    location=${location#*://}
    location=${location/@ARCH@/${arch}}
    if [[ "${type}" = "file" ]]; then
      umount "${chroot_dir}${location}/" || true &>/dev/null
    fi
  done

  if [[ "${conf_use_ccache}" = "true" ]]; then
    umount "${chroot_dir}${conf_ccache_dir}/" || true &>/dev/null
  fi

  # Clean up chroot
  if [[ "${keep_root}" != "true" ]]; then
    rm -rf "${chroot_dir}"
  fi
  rm -f "${chroot_dir}.lock"
  rm -rf "${cache_dir}"
  rm -rf "${temp_chroot}"
  rm -f "${temp_pkgbuild}"
}

trap "cleanup" SIGINT SIGTERM SIGKILL EXIT

chroot_dir=$(mktemp -d --tmpdir="$(pwd)")
chroot_dir=$(basename "${chroot_dir}")

result_dir=/packages

cache_dir=$(mktemp -d --tmpdir="$(pwd)")

temp_chroot=$(mktemp -d --tmpdir="$(pwd)")
temp_pkgbuild=$(mktemp)

# Necessary, or the chroot user created below won't be able to execute anything
chmod -R 0755 "${chroot_dir}"

# Make sure the chroot pacman can write to the cache dir
chmod -R 0755 "${cache_dir}"

### Download ###################################################################

# Everything writing to /var/cache/pacman/pkg/ MUST be done here to avoid
# threading/parallel execution issues
(
  flock 321 || (echo "Failed to acquire lock on pacman cache!" && exit 1)

  set +x

  # Remove any packages in the local repo from the pacman cache. The chroot
  # should download them into its own cache.
  for i in "${conf_localrepo}"/*.pkg.tar.xz; do
    if [[ -f "/var/cache/pacman/pkg/$(basename "${i}")" ]]; then
      rm "/var/cache/pacman/pkg/$(basename "${i}")"
    fi
  done

  set -x

  # Create temporary mini-chroot to store database files
  mkdir -p "${temp_chroot}/var/lib/pacman/"

  # Download pacman.conf
  mkdir -p "${temp_chroot}/etc/"
  wget "https://projects.archlinux.org/svntogit/packages.git/plain/trunk/pacman.conf.${arch}?h=packages/pacman" -O "${temp_chroot}/etc/pacman.conf"

  cat "${package_dir}/PKGBUILD" > "${temp_pkgbuild}"
  chown nobody:nobody "${temp_pkgbuild}"

  # Copy or hard link cached packages to the chroot-specific cache directory
  if [[ "$(stat -c '%d' /var/cache/pacman/pkg/)" = \
        "$(stat -c '%d' "${cache_dir}")" ]]; then
    ln /var/cache/pacman/pkg/*-"${arch}".pkg.tar.xz "${cache_dir}/"
    ln /var/cache/pacman/pkg/*-any.pkg.tar.xz "${cache_dir}/"
  else
    cp /var/cache/pacman/pkg/*-"${arch}".pkg.tar.xz "${cache_dir}/"
    cp /var/cache/pacman/pkg/*-any.pkg.tar.xz "${cache_dir}/"
  fi
) 321>"$(dirname "${0}")/cache.lock"

################################################################################

### Create chroot ##############################################################

# Create base chroot
setarch "${arch}" pacstrap -GMcd "${chroot_dir}" --cachedir="${cache_dir}" \
                           --config="${temp_chroot}/etc/pacman.conf" \
                           "${chroot_packages[@]}"

# Set up systemd-nspawn arguments
nspawn_args=("--register=no" "--directory=${chroot_dir}")

# Cache directory
nspawn_args+=("--bind=${cache_dir}")
sed -i -r "s|^#?\\s*CacheDir.+|CacheDir = ${cache_dir}|g" \
  "${chroot_dir}/etc/pacman.conf"

# Don't install or update the kernel
sed -i -r "s|^#?\\s*IgnorePkg.+|IgnorePkg = linux|g" \
  "${chroot_dir}/etc/pacman.conf"

# Copy pacman keyring
cp -a /etc/pacman.d/gnupg/ "${chroot_dir}/etc/pacman.d/"

# Copy mirrorlist
cp /etc/pacman.d/mirrorlist "${chroot_dir}/etc/pacman.d/"

# Set up locale
sed -i '1i en_US.UTF-8 UTF-8' "${chroot_dir}/etc/locale.gen"
echo 'LANG=C' > "${chroot_dir}/etc/locale.conf"
setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                  locale-gen

# Set up /etc/makepkg.conf
cat >> "${chroot_dir}/etc/makepkg.conf" << EOF
INTEGRITY_CHECK=(sha512)
PKGDEST="${result_dir}"
PACKAGER="${conf_packager}"
GPGKEY="${conf_gpgkey}"
MAKEFLAGS="${conf_makeflags}"
EOF

if [[ "${conf_use_ccache}" = "true" ]]; then
  sed -i '/^\s*BUILDENV/ s/!ccache/ccache/g' "${chroot_dir}/etc/makepkg.conf"
fi

# Set up /etc/pacman.conf if local repo already exists
# TODO: Enable signature verification
if [[ -f "${conf_localrepo}/${conf_repo}.db" ]]; then
#  cat >> "${chroot_dir}/etc/pacman.conf" << EOF
#[${conf_repo}]
#SigLevel = Never
#Server = file://$(readlink -f "${conf_localrepo}")
#EOF

  sed -i "/^\[core\]/ i\\
[${conf_repo}] \\
SigLevel = Never \\
Server = file://$(readlink -f "${conf_localrepo}") \\
" "${chroot_dir}/etc/pacman.conf"
fi

for i in "${conf_otherrepos[@]}"; do
  i=${i/@ARCH@/${arch}}
  cat >> "${chroot_dir}/etc/pacman.conf" << EOF
[${i%::*}]
SigLevel = Never
Server = ${i#*::}
EOF
done

for i in "${conf_otherrepos_pre[@]}"; do
  i=${i/@ARCH@/${arch}}
  sed -i "/^\[core\]/ i\\
[${i%::*}] \\
SigLevel = Never \\
Server = ${i#*::} \\
" "${chroot_dir}/etc/pacman.conf"
done

# Enable multilib on x86_64
if [[ "${arch}" == x86_64 ]]; then
  cat >> "${chroot_dir}/etc/pacman.conf" << EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
fi

# Copy packaging
mkdir "${chroot_dir}/${package}/"
cp -v "${package_dir}/PKGBUILD" "${chroot_dir}/${package}/"
install=$(sudo -u nobody bash -c "source \"${temp_pkgbuild}\" && \
                                  echo \${install}")
sources=$(sudo -u nobody bash -c "source \"${temp_pkgbuild}\" && \
                                  echo \${source[@]}")
extrafiles=$(sudo -u nobody bash -c "source \"${temp_pkgbuild}\" && \
                                     echo \${extrafiles[@]}")
if [[ -f "${package_dir}/${install}" ]]; then
  cp -v "${package_dir}/${install}" "${chroot_dir}/${package}/"
fi
for i in ${sources}; do
  if [[ -f "${package_dir}/${i}" ]]; then
    cp -v "${package_dir}/${i}" "${chroot_dir}/${package}/"
  fi
done
for i in ${extrafiles}; do
  cp -v "${package_dir}/${i}" "${chroot_dir}/${package}/"
done

# Create new user
setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                  useradd --create-home --shell /bin/bash --user-group builder \
                          -u 10000

# Fix permissions
mkdir "${chroot_dir}${result_dir}/"
setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                  chown -R builder:builder "${result_dir}" "/${package}/"

# Make sure the builder user can run "pacman" to install the build dependencies
echo "builder ALL=(ALL) ALL,NOPASSWD: /usr/bin/pacman" \
  > "${chroot_dir}/etc/sudoers.d/chrootbuild"

# Make sure local repo exists
mkdir -p "${conf_localrepo}/" "${chroot_dir}${conf_localrepo}/"
mount --bind "${conf_localrepo}/" "${chroot_dir}${conf_localrepo}/"
for i in "${conf_otherrepos[@]}" "${conf_otherrepos_pre[@]}"; do
  location=${i#*::}
  type=${location%://*}
  location=${location#*://}
  location=${location/@ARCH@/${arch}}
  if [[ "${type}" = "file" ]]; then
    mkdir -p "${chroot_dir}${location}/"
    mount --bind "${location}/" "${chroot_dir}${location}/"
  fi
done

if [[ "${conf_use_ccache}" = "true" ]]; then
  mkdir -p "${chroot_dir}${conf_ccache_dir}/"
  chown -R 10000:10000 "${chroot_dir}${conf_ccache_dir}/"
  mount --bind "${conf_ccache_dir}/" "${chroot_dir}${conf_ccache_dir}/"
fi

# Must lock the local repo or (local repo) packages may be deleted as they are
# being downloaded
(
  flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
  if [[ -f "${conf_localrepo}/${conf_repo}.db" ]] \
      || [[ ! -z "${conf_otherrepos[@]}" ]] \
      || [[ ! -z "${conf_otherrepos_pre[@]}" ]]; then
    setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                      pacman -Syu --noconfirm ${progressbar}
  fi

  # Download sources and install build dependencies
  cat > "${chroot_dir}/stage1.sh" << EOF
if [[ "${arch}" == "x86_64" ]]; then
  yes | pacman -S gcc-multilib gcc-libs-multilib libtool-multilib
fi
su - builder -c 'export CCACHE_DIR="${conf_ccache_dir}" && cd "/${package}" && \\
                 makepkg --syncdeps --nobuild --noextract --nocolor \\
                         --noconfirm --skipinteg ${progressbar}'
EOF
  setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                    sh /stage1.sh
) 123>"${conf_localrepo}/repo.lock"

# Workaround makepkg bug for SCM packages
cat > "${chroot_dir}/stage2.sh" << EOF
su - builder -c 'git config --global user.email dummy@dummy'
su - builder -c 'git config --global user.name dummy'
su - builder -c 'cd "/${package}" && \\
                 find -maxdepth 1 -type d -empty -name src \
                      -exec touch {}/stupid-makepkg \\;'
EOF
setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                  sh /stage2.sh

# Build package
# TODO: Enable signing
cat > "${chroot_dir}/stage3.sh" << EOF
su - builder -c 'export CCACHE_DIR="${conf_ccache_dir}" && cd "/${package}" && \\
                 makepkg --clean --check --noconfirm --nocolor \\
                 ${progressbar}'
EOF
setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" \
                  sh /stage3.sh

################################################################################

### Create or update local repo ################################################

# Move out packages
if [[ "${keep_copy}" = "true" ]]; then
  cp "${chroot_dir}${result_dir}"/* "${package_dir}/"
fi

# Update repo. Make sure that a lock is acquired before performing the operation
# TODO: Remove old packages
echo "Attempting to acquire lock on local repo..."
(
  flock 123 || (echo "Failed to acquire lock on local repo!" && exit 1)
  rm -f "${conf_localrepo}"/*.db*
  rm -f "${conf_localrepo}"/*.files*
  cp "${chroot_dir}${result_dir}"/* "${conf_localrepo}/"
  # Old packages must be removed, so that the '*' glob in the repo-add command
  # below will not use old packages. For example, '*' would match:
  #   0ubuntu10 0ubuntu11 0ubuntu9
  # causing repo-add to only add 0ubuntu9 when it should clearly add 0ubuntu11
  paccache -vvv -k 1 -r -c "${conf_localrepo}/" || true

  # Avoid the epoch colon in the filename
  for i in "${conf_localrepo}"/*.pkg.tar.xz; do
    if [[ "${i}" != "${i/:/_}" ]]; then
      mv "${i}" "${i/:/_}"
    fi
  done

  # TODO: Enable signing
  repo-add "${conf_localrepo}/${conf_repo}.db.tar.xz" \
           "${conf_localrepo}"/*.pkg.tar.xz
  repo-add -f "${conf_localrepo}/${conf_repo}.files.tar.xz" \
              "${conf_localrepo}"/*.pkg.tar.xz
) 123>"${conf_localrepo}/repo.lock"

################################################################################

### Copy cached packages back to /var/cache/pacman/pkg #########################

(
  if [[ "$(stat -c '%d' /var/cache/pacman/pkg/)" = \
        "$(stat -c '%d' "${cache_dir}")" ]]; then
    ln "${cache_dir}"/*.pkg.tar.xz /var/cache/pacman/pkg/ || true
  else
    cp "${cache_dir}"/*.pkg.tar.xz /var/cache/pacman/pkg/
  fi
) 321>"$(dirname "${0}")/cache.lock"
