# Maintainer: Xiao-Long Chen <chenxiaolong@cxl.epac.to>
# Based on Nathan Hulses's PKGBUILD

# Some comments are taken from the Ubuntu packaging files

# Disable build with KDE 4.8 for now
NO_KDE=true

pkgbase=compiz-core-ubuntu

# AUR fix
pkgname=compiz-core-ubuntu
true && pkgname=('compiz-core-ubuntu' 'compiz-gnome-ubuntu' 'compiz-kde-ubuntu')

_kdedeps=('kdebase-workspace' 'kdelibs')
COMPIZ_DISABLE_PLUGIN_KDE="OFF"

# Run makepkg with "NO_KDE=true makepkg" to disable the KDE package
if [[ "${NO_KDE}" == "true" ]]; then
  true && pkgname=('compiz-core-ubuntu' 'compiz-gnome-ubuntu')
  _kdedeps=()
  COMPIZ_DISABLE_PLUGIN_KDE="ON"
fi

_ubuntu_rel="0ubuntu1"
_actual_ver=0.9.7.8

# Another AUR fix
pkgver=${_actual_ver}.${_ubuntu_rel}

pkgrel=100
pkgdesc="OpenGL window and compositing manager"
url="http://www.compiz.org/"
arch=('i686' 'x86_64')
license=('GPL')
makedepends=('boost' 'cmake' 'glibmm' 'gnome-control-center' 'intltool' 'libwnck' 'mesa' 'metacity-ubuntu' 'startup-notification')
if [ ! -z "${_kdedeps}" ]; then
  for dep in ${_kdedeps[@]}; do
    makedepends[${#makedepends[@]}]=${dep}
  done
fi
options=('emptydirs')
source=("https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%%-*}_${_actual_ver}.orig.tar.bz2"
        "https://launchpad.net/ubuntu/+archive/primary/+files/${pkgname%%-*}_${_actual_ver}-${_ubuntu_rel}.debian.tar.gz")
sha512sums=('30bb0c4a19dbeb537129e89b9b0fdafa1c7ce18c2dc25e5ec17965a991d05cedc8d6caf93dea8eab2b065a140f57252380ac142c2edd6909a9f5dcd2700a93a6'
            'ed5b5e57f0f41e67ef26d97952cf89c24e3674576ddbce7903060d0d4784c3b213c5744be2641e5ba11f091720309abca33d55b14ffc6a86d91db9055debf0ca')

build() {
  cd "${srcdir}/${pkgname%%-*}-${_actual_ver}"

  # Apply Ubuntu patches
  for i in $(cat ${srcdir}/debian/patches/series | grep -v '#'); do
    patch -Np1 -i "${srcdir}/debian/patches/${i}"
  done

  # Cannot find libx11
  CXXFLAGS="${CXXFLAGS} $(pkg-config --cflags --libs x11)"

  # Cannot find libdl
  CXXFLAGS="${CXXFLAGS} -ldl"

  # Do not build KDE window decorator if NO_KDE is set to true
  if [[ "${NO_KDE}" == "true" ]]; then
    sed -i '/kde/d' CMakeLists.txt
  fi

  # Set default plugins
  DEFAULT_PLUGINS=(
    'core' 'composite' 'opengl' 'compiztoolbox' 'decor' 'vpswitch' 'snap'
    'mousepoll' 'resize' 'place' 'move' 'wall' 'grid' 'regex' 'imgpng'
    'session' 'gnomecompat' 'animation' 'fade' 'unitymtgrabhandles'
    'workarounds' 'scale' 'expo' 'ezoom'
  )

  # Build fix
  CXXFLAGS="${CXXFLAGS} -Wno-error=sign-compare"

  # Disable '-Bsymbolic-functions' if present so libcompiz_core won't be
  # loaded once per plugin
  LDFLAGS="$(echo ${LDFLAGS} | sed 's/-B[ ]*symbolic-functions//')"

  # Compiz will segfault if the CMake built target is set to 'Release'
  # Disable tests since they can't run on a headless build server

  [[ -d build ]] || mkdir build
  cd build
  cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    `#-DCOMPIZ_DESTDIR="${srcdir}/temp_install"` \
    -DCOMPIZ_BUILD_WITH_RPATH=FALSE \
    -DCOMPIZ_DEFAULT_PLUGINS="${DEFAULT_PLUGINS[@]}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCOMPIZ_PACKAGING_ENABLED=TRUE \
    -DUSE_GSETTINGS=OFF \
    -DCOMPIZ_DISABLE_GS_SCHEMAS_INSTALL=ON \
    -DCOMPIZ_DISABLE_PLUGIN_KDE="${COMPIZ_DISABLE_PLUGIN_KDE}" \
    -DCOMPIZ_BUILD_TESTING=OFF \
    ..

  make ${MAKEFLAGS}

  # Install to temporary directory

  ### Standard installation using make ###
    make DESTDIR="${srcdir}/temp_install" \
      GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL=1 install

    # Stupid findcompiz_install needs COMPIZ_DESTDIR and install needs
    # DESTDIR
    #make findcompiz_install
    CMAKE_DIR=$(cmake --system-information | grep '^CMAKE_ROOT' \
      | awk -F\" '{print $2}')
    install -dm755 "${srcdir}/temp_install${CMAKE_DIR}/Modules/"
    install -m644 ../cmake/FindCompiz.cmake \
      "${srcdir}/temp_install${CMAKE_DIR}/Modules/"

  ### Install documentation ###
    install -dm755 "${srcdir}/temp_install/usr/share/doc/compiz-core/"
    install ../{AUTHORS,NEWS,README,TODO} \
      "${srcdir}/temp_install/usr/share/doc/compiz-core/"

  ### Manual installation of Ubuntu files ###
    ## Create directories
      install -dm755 "${srcdir}/temp_install/usr/bin/"
      install -dm755 "${srcdir}/temp_install/usr/share/man/man1/"
      install -dm755 "${srcdir}/temp_install/etc/X11/xinit/xinitrc.d/"
      install -dm755 "${srcdir}/temp_install/etc/compizconfig/"
      install -dm755 "${srcdir}/temp_install/usr/share/gconf/defaults/"
      install -dm755 \
        "${srcdir}/temp_install/usr/share/gnome-control-center/keybindings/"
      install -dm755 "${srcdir}/temp_install/usr/share/gnome/wm-properties/"
      install -dm755 "${srcdir}/temp_install/etc/compizconfig/upgrades/"

    ## Install files
      # Compiz decorator
        install -m755 "${srcdir}/debian/compiz-decorator" \
          "${srcdir}/temp_install/usr/bin/"

      # Manual pages
        install -m644 \
          "${srcdir}/debian/compiz.1" \
          "${srcdir}/debian/compiz-decorator.1" \
          "${srcdir}/debian/gtk-window-decorator.1" \
          "${srcdir}/debian/kde4-window-decorator.1" \
          "${srcdir}/temp_install/usr/share/man/man1/"

      # Window manager desktop file for GNOME
        install -m644 \
          "${srcdir}/temp_install/usr/share/applications/compiz.desktop" \
          "${srcdir}/temp_install/usr/share/gnome/wm-properties/"

      # X11 startup script
        install -m755 "${srcdir}/debian/65compiz_profile-on-session" \
          "${srcdir}/temp_install/etc/X11/xinit/xinitrc.d/"

      # Unity Compiz plugin configuration file
        install -m644 "${srcdir}/debian/unity.ini" \
          "${srcdir}/temp_install/etc/compizconfig/"

      # Compiz profile upgrade helper files for ensuring smooth upgrades
      # from older configuration files
        for i in $(find "${srcdir}/debian/profile_upgrades/" -type f \
            -name "*.upgrade"); do
          install -m644 "${i}" \
            "${srcdir}/temp_install/etc/compizconfig/upgrades/"
        done

      # Default GConf settings
        install -m644 "${srcdir}/debian/compiz-gnome.gconf-defaults" \
          "${srcdir}/temp_install/usr/share/gconf/defaults/10_compiz-gnome"

      # Create keybindings for Compiz based on the Metacity ones
        KEYBIND_DIR=/usr/share/gnome-control-center/keybindings
        for i in launchers navigation screenshot system windows; do
          # Keep 'package=metacity' to use translations from Metacity
          sed 's/wm_name=\"Metacity\"/wm_name=\"Compiz\"/' \
          "/usr/share/gnome-control-center/keybindings/50-metacity-${i}.xml" \
          > "${srcdir}/temp_install${KEYBIND_DIR}/50-compiz-${i}.xml"
        done
        # Add selected keys
        sed -i 's#key=\"/apps/metacity/general/num_workspaces\" comparison=\"gt\"##g' \
          "${srcdir}/temp_install${KEYBIND_DIR}/50-compiz-navigation.xml"

  ### Modify files ###
    # Allow desktop files to translated using gettext
      for d in $(find "${srcdir}/temp_install" -type f \
        \( -name "*.desktop" -o -name "*.directory" \) ); do
        sed -ri '/^(Name|GenericName|Comment|X-GNOME-FullName)\[/d' "${d}"
        echo "X-Ubuntu-Gettext-Domain=compiz" >> "${d}"
      done

  ### Remove files ###
    # Remove static libraries
    #rm "${srcdir}"/temp_install/usr/lib/*.a

  ### Temporary (easier to see what went wrong during build) ###
    cp -rv "${srcdir}/temp_install" "${srcdir}/temp_install.bak"
}

package_compiz-kde-ubuntu() {
  pkgdesc="OpenGL window and compositing manager - KDE window decorator"
  groups=('unity' 'compiz-ubuntu')
  depends=('kdebase-workspace' 'compiz-core-ubuntu' 'compizconfig-backend-kconfig4')
  optdepends=('compizconfig-backend-kconfig4-ubuntu: Store sttings with KConfig')
  provides=("compiz-decorator-kde=${pkgver}")
  conflicts=('compiz-decorator-kde')

  ### Install files that belong in this package ###
    ## Create directories
      install -dm755 "${pkgdir}/usr/bin/"
      install -dm755 "${pkgdir}/usr/lib/compiz/"
      install -dm755 "${pkgdir}/usr/share/compiz/"
      install -dm755 "${pkgdir}/usr/share/man/man1/"

    ## Install files
      # Compiz KDE window decorator
        mv "${srcdir}/temp_install/usr/bin/kde4-window-decorator" \
          "${pkgdir}/usr/bin/"

      # Compiz KDE libraries
        mv "${srcdir}/temp_install/usr/lib/compiz/libkde.so" \
          "${pkgdir}/usr/lib/compiz/"

      # Compia KDE data files
        mv "${srcdir}/temp_install/usr/share/compiz/kde.xml" \
          "${pkgdir}/usr/share/compiz/"

      # Compiz KDE manual page
        MAN_DIR=/usr/share/man/man1
        mv "${srcdir}/temp_install${MAN_DIR}/kde4-window-decorator.1" \
          "${pkgdir}${MAN_DIR}/"
}

package_compiz-gnome-ubuntu() {
  pkgdesc="OpenGL window and compositing manager - GNOME window decorator"
  groups=('unity' 'compiz-ubuntu')
  depends=('gnome-control-center' 'metacity-ubuntu' 'compiz-core' 'gconf-ubuntu' 'glibmm')
  optdepends=('compizconfig-backend-gconf-ubuntu: Store settings in GNOME GConf database')
  provides=("compiz-decorator-gtk=${pkgver}")
  conflicts=('compiz-decorator-gtk')
  install=compiz-gnome-ubuntu.install

  ### Install files that belong in this package ###
    ## Create directories
      install -dm755 "${pkgdir}/etc/X11/xinit/xinitrc.d/"
      install -dm755 "${pkgdir}/etc/compizconfig/upgrades/"
      install -dm755 "${pkgdir}/usr/bin/"
      install -dm755 "${pkgdir}/usr/share/gconf/defaults/"
      install -dm755 "${pkgdir}/usr/share/gconf/schemas/"
      install -dm755 "${pkgdir}/usr/share/gnome-control-center/keybindings/"
      install -dm755 "${pkgdir}/usr/share/gnome/wm-properties/"
      install -dm755 "${pkgdir}/usr/share/man/man1/"

    ## Install files
      # X11 startup script
        X11_DIR=/etc/X11/xinit/xinitrc.d
        mv "${srcdir}/temp_install${X11_DIR}/65compiz_profile-on-session" \
          "${pkgdir}${X11_DIR}/"

      # Unity Compiz plugin configuration file
        mv "${srcdir}/temp_install/etc/compizconfig/unity.ini" \
          "${pkgdir}/etc/compizconfig/"

      # Unity Compiz plugin profile upgrade helpers
        UPGRADE_DIR=/etc/compizconfig/upgrades
        FILE=com.canonical.unity.unity
        mv \
          "${srcdir}"/temp_install${UPGRADE_DIR}/${FILE}.0{1,2}.upgrade \
          "${pkgdir}${UPGRADE_DIR}/"

      # Compiz GTK window decorator
        mv \
          "${srcdir}/temp_install/usr/bin/gtk-window-decorator" \
          "${pkgdir}/usr/bin/"

      # Default GConf settings
        GCONF_DIR=/usr/share/gconf/defaults
        mv "${srcdir}/temp_install${GCONF_DIR}/10_compiz-gnome" \
          "${pkgdir}${GCONF_DIR}/"

      # GConf schemas
        GCONF_SCHEMAS=(
          'compiz-annotate.schemas'
          'compiz-blur.schemas' 'compiz-clone.schemas'
          'compiz-commands.schemas' 'compiz-compiztoolbox.schemas'
          'compiz-composite.schemas' 'compiz-copytex.schemas'
          'compiz-core.schemas' 'compiz-cube.schemas'
          'compiz-dbus.schemas' 'compiz-decor.schemas'
          'compiz-fade.schemas' 'compiz-gnomecompat.schemas'
          'compiz-imgpng.schemas' 'compiz-imgsvg.schemas'
          'compiz-inotify.schemas' 'compiz-kde.schemas'
          'compiz-move.schemas' 'compiz-obs.schemas'
          'compiz-opengl.schemas' 'compiz-place.schemas'
          'compiz-regex.schemas' 'compiz-resize.schemas'
          'compiz-rotate.schemas' 'compiz-scale.schemas'
          'compiz-screenshot.schemas' 'compiz-switcher.schemas'
          'compiz-water.schemas' 'compiz-wobbly.schemas' 'gwd.schemas'
        )
        for i in ${GCONF_SCHEMAS[@]}; do
          if [ -z "${_kdedeps[@]}" ] && \
            [[ "${i}" == "compiz-kde.schemas" ]]; then
            continue
          fi
          mv "${srcdir}/temp_install/usr/share/gconf/schemas/${i}" \
            "${pkgdir}/usr/share/gconf/schemas/"
        done

      # Keybindings
        KEYBINDINGS=(
          '50-compiz-launchers.xml' '50-compiz-navigation.xml'
          '50-compiz-screenshot.xml' '50-compiz-system.xml'
          '50-compiz-windows.xml'
        )
        KEYBIND_DIR=/usr/share/gnome-control-center/keybindings
        for i in ${KEYBINDINGS[@]}; do
          mv "${srcdir}/temp_install${KEYBIND_DIR}/${i}" \
            "${pkgdir}${KEYBIND_DIR}/"
        done

      # Compiz window manager desktop file for GNOME
        WM_DIR=/usr/share/gnome/wm-properties
        mv "${srcdir}/temp_install${WM_DIR}/compiz.desktop" \
          "${pkgdir}${WM_DIR}/"

      # Manual pages
        MAN_DIR=/usr/share/man/man1
          mv "${srcdir}/temp_install${MAN_DIR}/gtk-window-decorator.1" \
            "${pkgdir}${MAN_DIR}/"
}

package_compiz-core-ubuntu() {
  pkgdesc="OpenGL window and compositing manager"
  groups=('unity' 'compiz-ubuntu')
  depends=('startup-notification' 'mesa' 'dbus' 'libxslt' 'fuse' 'glibmm' 'libxrandr' 'libxdamage' 'libxcomposite' 'librsvg' 'boost-libs' 'libxinerama')
  optdepends=()
  provides=("compiz-core=${pkgver}")
  conflicts=('compiz-core')
  optdepends=('ccsm-ubuntu: CompizConfig Settings Manager'
              'compiz-gnome-ubuntu: GNOME/Unity support'
              'compizconfig-backend-gconf-ubuntu: Store settings in GNOME GConf database'
              'compiz-kde-ubuntu: KDE support'
              'compizconfig-backend-kconfig4-ubuntu: Store sttings with KConfig'
              'compiz-plugins-main-ubuntu: Main plugins'
              'compiz-plugins-extra-ubuntu: Extra plugins')

  ### Install files that belong in this package ###
    ## Create directories
      install -dm755 "${pkgdir}/usr/bin/"
      install -dm755 "${pkgdir}/usr/include/"
      install -dm755 "${pkgdir}/usr/lib/"

    ## Install files
      # Documentation
        install -dm755 "${pkgdir}/usr/share/doc/compiz-core/"
        for i in AUTHORS NEWS README TODO; do
          mv "${srcdir}/temp_install/usr/share/doc/compiz-core/${i}" \
            "${pkgdir}/usr/share/doc/compiz-core/${i}"
        done

      # Binaries
        mv \
          "${srcdir}/temp_install/usr/bin/compiz" \
          "${srcdir}/temp_install/usr/bin/compiz-decorator" \
          "${pkgdir}/usr/bin/"

      # libdecoration libraries
        mv "${srcdir}"/temp_install/usr/lib/libdecoration.so* \
          "${pkgdir}/usr/lib/"

      # Compiz core libraries
        install -dm755 "${pkgdir}/usr/lib/"
        pushd "${srcdir}/temp_install/usr/lib"
        for file in $(find . -maxdepth 1 \( -type f -o -type l \) \
          -name 'libcompiz_core*'); do
          mv "${file}" "${pkgdir}/usr/lib/${file}"
        done
        popd

      # Source headers, localization files, desktop files, pkgconfig files
        for dir in \
          usr/include usr/share/locale \
          usr/share/applications usr/lib/pkgconfig; do
          pushd "${srcdir}/temp_install/${dir}"
          for file in $(find . -type f); do
            install -Dm644 "${file}" "${pkgdir}/${dir}/${file}"
            rm "${file}"
          done
          popd
        done

      # Non-KDE and non-GNOME Compiz libraries
        pushd "${srcdir}/temp_install/usr/lib/compiz/"
        for file in $(find . -type f ! -name 'libkde.so'); do
          install -Dm755 "${file}" "${pkgdir}/usr/lib/compiz/${file}"
          rm "${file}"
        done
        popd

      # Compiz data files
        pushd "${srcdir}/temp_install/usr/share/compiz/"
        for file in $(find . -type f ! -name 'kde.xml'); do
          install -Dm644 "${file}" "${pkgdir}/usr/share/compiz/${file}"
          rm "${file}"
        done
        popd

      # Non-KDE and non-GNOME Manual pages
        pushd "${srcdir}/temp_install/usr/share/man/"
        for file in $(find . -type f ! -name 'kde4-window-decorator.1' \
          ! -name 'gtk-window-decorator.1'); do
          install -Dm644 "${file}" "${pkgdir}/usr/share/man/${file}"
          rm "${file}"
        done

      # CMake files
        pushd "${srcdir}/temp_install/usr/share/"
        for file in $(find cmake* -type f); do
          install -Dm644 "${file}" "${pkgdir}/usr/share/${file}"
          rm "${file}"
        done
        popd
}

# vim:set ts=2 sw=2 et:
