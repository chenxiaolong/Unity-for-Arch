# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Jan de Groot <jgc@archlinux.org>

pkgname=libxfixes-ubuntu
_ubuntu_rel=4ubuntu1
pkgver=5.0.${_ubuntu_rel}
pkgrel=1
pkgdesc="X11 miscellaneous 'fixes' extension library"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
license=('custom')
depends=('libx11-ubuntu' 'fixesproto-ubuntu>=5.0.2ubuntu1')
makedepends=('xorg-util-macros')
provides=("libxfixes=${pkgver%.*}")
conflicts=('libxfixes')
options=('!libtool')
source=("${url}/releases/individual/lib/libXfixes-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('fd3071b52c657975b4321e6c7ebe433c43ea6944d04d2228da075aad394e962eec705e41a6c3a6bbc12f704765189116d1328c3111e457f23395ff6f57ae63d5'
            '01ca02cefcaec123f9037614f91e791a213739623cf241b400d44118740408f5d5d001cbb3ac3b493717fc95b44483fd79632c9cbfcc857f566d7e7ca141f6f7')

build() {
  cd "${srcdir}/libXfixes-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/${pkgname%-*}_${pkgver%.*}-${_ubuntu_rel}.diff"
  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  ./configure --prefix=/usr --sysconfdir=/etc --disable-static
  make ${MAKEFLAGS}
}

check() {
  cd "${srcdir}/libXfixes-${pkgver%.*}"

  make -k check
}

package() {
  cd "${srcdir}/libXfixes-${pkgver%.*}"

  make DESTDIR="${pkgdir}/" install

  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"
}

# vim:set ts=2 sw=2 et:
