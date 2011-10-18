# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Jan de Groot <jgc@archlinux.org>
# Contributor: Alexander Baldeck <alexander@archlinux.org>

pkgname=xf86-video-ati-ubuntu
_ubuntu_ver="~git20110811.g93fc084"
_ubuntu_rel=0ubuntu1
_actual_ver=6.14.99
pkgver=${_actual_ver}$(echo ${_ubuntu_ver} | tr '~' '.')
pkgrel=100
pkgdesc="X.org ati video driver"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
license=('custom')
depends=('libpciaccess' 'libdrm' 'udev' 'pixman' 'ati-dri')
makedepends=('xorg-server-devel-ubuntu' 'libdrm' 'xf86driproto' 'mesa' 'glproto')
provides=("xf86-video-ati=${pkgver}")
conflicts=('xorg-server>=1.11.0' 'xf86-video-ati')
groups=('xorg-drivers' 'xorg')
options=('!libtool')
source=("http://archive.ubuntu.com/ubuntu/pool/main/x/xserver-xorg-video-ati/xserver-xorg-video-ati_${_actual_ver}${_ubuntu_ver}.orig.tar.gz"
        "http://archive.ubuntu.com/ubuntu/pool/main/x/xserver-xorg-video-ati/xserver-xorg-video-ati_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff.gz")
sha512sums=('33f261bfb8c62102cc525a7bf467d037ff375cb4346d83f7f80443518a83c1f36c4be921865cc058fbbcdb9f7f926d943ef25942d9bf4d6cf897db5b1512d61c'
            'a2080d4f53228484eb2fec345763e43a127740b0454153cdcf46bab5827eb498e95b81c88fcec249ad29792330ab853a061a97ca52f64b823763123ddc02048d')

build() {
  cd "${srcdir}/xserver-xorg-video-ati_${_actual_ver}${_ubuntu_ver}"

  #Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xserver-xorg-video-ati_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff"
  for i in $(cat 'debian/patches/series' | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  ./autogen.sh --prefix=/usr --enable-dri
  make
}

package() {
  cd "${srcdir}/xserver-xorg-video-ati_${_actual_ver}${_ubuntu_ver}"
  make "DESTDIR=${pkgdir}" install
  install -m755 -d "${pkgdir}/usr/share/licenses/${pkgname}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname}/"
}
