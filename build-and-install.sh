#!/bin/bash
#Todo
# * add workaround for qt-ubuntu
# * add error detection
# * add option to only build a certain package, ignore certain packages, or start from a certain position
# * check for root if installing
while getopts nhb opt; do
	case $opt in
		n)
			NOCONFIRM=true
			;; 
		h)
			echo "arguments:"
			echo "-h Shows this help file"
			echo "-n installs package without user confirmation"
			echo "-b just builds without installing"
			exit
			;;
		b)
			NOINSTALL=true
			;;
	esac
done

#check for conflicting arguments
if [ "$NOINSTALL" == true ]; then
	if [ "$NOCONFIRM" == true ]; then
		echo "Conflicting arguments...exiting"
		exit
	fi
fi


packages=($(./What_can_I_update\?.py -l | grep -v qt-ubuntu))
for package in "${packages[@]}"; do
	cd "${package}"
	rm -rf src
	if [ "$NOCONFIRM" == "true" ];then
		makepkg -fsic --noconfirm
	elif [ "$NOINSTALL" == "true" ]; then
			makepkg -fc
	else
		makepkg -fsic
	fi
	cd ..
done
