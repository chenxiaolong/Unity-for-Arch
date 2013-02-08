#!/bin/bash
#Todo
# * add workaround for qt-ubuntu
# * add option to install without user input
packages=($(./What_can_I_update\?.py -l | grep -v qt-ubuntu))
for package in "${packages[@]}"; do
	cd "${package}"
	makepkg -fisc
	cd ..
done
