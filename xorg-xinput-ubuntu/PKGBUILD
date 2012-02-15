# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Jan de Groot <jgc@archlinux.org>

pkgname=xorg-xinput-ubuntu
_ubuntu_rel=0ubuntu2
pkgver=1.5.99.1.${_ubuntu_rel}
pkgrel=100
pkgdesc="Small commandline tool to configure devices with Ubuntu's patches"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
license=('custom')
depends=('libx11' 'libxi-ubuntu')
makedepends=('xorg-util-macros' 'inputproto-ubuntu')
groups=('xorg-apps' 'xorg')
provides=("xorg-xinput=${pkgver}")
conflicts=('xorg-xinput')
source=("http://xorg.freedesktop.org/archive/individual/app/xinput-${pkgver%.*}.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/xinput_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('2ada7baf0422880bb4a14d442a4eea54bc6a106980c94704596e77dd69e813cb816e62785fd675f4e2e847d1e4b903ad9ee2521306ddf73decb33e69c4fcf1d1'
            'f4c544cb466224b7e0b763ac8e224619c8e0aa705a8d1bb1c0c5b4ad7c50ad02395c2be5385c60d03d57096fa40e76f613796de4c766748e95632d67a36b788b')

build() {
  cd "${srcdir}/xinput-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xinput_${pkgver%.*}-${_ubuntu_rel}.diff"
  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  ./configure --prefix=/usr
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/xinput-${pkgver%.*}"
  make DESTDIR="${pkgdir}" install
  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"
}
