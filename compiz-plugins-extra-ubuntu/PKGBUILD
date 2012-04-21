# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=compiz-plugins-extra-ubuntu

_ubuntu_rel=0ubuntu6
_ubuntu_ver='~bzr9'
_actual_ver=0.9.7.0

pkgver=${_actual_ver}.bzr9.${_ubuntu_rel}
pkgrel=100
pkgdesc="Compiz extra plugins - Ubuntu version"
url="http://www.compiz.org/"
license=('GPL' 'LGPL' 'MIT')
arch=('i686' 'x86_64')
provides=('compiz-plugins-extra')
conflicts=('compiz-plugins-extra')
groups=('unity')
depends=('compiz-core-ubuntu' 'compiz-plugins-main-ubuntu' 'libjpeg-turbo' 'gconf-ubuntu' 'libnotify' 'dconf')
makedepends=('intltool' 'cmake' 'pkgconfig')
install=compiz-plugins-extra-ubuntu.install
source=("https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${_actual_ver}${_ubuntu_ver}.orig.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.debian.tar.gz")
sha512sums=('5681447344359af7b5bd803cf986d3e27e79a4a55d338d7b793c2f5611b0c2d08ccdd8cbe0d60f41f88fda1146e91f524f40209c071d3bbb0b63c4dfef549714'
            'e4d0ab6c1fa8492bcbbf2f89550b5dbd41dd7ca073691dd1afe92be0d67ca14b447307e89d8b659431d0317d8ad3717259c3a9f1051cfd314fef0cf11e21027a')

build() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}"

  [[ -d build ]] || mkdir build
  cd build
  cmake .. \
    -DCOMPIZ_BUILD_WITH_RPATH=FALSE \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCOMPIZ_PLUGIN_INSTALL_TYPE="compiz" \
    -DCMAKE_INSTALL_PREFIX=/usr

  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}/build"
  make DESTDIR="${pkgdir}" install
}

# vim:set ts=2 sw=2 et:
