#!/bin/bash

# Please add the following to build-in-chroot.conf:
#
# PACKAGER="Your Name <your@email>"
# GPGKEY=""
# MAKEFLAGS=""
# REPOS=('Unity-for-Arch::file:///path/to/repo/@ARCH@'
#        'My-Favorite-Repo::http://www.something.org/pub/@ARCH@')
# USE_CCACHE="true"
# CCACHE_DIR="/path/to/ccache/cache/@ARCH@" # The @ARCH@ is required
# # Note that this script will change the ownership of ${CCACHE_DIR} to
# # 10000:10000 with permissions 0755.

################################################################################

# Target architecture
arch=
# PKGBUILD directory
package_dir=
# Default packages to install in chroot
chroot_packages=(base base-devel sudo curl)
# Path to config file
config_file="$(dirname "${BASH_SOURCE[0]}")/build-in-chroot.conf"
# Whether the chroot should be kept
keep_root=false

# Build directory in chroot
build_dir=/build
# Packages result directory in chroot
result_dir=/packages
# Build user's username in chroot
build_user=builder
# Build user's UID in chroot
build_uid=10000

# [makepkg.conf] PACKAGER
conf_packager=
# [makepkg.conf] GPGKEY
conf_gpgkey=
# [makepkg.conf] MAKEFLAGS
conf_makeflags=
# Repos to add to pacman.conf
conf_repos=()
# Repos to add to pacman.conf before [core]
conf_repos_pre=()
# Whether ccache should be used
conf_use_ccache=false
# ccache directory
conf_ccache_dir=

################################################################################

load_config_file() {
    source "${config_file}"

    conf_packager="${PACKAGER}"
    conf_gpgkey="${GPGKEY}"
    conf_makeflags="${MAKEFLAGS}"
    conf_repos=("${REPOS[@]}")
    conf_repos_pre=("${REPOS_PRE[@]}")
    conf_use_ccache="${USE_CCACHE}"
    conf_ccache_dir="${CCACHE_DIR}"

    unset PACKAGER
    unset GPGKEY
    unset MAKEFLAGS
    unset REPOS
    unset REPOS_PRE
    unset USE_CCACHE
    unset CCACHE_DIR
}

chroot_exec() {
    setarch "${arch}" systemd-nspawn "${nspawn_args[@]}" "${@}"
}

show_help() {
    echo "Usage build-in-chroot.sh -p <package> [-a <arch>] [-c <config>]"
    echo ""
    echo "Options:"
    echo "  -p,--package  Path to the directory containing the PKGBUILD file"
    echo "  -a,--arch     Architecture to build for"
    echo "  -c,--config   Use this file instead of build-in-chroot.conf as the config"
    echo "  -r,--keeproot Do not delete chroot after building"
}

args=$(getopt -o p:a:c:r -l package:arch:config:keeproot -n build-in-chroot.sh -- "${@}")

if [[ ${?} -ne 0 ]]; then
    echo "Failed to parse arguments!"
    show_help
    exit 1
fi

eval set -- "${args}"

while true; do
    case "${1}" in
    -a|--arch)
        arch="${2}"
        shift 2
        ;;
    -p|--package)
        package_dir="${2}"
        shift 2
        ;;
    -c|--config)
        config_file="${2}"
        shift 2
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

if [[ -z "${package_dir}" ]]; then
    echo "No package was provided!"
    show_help
    exit 1
fi

if [[ -z "${arch}" ]]; then
    arch="$(uname -m)"
fi

package_dir="$(readlink -f "${package_dir}")"

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

if ! which pacstrap &>/dev/null; then
    echo "arch-install-scripts is not installed!"
    exit 1
fi

# Check if the shell is interactive
if tty -s; then
    progressbar=""
else
    progressbar="--noprogressbar"
fi

load_config_file

if [[ "${conf_use_ccache}" = "true" ]]; then
    chroot_packages+=(ccache)
    conf_ccache_dir=${conf_ccache_dir/@ARCH@/${arch}}
    mkdir -p "${conf_ccache_dir}"
    chown -R "${build_uid}:${build_uid}" "${conf_ccache_dir}"
fi

set -ex

cleanup() {
    # Clean up chroot
    if [[ "${keep_root}" != "true" ]]; then
        rm -rf "${chroot_dir}"
    fi
    rm -f "${temp_pacman_conf}"
}

trap "cleanup" SIGINT SIGTERM EXIT

chroot_dir=$(mktemp -d --tmpdir="$(pwd)")
chroot_dir=$(basename "${chroot_dir}")

temp_pacman_conf=$(mktemp --tmpdir="$(pwd)")

# Necessary, or the chroot user created below won't be able to execute anything
chmod -R 0755 "${chroot_dir}"

### Download ###################################################################

# Download pacman.conf
wget "https://projects.archlinux.org/svntogit/packages.git/plain/trunk/pacman.conf.${arch}?h=packages/pacman" -O "${temp_pacman_conf}"

################################################################################

### Create chroot ##############################################################

# Create base chroot
setarch "${arch}" pacstrap -cd "${chroot_dir}" \
                           --config="${temp_pacman_conf}" \
                           "${chroot_packages[@]}"

# Set up systemd-nspawn arguments
nspawn_args=("--register=no" "--directory=${chroot_dir}")

# Don't install or update the kernel
sed -i -r "s|^#?\\s*IgnorePkg.+|IgnorePkg = linux|g" \
    "${chroot_dir}/etc/pacman.conf"

# Set up locale
sed -i '1i en_US.UTF-8 UTF-8' "${chroot_dir}/etc/locale.gen"
echo 'LANG=C' > "${chroot_dir}/etc/locale.conf"
chroot_exec locale-gen

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

# Enable multilib on x86_64
if [[ "${arch}" == x86_64 ]]; then
    cat >> "${chroot_dir}/etc/pacman.conf" << EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
fi

for i in "${conf_repos[@]}"; do
    i=${i/@ARCH@/${arch}}
    cat >> "${chroot_dir}/etc/pacman.conf" << EOF
[${i%::*}]
SigLevel = Never
Server = ${i#*::}
EOF
done

for i in "${conf_repos_pre[@]}"; do
    i=${i/@ARCH@/${arch}}
    sed -i "/^\[core\]/ i\\
[${i%::*}] \\
SigLevel = Never \\
Server = ${i#*::} \\
" "${chroot_dir}/etc/pacman.conf"
done

# Copy packaging
mkdir "${chroot_dir}${build_dir}/"
cp -r "${package_dir}"/. "${chroot_dir}${build_dir}/"

# Create new user
chroot_exec useradd \
    --create-home \
    --shell /bin/bash \
    --user-group \
    --uid "${build_uid}" \
    "${build_user}"

# Fix permissions
mkdir "${chroot_dir}${result_dir}/"
chown -R "${build_uid}:${build_uid}" "${result_dir}" "${build_dir}"

# Make sure the builder user can run "pacman" to install the build dependencies
echo "${build_user} ALL=(ALL) ALL,NOPASSWD: /usr/bin/pacman" \
    > "${chroot_dir}/etc/sudoers.d/chrootbuild"

# Bind mount local repos
for i in "${conf_repos[@]}" "${conf_repos_pre[@]}"; do
    location=${i#*::}
    type=${location%://*}
    location=${location#*://}
    location=${location/@ARCH@/${arch}}
    if [[ "${type}" = "file" ]]; then
        mkdir -p "${chroot_dir}${location}/"
        nspawn_args+=(--bind "${location//:/\\:}/")
    fi
done

# Bind mount ccache directory
if [[ "${conf_use_ccache}" = "true" ]]; then
    mkdir -p "${chroot_dir}${conf_ccache_dir}/"
    chown -R "${build_uid}:${build_uid}" "${chroot_dir}${conf_ccache_dir}/"
    nspawn_args+=(--bind "${conf_ccache_dir//:/\\:}/")
fi

# Build package
cat > "${chroot_dir}/build.sh" << EOF
#!/bin/bash

set -e

git config --global user.email dummy@dummy
git config --global user.name dummy

sudo pacman -Syu --noconfirm ${progressbar}

if [[ "${arch}" == "x86_64" ]]; then
    yes | sudo pacman -S gcc-multilib gcc-libs-multilib libtool-multilib
fi

cd "${build_dir}"
# TODO: Enable signing
makepkg --syncdeps --clean --check --nocolor --noconfirm ${progressbar}
EOF
chroot_exec --user "${build_user}" --setenv CCACHE_DIR="${conf_ccache_dir}" sh /build.sh

# Move out packages
cp "${chroot_dir}${result_dir}"/* "${package_dir}/"