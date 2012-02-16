# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=compizconfig-backend-kconfig4-ubuntu
_ubuntu_rel=0ubuntu1
pkgver=0.9.2.${_ubuntu_rel}
pkgrel=101
pkgdesc="Compizconfig KDE 4 kconfig backend - Ubuntu version"
url="http://www.compiz.org/"
license=('GPL' 'LGPL' 'MIT')
arch=('i686' 'x86_64')
depends=('libcompizconfig-ubuntu' 'kdelibs' 'libxcomposite' 'libxinerama')
makedepends=('intltool' 'cmake')
provides=('compizconfig-backend-kconfig4')
conflicts=('compizconfig-backend-kconfig4')
groups=('unity')
source=("https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%4*}_${pkgver%.*}.orig.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%4*}_${pkgver%.*}-${_ubuntu_rel}.debian.tar.gz"
        'build_fix.patch')
sha512sums=('08577238c6518bf858676b5c31223e9e8e0c474a7dd114fc5c1a7e3781af5e3ea0ab469e956bc8444c4f26ca552614ea7b41d61cbee3e0a9824fb907789e5fb8'
            'c1ad32da1d45ba5302fe981894d9661cd383098aeb89b5eda8938760a57b2d7988dcae1ee0c14ddbe5e53f33c8652acca6e2af6901670a250c3b6936b83fea26'
            'f1e65358c16c647bc2f0e007086a966de295804ee50b4adef6c729ed34937d2696c1e955171a4111af7b5c6aaea464bbb675e96a344abdef48eb41affd24d041')

build() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"

  # Apply Ubuntu patches
  for i in $(cat ${srcdir}/debian/patches/series | grep -Ev '#'); do
    patch -Np1 -i "${srcdir}/debian/patches/${i}"
  done

  # Build fix by somebody who doesn't know programming (me :D)
  # It compiles now...not sure if it works or not...
  patch -Np1 -i "${srcdir}/build_fix.patch"

  [[ -d build ]] || mkdir build
  cd build
  cmake .. \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX=/usr

  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"
  cd build
  make DESTDIR="${pkgdir}/" install
}

