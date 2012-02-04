# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=fixesproto-ubuntu
_ubuntu_rel=2ubuntu1
pkgver=5.0.${_ubuntu_rel}
pkgrel=100
pkgdesc="X11 Fixes extension wire protocol"
arch=('any')
license=('custom')
url="http://xorg.freedesktop.org/"
depends=('xproto' 'xextproto')
makedepends=('xorg-util-macros')
provides=("fixesproto=${pkgver%.*}")
conflicts=('fixesproto')
source=("${url}/releases/individual/proto/${pkgname%-*}-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/x11proto-fixes_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('93c6a8b6e4345c3049c08f2f3960f5eb5f92c487f26d227430964361bf82041b49e61f873fbbb8ee0e111556f90532b852c20e6082ee8008be641373251fa78c'
            'b9f95d240ef0cbbb70f96a87ca95178cde5056364d6ad4e41327c273a95b885d281032cf82eeab0c364e81613a29e6880fe03fcc5308b1870e67e51a39232f26')

build() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/x11proto-fixes_${pkgver%.*}-${_ubuntu_rel}.diff"
  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  autoreconf -vfi

  ./configure --prefix=/usr
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"
  make DESTDIR="${pkgdir}" install

  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"
}
