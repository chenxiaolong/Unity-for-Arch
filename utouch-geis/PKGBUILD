# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=utouch-geis
pkgver=2.2.10
pkgrel=100
pkgdesc="Implementation of the GEIS (Gesture Engine Interface and Support) interface."
arch=('i686' 'x86_64')
url="https://launchpad.net/utouch-geis"
license=('GPL' 'LGPL')
depends=('utouch-grail' 'xorg-xinput' 'python2' 'dbus-core')
options=('!emptydirs' '!libtool')
source=("http://launchpad.net/${pkgname}/trunk/${pkgname}-${pkgver}/+download/${pkgname}-${pkgver}.tar.gz")
sha512sums=('58d848e3462b9bf8d8d13b5c9e4935021372aefddd2f723bdd12be42d04e59d57054863fac238822f65192d168bb3e4d9889c1da12f46e1011102aead4e4be49')

build() {
  cd "${srcdir}/${pkgname}-${pkgver}"

  PYTHON2VER=$(ls -l /usr/bin/python2 2>&1 | sed 's/^.*\(.\..\)/\1/g')
  sed -i "/python >= ${PYTHON2VER}/s/python \(>= .\..\)/python-${PYTHON2VER} \1/g" configure
  PYTHON=/usr/bin/python2 ./configure --prefix=/usr --disable-static
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}/" install
  sed -i 's|\(#!.*bin.*python$\)|\12|g' "${pkgdir}"/usr/bin/{geisview,pygeis} "${pkgdir}/usr/lib/python2.7/site-packages/geisview/__init__.py"
}

# vim:set ts=2 sw=2 et:
