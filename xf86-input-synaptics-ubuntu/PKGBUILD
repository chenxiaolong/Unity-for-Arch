# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>

pkgname=xf86-input-synaptics-ubuntu
_ubuntu_ver="+git20120210"
_ubuntu_rel=0ubuntu2
_actual_ver=1.5.0

# The AUR is sooo annoying...
pkgver=${_actual_ver}.git20120210.${_ubuntu_rel}

pkgrel=1
pkgdesc="Synaptics driver for notebook touchpads"
arch=('i686' 'x86_64')
license=('custom')
url="http://xorg.freedesktop.org/"
depends=('libxtst' 'xorg-server-ubuntu')
makedepends=('xorg-server-devel-ubuntu' 'libxi-ubuntu' 'libx11-ubuntu')
conflicts=('xorg-server<1.11.0')
replaces=('synaptics' 'xf86-input-synaptics')
provides=('synaptics' 'xf86-input-synaptics')
conflicts=('synaptics' 'xf86-input-synaptics')
groups=('xorg-drivers' 'xorg')
options=(!libtool)
backup=('etc/X11/xorg.conf.d/10-synaptics.conf')
source=("10-synaptics.conf"
        "https://launchpad.net/ubuntu/+archive/primary/+files/xserver-xorg-input-synaptics_${_actual_ver}${_ubuntu_ver}.orig.tar.gz"
        "https://launchpad.net/ubuntu/+archive/primary/+files/xserver-xorg-input-synaptics_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff.gz")
sha512sums=('3e78c3c77e58ca9de19fc97b9cc3d7d6d08a740bacf005d564de9193e60037a0262ed6b0841f2b3d98adb5ba60675f4856569978d5cb47c4ed2312e47fe6c085'
            '576329dbeb34139a522200a87decee63dc0f30b3689cf77126d767bff3128e48454f5509ed08b761b93a00ddc1e2a74591ce421efcd85982970b79547680e169'
            'cbf9efd272f419bd713858fb33037905bf439cc081471e68148ed84de1f86453eb0c893aff3b66f91301e6e23793462f5a8247bdfa7580d606dfbe57e1dd51ea')

build() {
  cd "${srcdir}/${pkgname%-*}-1.5.99"

  # Apply Ubuntu patches
  patch -Np1 -i "${srcdir}/xserver-xorg-input-synaptics_${_actual_ver}${_ubuntu_ver}-${_ubuntu_rel}.diff"
  for i in $(cat debian/patches/series | grep -v '#'); do
    patch -Np1 -i "debian/patches/${i}"
  done

  chmod +x autogen.sh
  ./autogen.sh --prefix=/usr
  make ${MAKEFLAGS}
}

package() {
  cd "${srcdir}/${pkgname%-*}-1.5.99"
  make DESTDIR="${pkgdir}" install
  install -dm755 "${pkgdir}/etc/X11/xorg.conf.d"
  install -m644 "${srcdir}/10-synaptics.conf" "${pkgdir}/etc/X11/xorg.conf.d/"
  install -dm755 "${pkgdir}/usr/share/licenses/${pkgname%-*}"
  install -m644 COPYING "${pkgdir}/usr/share/licenses/${pkgname%-*}/"

  #rm -rf "${pkgdir}/usr/share/X11"
}
