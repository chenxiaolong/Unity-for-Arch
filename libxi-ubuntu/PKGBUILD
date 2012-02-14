# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=libxi-ubuntu
_ubuntu_rel=0ubuntu1
pkgver=1.5.99.3.${_ubuntu_rel}
pkgrel=100
pkgdesc="X11 Input extension library"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org"
depends=('libxext' 'inputproto-ubuntu>=2.1.99.6' 'libx11-ubuntu>=1.4.99.1.0ubuntu1')
makedepends=('pkgconfig' 'xorg-util-macros' 'xmlto' 'docbook-xml' 'asciidoc')
provides=("libxi=${pkgver}")
conflicts=('libxi')
options=(!libtool)
license=('custom')
source=("${url}/releases/individual/lib/libXi-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/libxi_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('7f1f4b561ea84a020f841e5288ab82d7d5de3ea7a56c7f39a3e0e10772799586249fd0976d5348d997ac3c11ba4747169305d69fc2ec636e5195ae363b20f33e'
            '7d2a667a6a82f4faa02065bfc380e777d77a5672a48fa121a3b6c0c108d13f53c699302ac189e99fdf623d4e8bc759ea0527c3e0f069a48666f54d8ea3c7c744')

build() {
  cd "${srcdir}/libXi-${pkgver%.*}"

  #Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/libxi_${pkgver%.*}-${_ubuntu_rel}.diff"
  for i in $(cat "debian/patches/series" | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  chmod +x autogen.sh
  ./autogen.sh --prefix=/usr --sysconfdir=/etc --disable-static --with-xmlto --without-fop
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/libXi-${pkgver%.*}"

  make DESTDIR="${pkgdir}" install

  install -m755 -d "${pkgdir}/usr/share/licenses/${pkgname}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname}/"
}
