# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=ccsm-ubuntu
_ubuntu_rel=0ubuntu3
pkgver=0.9.5.92.${_ubuntu_rel}
pkgrel=101
pkgdesc="Compizconfig Settings Manager in Python - Ubuntu version"
arch=('any')
url="http://compiz.org"
license=('GPL')
provides=('ccsm')
conflicts=('ccsm')
groups=('unity')
depends=('compiz-core-ubuntu' 'compizconfig-python-ubuntu' 'pygtk')
install="ccsm-ubuntu.install"
source=("https://launchpad.net/ubuntu/+archive/primary/+files/compizconfig-settings-manager_${pkgver%.*}.orig.tar.gz"
        "https://launchpad.net/ubuntu/+archive/primary/+files/compizconfig-settings-manager_${pkgver%.*}-${_ubuntu_rel}.diff.gz")
sha512sums=('541feec8384540ca011190aceb9596d558ff4b71f03e64b7e8800adcdf942d9a47fe53859820ecad74f7b80d0914c4d7be5bd4499db8551d554701a3edf93802'
            '40a25bfc873e116e41c0ac29f08c60f0131681eed38a6331304215df765d954712c9e4bf697215856562b93a39e115c2ffc4a7386ef42bafc46b5973e19ca93c')

build() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/compizconfig-settings-manager_${pkgver%.*}-${_ubuntu_rel}.diff"

  sed -i 's|^\(#!.*python\)$|\12|g' ccsm
  python2 setup.py build --prefix="/usr"
}

package() {
  cd "${srcdir}/${pkgname%-*}-${pkgver%.*}"
  python2 setup.py install --prefix="/usr" --root="${pkgdir}"
  install -dm755 "${pkgdir}/usr/share/applications/"
  install -m644 "${pkgname%-*}.desktop" "${pkgdir}/usr/share/applications/"
}
