#!/bin/bash
#Todo
# * add workaround for qt4-ubuntu
# * add error detection
# * check for root if installing
while getopts ednhbp:is: opt; do
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
			echo "-s [package-name] start at package"
			echo "-d only download required sources (do not build or install)"
			echo "-e stop on error "
			exit
			;;
		e)
			set -e
			echo "WARNING: Stopping on errors"
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
		s)
			NOSTART=true
			STARTPKG=$OPTARG
			;;
		d)	DOWNLOAD=true
	esac
done

#check for conflicting arguments
if [ "$NOINSTALL" == true ]; then
	if [ "$NOCONFIRM" == true ]; then
		echo "Conflicting arguments...exiting"
		exit
	fi
fi


packages=($(./What_can_I_update\?.py -l | grep -v qt4-ubuntu))
for package in "${packages[@]}"; do
	if [ "$NOSTART" == "true" ]; then
		if [ "${package}" != "$STARTPKG" ]; then
			continue
		else
			NOSTART=false
		fi

	fi

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
	elif [ "$DOWNLOAD" == "true" ]; then
		echo "Downloading ${package}..."
		makepkg -g &> /dev/null
	else
		makepkg --nocheck -fsic
	fi
	cd ..
done
