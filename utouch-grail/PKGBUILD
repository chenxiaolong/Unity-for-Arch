# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Contributor: thn81 <root@scrat>

pkgname=utouch-grail
pkgver=3.0.5
pkgrel=100
pkgdesc="Gesture Recognition And Instantiation Library"
arch=('i686' 'x86_64')
url="https://launchpad.net/utouch-grail"
license=('GPL')
depends=('utouch-frame' 'libxi')
makedepends=('inputproto')
options=('!libtool')
source=("http://launchpad.net/${pkgname}/trunk/${pkgname}-${pkgver}/+download/${pkgname}-${pkgver}.tar.gz")
sha512sums=('364858c966b680468d9de12986f6d5d36a82d6bf2918f6f3d75fe9da802d444d05fbee0a947e4a7387ee5d96f3071057775a67b45a766ab77faee4dabd038597')

build() {
  cd "${srcdir}/${pkgname}-${pkgver}"

  # Static library needed for tests
  ./configure --prefix=/usr # --disable-static
  MAKEFLAGS="-j1"
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname}-${pkgver}"
  make DESTDIR="${pkgdir}/" install
}
