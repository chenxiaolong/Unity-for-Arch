# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=xf86-video-intel-ubuntu
_ubuntu_ver=1ubuntu2
_ubuntu_ver2=2.15.901
pkgver=2.15.0.${_ubuntu_ver}
pkgrel=100
pkgdesc="X.org Intel i810/i830/i915/945G/G965+ video drivers"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
license=('custom')
depends=('intel-dri' 'libxvmc' 'libpciaccess' 'libdrm' 'xcb-util' 'libxfixes' 'udev')
makedepends=('xorg-server-devel' 'libx11' 'libdrm' 'xf86driproto' 'glproto' 'mesa' 'libxvmc' 'xcb-util' 'xorg-server-ubuntu')
provides=("xf86-video-intel=${pkgver}")
conflicts=('xorg-server<1.10.0' 'xf86-video-i810' 'xf86-video-intel-legacy' 'xf86-video-intel')
options=('!libtool')
groups=('xorg-drivers' 'xorg')
source=("${url}/releases/individual/driver/${pkgname%-*}-${pkgver%.*}.tar.bz2"
        "git-fixes.patch"
        "http://archive.ubuntu.com/ubuntu/pool/main/x/xserver-xorg-video-intel/xserver-xorg-video-intel_${_ubuntu_ver2}-${_ubuntu_ver}.diff.gz")
sha512sums=('e2a8ce427f653350d711cdfa419104f9b33ab3b93bcf5d4d9e0ce5045b34e8754e263dcee37bc26afcb1274ae4fbee4a9c79f41488e975eca939e3bfd243b511'
            'a588356d739c3e4c9c74e6703a26fab9b5a3632631f9ced417389c016cd7fbe338f6ec9d5514c43786b2902778aa74e75c0f8e992387363c472cd7fd8255ac0e'
            '2bb5ab251c58eaaedfdc6e365c0a72e9e8d9d68f98f7363045ca9064722c5c89a2c2ae20cd7d95f905272d8e722313b42308521d177910a3ddbe977c68437d6b')

build() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"

  patch -Np1 -i "${srcdir}/git-fixes.patch"

  #Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xserver-xorg-video-intel_${_ubuntu_ver2}-${_ubuntu_ver}.diff"

  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  autoreconf
  ./configure --prefix=/usr --enable-dri
  make
}

package() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"
  make DESTDIR="${pkgdir}" install
  install -m755 -d "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"
}
