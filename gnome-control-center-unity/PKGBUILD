# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=gnome-control-center-unity
pkgver=1.2daily13.02.15
pkgrel=1
pkgdesc="A set of settings panels for configuring the Unity desktop"
arch=('i686' 'x86_64')
url="https://launchpad.net/gnome-control-center-unity"
license=('GPL')
groups=('unity')
depends=('gnome-control-center-ubuntu' 'gsettings-desktop-schemas' 'libnotify' 'libxml2')
makedepends=('gnome-common' 'intltool')
options=('!libtool')
install=${pkgname}.install
source=("https://launchpad.net/ubuntu/+archive/primary/+files/gnome-control-center-unity_${pkgver}.orig.tar.gz")
sha512sums=('f49800f6c522cd6fbcca30926405bca469fc75b512f7e265f8ff49fc25a39e7b6dbe41b3957f8152f1df010d8012f1f95d8e7b8cf7d35d0d093fd852718bafd0')

build() {
  cd "${srcdir}/${pkgname}-${pkgver}"

  autoreconf -vfi
  intltoolize -f

  ./configure --prefix=/usr --disable-static
  make ${MAKEFLAGS}
}

check() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  make -k check
}

package() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}/" install
}

# vim:set ts=2 sw=2 et:
