# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=compiz-plugins-main-ubuntu

_ubuntu_rel=0ubuntu10
_ubuntu_ver='~bzr19'
_actual_ver=0.9.7.0

pkgver=${_actual_ver}.bzr19.${_ubuntu_rel}
pkgrel=100
pkgdesc="Compiz main plugins - Ubuntu version"
url="http://www.compiz.org/"
license=('GPL' 'LGPL' 'MIT')
arch=('i686' 'x86_64')
provides=('compiz-plugins-main')
conflicts=('compiz-plugins-main')
groups=('unity')
depends=('compiz-core-ubuntu' 'gconf-ubuntu' 'glib2-ubuntu' 'libjpeg-turbo')
makedepends=('intltool' 'cmake' 'pkgconfig' 'libtool')
install=compiz-plugins-main-ubuntu.install
source=("https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${_actual_ver}${_ubuntu_ver}.orig.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%-*}_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.debian.tar.gz")
sha512sums=('6b408584851699e8661b674446f0a8fa7dc7f2fff9530a0fb31d4f099f2b7c818e3135365c925b6d2d1b2c02463089247306ade3cfeedfda17ae491eb2c6b857'
            '051bf6efc21da779431f4cc2e2e2aaf525e63bc8518080da42abe928e03ddc6c62af697dc10415206e94ef92e148cdb17c1567baeef1898014822b0cdf49df43')

build() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}"

  # Apply Ubuntu patches
  for i in $(cat "${srcdir}/debian/patches/series" | grep -v '#'); do
    patch -Np1 -i "${srcdir}/debian/patches/${i}"
  done

  [[ -d build ]] || mkdir build
  cd build
  cmake .. \
    -DCMAKE_BUILD_WITH_RPATH=FALSE \
    -DCOMPIZ_PACKAGING_ENABLED=TRUE \
    -DCOMPIZ_PLUGIN_INSTALL_TYPE=package \
    -DUSE_GSETTINGS=OFF \
    -DCOMPIZ_DISABLE_GS_SCHEMAS_INSTALL=ON \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX=/usr

  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-${_actual_ver}/build"
  make DESTDIR="${pkgdir}" install
}

# vim:set ts=2 sw=2 et:
