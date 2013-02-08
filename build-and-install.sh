#!/bin/bash
packages=(gtk2-ubuntu gtk3-ubuntu libdbusmenu libindicator libindicate libindicate-qt appmenu-gtk libunity libunity-misc indicator-messages libunity-webapps bamf sni-qt ido gnome-settings-daemon-ubuntu gnome-session-ubuntu gnome-control-center-ubuntu gnome-control-center-unity credentials-preferences metacity-ubuntu indicator-applet indicator-application indicator-appmenu indicator-bluetooth indicator-datetime indicator-power indicator-printers indicator-session indicator-sound network-manager-applet-ubuntu overlay-scrollbar evemu frame fixesproto-ubuntu libxfixes-ubuntu xorg-server-ubuntu grail geis nux unity-asset-pool nautilus-ubuntu python-oauthlib unity-lens-applications unity-lens-files unity-lens-music unity-lens-photos unity-lens-video unity-scope-video-remote compiz-ubuntu unity)
for package in "${packages[@]}"; do
	cd "${package}"
	rm -rf src
	makepkg -fi
	cd ..
done
