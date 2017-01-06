[![Build Status](https://jenkins.noobdev.io/job/ArchLinux_Build_Package/badge/icon)](https://jenkins.noobdev.io/job/ArchLinux_Build_Package/)

Unity-for-Arch
==============
This project is a port of the Ubuntu Unity desktop and most of its features to Arch Linux. Please see the [Arch Wiki](https://wiki.archlinux.org/index.php/unity) for more information.

Thanks
------
* thn81
* L42y
* City-Busz
* All of the other AUR maintainers that helped make it possible to run Unity under Arch Linux

Compiling from source
---------------------
Please make sure you don't already have modified versions of the dependencies installed. For example, gtk3-ubuntu might fail to compile if there's a modified version of gtk3 already installed.

Packages ending with "-ubuntu" contain Ubuntu patches and *REPLACE* Arch Linux versions of those packages.

To compile from source, just build all of the packages in the following order:

| Package                          | Description                                |
| -------------------------------- | ------------------------------------------ |
| dbus-activation-env              | Push session env vars to dbus/systemd      |
| gtk2-ubuntu                      | GTK toolkit 2.0 with Ubuntu's patches      |
| gtk3-ubuntu                      | GTK toolkit 3.0 with Ubuntu's patches      |
| libdbusmenu-ubuntu               | Library for passing menus over DBus        |
| ido                              | Widgets and objects used for indicators    |
| libindicator                     | Symbols and functions for indicators       |
| libindicate                      | Libraries to raise 'flags' on DBus         |
| libindicate-qt                   | Qt 4 bindings for libindicate              |
| libappindicator                  | Library to export menu bar to Unity        |
| unity-gtk-module                 | Application menu module for GTK+           |
| dee-ubuntu                       | Model to synchronize instances over DBus   |
| libunity                         | Library for integrating with Unity         |
| libunity-misc                    | Differently licensed stuff for Unity       |
| indicator-messages               | Collects messages that need a response     |
| bamf-ubuntu                      | Application matching framework             |
| libtimezonemap                   | GTK+3 timezone map widget                  |
| gsettings-desktop-schemas-ubuntu | Shared GSettings schemas for the desktop   |
| gsettings-ubuntu-schemas         | GSettings desktop-wide schemas for Ubuntu  |
| gnome-settings-daemon-ubuntu     | Daemon handling the GNOME session settings |
| gnome-session-ubuntu             | GNOME Session Manager                      |
| gnome-screensaver-ubuntu         | GNOME screen saver and locker              |
| unity-settings-daemon            | Daemon handling the Unity session settings |
| libgeonames                      | Library for parsing local geonames.org DB  |
| unity-control-center             | Utilities to configure the Unity desktop   |
| properties-cpp                   | C++11 library providing properties/signals |
| lightdm-ubuntu                   | Cross-desktop lightweight display manager  |
| unity-api                        | API for Unity shell integration            |
| appmenu-qt                       | Global menus support for Qt4               |
| appmenu-qt5                      | Global menus support for Qt5               |
| indicator-application            | Takes menus and puts them in the panel     |
| indicator-appmenu                | Indicator to host the menus from apps      |
| indicator-datetime               | Indicator to show the date and time        |
| indicator-keyboard               | Indicator to show kb. layout/input method  |
| indicator-power                  | Indicator to show battery information      |
| indicator-printers               | Indicator to show active print jobs        |
| indicator-session                | Indicator for session management           |
| indicator-sound                  | Indicator to show a unified sound menu     |
| gsettings-qt                     | Library to access GSettings from Qt        |
| dee-qt                           | Qt5 bindings for dee                       |
| libcolumbus                      | Small, fast, error tolerant matcher        |
| hud                              | Backend for the Unity HUD                  |
| network-manager-applet-ubuntu    | NetworkManager applet w/indicator support  |
| overlay-scrollbar                | Overlay scrollbars for GTK+2 and GTK+3     |
| frame                            | Open Input Framework Frame Library         |
| grail                            | Gesture recognition and instantiation lib. |
| geis                             | Implementation of the GEIS interface       |
| glew-unity                       | The OpenGL Extension Wrangler Library      |
| nux                              | An OpenGL toolkit for Unity                |
| unity-asset-pool                 | Design assets for Unity                    |
| nautilus-ubuntu                  | File manager for GNOME and Unity           |
| zeitgeist-ubuntu                 | Service for logging user activities        |
| libzeitgeist                     | Zeitgeist client library                   |
| unity-lens-applications          | Unity lens for searching applications      |
| unity-lens-files                 | Unity lens for searching files             |
| unity-lens-music                 | Unity lens for searching music library     |
| unity-lens-photos                | Unity lens for searching photos            |
| unity-lens-video                 | Unity lens for searching videos            |
| unity-scope-home                 | Unity lens for aggregating search results  |
| unity-scopes                     | Unity scopes for searching online sources  |
| compiz-ubuntu                    | Compositing window manager                 |
| lightdm-unity-greeter            | LightDM greeter for Unity                  |
| unity                            | Desktop shell designed for efficiency      |
| unity-language-packs             | Unity language packs                       |

Troubleshooting
---------------
See the [Arch wiki](https://wiki.archlinux.org/index.php/unity) for more troubleshooting tips.

* AHH! Something is wrong with Unity!

    Try resetting the settings for Unity and Compiz and relogin:

        compiz.reset
        rm -rvf ~/.cache/unity/
        rm -vf ~/.cache/unity-lens-video

    If something is still wrong, please file a bug report at either:
    
    [Github](https://github.com/chenxiaolong/Unity-for-Arch/issues)

    or

    [Launchpad](https://bugs.launchpad.net/unity-for-arch)

* The global menu does not show up for Qt 4 applications.

    Just install `appmenu-qt`
