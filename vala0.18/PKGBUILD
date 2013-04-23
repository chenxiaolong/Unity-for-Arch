# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Original Maintainer: Ionut Biru <ibiru@archlinux.org>
# Contributor: Timm Preetz <timm@preetz.us>

pkgname=vala0.18
pkgver=0.18.1
pkgrel=1
pkgdesc="Compiler for the GObject type system"
arch=('i686' 'x86_64')
url="http://live.gnome.org/Vala"
license=('LGPL')
depends=('glib2')
makedepends=('gobject-introspection' 'libxslt')
checkdepends=('libx11')
conflicts=("vala<=${pkgver}")
options=('!libtool')
source=("http://ftp.gnome.org/pub/gnome/sources/vala/${pkgver%.*}/vala-${pkgver}.tar.xz")
sha512sums=('e4459738b916d6b70c633844db3e0b0fed0f186d3f44cd3e4cac3c486a7d8b7a4bb0f58620b8b0c367f61bf6358a6b511edf924533eb8bb2ee49ac36069ee4db')

build() {
  cd "${srcdir}/vala-${pkgver}"
  ./configure --prefix=/usr --enable-vapigen
  make
}

check() {
  cd "${srcdir}/vala-${pkgver}"
  make check
}

package() {
  cd "${srcdir}/vala-${pkgver}"
  make DESTDIR="${pkgdir}" install

  pushd "${pkgdir}"

  rm -v usr/bin/{vala{,-gen-introspect,c},vapi{check,gen}}
  rm -v usr/share/man/man1/{vala{-gen-introspect,c},vapigen}.1
  rm -v usr/share/pkgconfig/vapigen.pc
  rm -rv usr/share/{aclocal,vala}/

  popd
}

# vim:set ts=2 sw=2 et:
