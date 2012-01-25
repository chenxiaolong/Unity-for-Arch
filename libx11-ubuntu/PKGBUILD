# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Jan de Groot <jgc@archlinux.org>

pkgname=libx11-ubuntu
_ubuntu_rel=0ubuntu1
pkgver=1.4.99.1.${_ubuntu_rel}
pkgrel=100
pkgdesc="X11 client-side library"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
depends=('libxcb' 'xproto' 'kbproto')
makedepends=('xorg-util-macros' 'xextproto' 'xtrans' 'inputproto')
provides=("libx11=${pkgver%.*}")
conflicts=('libx11')
options=('!libtool')
license=('custom')
source=("${url}/releases/individual/lib/libX11-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${pkgver%.*}-${_ubuntu_rel}.diff.gz"
        'xorg.sh'
        'xorg.csh')
sha512sums=('8eda07c527977cab493da3fad0f7b827dbc3e98e345ef69bf9187da34e2704dae3c6eeda3c9d8db6631ecf7c05d1f7dfdd57779f78ae33484e959833eb4a10b2'
            '4689b4a1c3f804612bd17d8b5df3e50983d3a77437610f886f0bf5b4b695c7573f2901fdb25e409d46c7c66d07be595ca93ee58c2974f8d795261b06e731208f'
            '00d2feec7ea163ac0ce49157f274857f79593e6a1749be2102ccd7ca33461ba6242d173872d9a9a7e470bbabaf20efeafcde423ef723f19c3ba21923eb8ac92a'
            '3d7e5d5aad76e489c0e1c72a714a4ab0b6111140923e304dbcca35f29227f268f3863bd0cde0517cbc23adb95a9dbdf7b36054f642cf5c59d8865216f12695fa')

build() {
  cd "${srcdir}/libX11-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/${pkgname%-*}_${pkgver%.*}-${_ubuntu_rel}.diff"
  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  autoreconf -vfi

  ./configure --prefix=/usr --disable-static --disable-xf86bigfont
  make ${MAKEFLAGS}
}

check() {
  cd "${srcdir}/libX11-${pkgver%.*}"

  make check
}

package() {
  cd "${srcdir}/libX11-${pkgver%.*}"

  make DESTDIR="${pkgdir}/" install

  install -m755 -d "${pkgdir}/etc/profile.d"
  install -m755 "${srcdir}/"xorg.{sh,csh} "${pkgdir}/etc/profile.d/"

  install -d -m755 "${pkgdir}/usr/share/licenses/${pkgname}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname}/"
}
