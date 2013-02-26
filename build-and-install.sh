#!/bin/bash
#Todo
# * add workaround for qt-ubuntu
# * add error detection
# * add option to start from a certain position
# * check for root if installing
while getopts nhbp:i: opt; do
	case $opt in
		n)
			NOCONFIRM=true
			;;
		h)
			echo "arguments:"
			echo "-h Shows this help file"
			echo "-n installs package without user confirmation"
			echo "-b just builds without installing"
			echo "-p [package-name] only build specific package"
			echo "-i [package-name] ignore certain package"
			exit
			;;
		b)
			NOINSTALL=true
			;;
		p)
			INSTALLPACKAGE=$OPTARG
			;;
		i)
			IGNOREPACKAGE=$OPTARG
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
	if [[ "$IGNOREPACKAGE" != "" && "$IGNOREPACKAGE" == "${package}" ]]; then
		continue
	fi
	if [[ "$INSTALLPACKAGE" != "" && "$INSTALLPACKAGE" != "${package}" ]]; then
		continue
	fi
	cd "${package}"
	rm -rf src
	if [ "$NOCONFIRM" == "true" ];then
		makepkg --nocheck -fsic --noconfirm
	elif [ "$NOINSTALL" == "true" ]; then
		makepkg --nocheck -fc
	else
		makepkg --nocheck -fsic
	fi
	cd ..
done
