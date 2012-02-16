# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=xf86-input-evdev-ubuntu
_ubuntu_rel=0ubuntu2
_ubuntu_ver="+git20120126"
_actual_ver=2.6.99.901

# The AUR is sooo annoying
pkgver=${_actual_ver}.git20120126.${_ubuntu_rel}

pkgrel=100
pkgdesc="X.org evdev input driver"
arch=('i686' 'x86_64')
url="http://xorg.freedesktop.org/"
license=('custom')
depends=('glibc' 'xorg-server-ubuntu' 'mtdev')
makedepends=('xorg-server-devel-ubuntu')
provides=('xf86-input-evdev')
conflicts=('xorg-server<1.11.0' 'xf86-input-evdev')
options=('!libtool' '!makeflags')
groups=('xorg-drivers' 'xorg')
source=("https://launchpad.net/ubuntu/+archive/primary/+files/xserver-xorg-input-evdev_${_actual_ver}${_ubuntu_ver}.orig.tar.gz"
        "https://launchpad.net/ubuntu/+archive/primary/+files/xserver-xorg-input-evdev_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff.gz")
sha512sums=('09061f439711047fd81025e9d9bc81124ee25256422df3c066a93294f73e0e0e0f4c71dda7aa7b8a6f1b6a222d434a180f827b0732f8bb100a1a95d460771b7d'
            'b8a44f6c7e078408f07e85fc09b0ed199efa233e50f8b708c5b27f9978d10f3457103fda3813c37559fd6e560bc590e14ccd8311322add97adfd609c31793127')

build() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xserver-xorg-input-evdev_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff"

  for i in $(cat 'debian/patches/series' | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  chmod +x autogen.sh
  ./autogen.sh --prefix=/usr
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}"
  make DESTDIR="${pkgdir}" install
  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"
  install -dm755 "${pkgdir}/etc/X11/xorg.conf.d"
  install -m644 'debian/local/11-evdev-quirks.conf' "${pkgdir}/etc/X11/xorg.conf.d/"
  install -m644 'debian/local/11-evdev-trackpoint.conf' "${pkgdir}/etc/X11/xorg.conf.d/"
}
