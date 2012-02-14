# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=inputproto-ubuntu
_ubuntu_rel=1
pkgver=2.1.99.6.${_ubuntu_rel}
pkgrel=100
pkgdesc="X11 Input extension wire protocol"
arch=('any')
license=('custom')
url="http://xorg.freedesktop.org/"
makedepends=('xorg-util-macros')
provides=("inputproto=${pkgver}")
conflicts=('inputproto')
source=("${url}/releases/individual/proto/${pkgname%-*}-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/x11proto-input_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('7b493e10102734b6eb738a08ef7dc10c7a974a4a34ed88e32ab7c56f1bc049fba5382747d6da3c4cd0baa589cdfd3bbaedc5d266746e3bf8d1ff873fb082aee5'
            '85cc1b6576cad3539b560379c255c871426945c1cf8433a303530524fabd80da38f27f2dbab32457bfe254afd76bf72fd140475f15390ffb3bd9fb29a86aa88a')

build() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/x11proto-input_${pkgver%.*}-${_ubuntu_rel}.diff"
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
