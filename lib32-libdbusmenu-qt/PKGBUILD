# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Andrea Scarpino <andrea@archlinux.org>

# vercheck-pkgbuild: auto
# vercheck-ubuntu: name=libdbusmenu-qt, repo=utopic
# vercheck-launchpad: name=libdbusmenu-qt

pkgname=lib32-libdbusmenu-qt
pkgver=0.9.2
pkgrel=1
pkgdesc="A library that provides a Qt implementation of the DBusMenu spec (32-bit)"
arch=(x86_64)
url="https://launchpad.net/libdbusmenu-qt"
license=(GPL)
depends=(lib32-qt4)
makedepends=(cmake gcc-multilib lib32-qjson)
source=("http://launchpad.net/libdbusmenu-qt/trunk/${pkgver}/+download/libdbusmenu-qt-${pkgver}.tar.bz2")
sha512sums=('07f5ea2a7ce32f82dbd11ca3fa5f5b7c10d3cca8dcd2e942d46452f978cbb5bc312d6b10058554330b0b983047e61a4b84cf3a6ae53ba43e89e1e0b81edba126')

build() {
  cd "libdbusmenu-qt-${pkgver}"

  export CC="gcc -m32"
  export CXX="g++ -m32"

  cmake . \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIB_SUFFIX=32 \
    -DWITH_DOC=OFF

  make
}

package() {
  cd "libdbusmenu-qt-${pkgver}"
  make DESTDIR="${pkgdir}" install

  rm -r "${pkgdir}/usr/include/"

  sed -i '/^libdir/s/\(\/lib\)/\132/g' "${pkgdir}/usr/lib32/pkgconfig/dbusmenu-qt.pc"
}
