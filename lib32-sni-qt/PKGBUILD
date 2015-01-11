# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

# vercheck-pkgbuild: auto
# vercheck-ubuntu: name=sni-qt, repo=utopic

pkgname=lib32-sni-qt
pkgver=0.2.6
pkgrel=3
pkgdesc="A Qt plugin which turns all QSystemTrayIcon into StatusNotifierItems (appindicators) (32-bit)"
arch=(x86_64)
url="https://launchpad.net/sni-qt"
license=(GPL)
groups=(unity)
depends=(sni-qt lib32-libdbusmenu-qt lib32-qt4-ubuntu)
makedepends=(cmake gcc-multilib)
source=("http://launchpad.net/sni-qt/trunk/${pkgver}/+download/sni-qt-${pkgver}.tar.bz2"
        "qconfig.h")
sha512sums=('aa4cffeb3a5a70d65bd5ff42dcdd1c8efd107ade32a104b9a91696aecfb39a7a15d151f7491030ac0d7df796f2c7e4e6c3c0b7e32ee07a7cdc949da757147621'
            '193ab479bcf35ecc5d75e575a7551016e416003fd26ac88664a5c64e6dcbf5ce50685c5803e0edba8c3b188d63acd15b7965fca771f03e6c8d573a0354d51290')

prepare() {
  mkdir -p "${srcdir}/QtCore"
  ln -sf "${srcdir}/qconfig.h" "${srcdir}/QtCore/"
}

build() {
  cd "sni-qt-${pkgver}"

  export CC="gcc -m32"
  export CXX="g++ -m32"
  export PKG_CONFIG_PATH=/usr/lib32/pkgconfig

  export CFLAGS="\"-I${srcdir}\" ${CFLAGS}"
  export CXXFLAGS="\"-I${srcdir}\" ${CXXFLAGS}"

  cmake . \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_PLUGINS_DIR=/usr/lib32/qt/plugins

  make
}

package() {
  cd "sni-qt-${pkgver}"
  make DESTDIR="${pkgdir}/" install
}
