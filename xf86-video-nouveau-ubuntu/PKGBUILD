# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Andreas Radke <andyrtr@archlinux.org>
# Contributor: buddabrod <buddabrod@gmail.com>

pkgname=xf86-video-nouveau-ubuntu
_ubuntu_ver="+git20110411+8378443"
_ubuntu_rel=1
_actual_ver=0.0.16
pkgver=${_actual_ver}$(echo ${_ubuntu_ver} | tr '+' '.')
pkgrel=100
pkgdesc="Open Source 3D acceleration driver for nVidia cards (experimental)"
arch=('i686' 'x86_64')
url="http://nouveau.freedesktop.org/wiki/"
license=('GPL') #and MIT, not yet a license file, see http://nouveau.freedesktop.org/wiki/FAQ#head-09f75d03eb30011c754038a3893119a70745de4e
depends=('libdrm' 'udev')
optdepends=('nouveau-dri:	experimental gallium3d features')
makedepends=('xorg-server-devel' 'libdrm' 'xf86driproto')
provides=("xf86-video-nouveau=${pkgver}")
conflicts=('xorg-server>=1.11.0' 'xf86-video-nouveau')
options=('!libtool')
install=${pkgname%-*}.install
source=("http://archive.ubuntu.com/ubuntu/pool/main/x/xserver-xorg-video-nouveau/xserver-xorg-video-nouveau_${_actual_ver}${_ubuntu_ver}.orig.tar.gz"
        "http://archive.ubuntu.com/ubuntu/pool/main/x/xserver-xorg-video-nouveau/xserver-xorg-video-nouveau_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff.gz")
sha512sums=('5da618ec7d20d1709906f3460661ee027eecdf1dfbc9f4098330d872b955d2c6c569a458f8962a918891cc01484e8335c64e1ae3938f8e643154ad8e48531e03'
            '11cd4bb5514f106cc7dba182e13ac81d3a2e596a9c008b8db6a3477007581b5dff2945bf41895f1de1d1a4c6df46147417c2328ba2059053d35064a2baf32168')

build() {
  cd "${srcdir}/${pkgname%-*}"

  #Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xserver-xorg-video-nouveau_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff"
  for i in $(cat 'debian/patches/series' | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  ./autogen.sh --prefix=/usr
  make
}

package() {
  cd "${srcdir}/${pkgname%-*}"
  make DESTDIR="${pkgdir}/" install
}
