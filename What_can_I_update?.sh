#!/bin/bash
# Written by Xiao-Long Chen <chenxiaolong@cxl.epac.to>

# PKGBUILDLIST -> The file which contains the list of packages.
#   This script expects every PKGBUILD to be in its own 
#   directory named after the appropriate entry in the list. 
#   This is usually the README file.
#
# For example, if the README file contained this:
#-------------------------------------------------------
#   This is my project blah
#   Build order:
#   1. packagea -> description A
#   2. packageb -> discription B
#   3. packagec -> discription C
#-------------------------------------------------------
# Then the directory structure should be like this
#  .
#  |-- packagea
#  |   `-- PKGBUILD
#  |-- packageb
#  |   `-- PKGBUILD
#  |-- packagec
#  |   `-- PKGBUILD
#  `-- README
PKGBUILDLIST="README"

# PKGLIST -> The command to read the file above and turn it
#   into a space separated or newline separated list.
#
# For example, the command for the above README file could be:
#-------------------------------------------------------
# cat ${PKGBUILDLIST} | grep ^[[[:digit:]]]* | sed -e 's/ ->.*$//g' -e 's/^.* //g'
#-------------------------------------------------------
# Breakdown of the command:
#   cat ${PKGBUILDLIST} -> The cat command prints out a file
#   | -> This is a pipe. It sends the output of the command
#        to the left of it to the input of the command to the
#        right of it.
#   grep -> A very powerful tool designed for searching
#           through anything.
#   ^ -> Beginning of line
#   [ ]* -> Searches one or more of what's in the backets
#   [[:digit:]] -> Well, a numerical digit.
#
#   So, far the command reads the file specified above,
#   tries to match lines that have one or more digits at
#   the beginning of the line. Omitting everything after
#   the grep command would output this:
#  -----------------------------------------------------
#    1. packagea -> description A
#    2. packageb -> description B
#    3. packagec -> description C
#  -----------------------------------------------------
#   Notice how the other lines aren't shown. Okay, continuing
#   the breakdown of the command:
#
#   sed -> Another very powerful tool used to manipulate
#          text.
#   s -> The sed command for replace. It's used like this:
#        's/replace_this/with_this/g'
#   g -> The g at the end of the sed command tells it to
#        keep going even after the first modification. Ie.
#        replace every instance of 'replace_this' with
#        'with_this'.
#   .* -> Every character
#   $ -> End of line
#
#   In the first sed command 's/ ->.*$//g', sed is going
#   replace the text starting with a space and an arrow all
#   the way to the end of the line with nothing.
#
#   The second sed command will replace the text starting from
#   the beginning of the line all the way to the last space
#   (which is why the stuff after the package name needs to be
#   removed first - the space will have been after the package
#   name causing it to be removed).
#
#   The final output would be:
#  -----------------------------------------------------
#   packagea
#   packageb
#   packagec
#  -----------------------------------------------------
#   which will work perfectly with this script.
alias PKGLIST="cat README | grep '^[[:digit:]][[:digit:]]:' | sed -e 's/^..:\ \(.*[a-z0-9]\)\ .*->.*$/\1/g'"

########################################################
# Unless you understand Bash, please do not edit below #
########################################################

COLOR="true"
SHOW="UPDATES NOTINSTALLED"

#Help
showHelp() {
  echo "Arch Linux package update checker script for a group of PKGBUILDs"
  echo "  by Xiao-Long Chen"
  echo "Version: Tue, 08 Nov 2011 00:00:01 -0500"
  echo "Usage: ${0} [options]"
  echo ""
  echo "Options:"
  echo "  -c, --nocolor     Disable colorized output"
  echo "  -i, --onlynotinst Only show packages that aren't installed"
  echo "  -u, --onlyupdates Only show available updates"
  echo "  -l, --pkglist     List packages in the group of PKGBUILDs"
  echo "  -p, --pkgnameonly Only output unformatted package names"
  echo "  -v, --pkgversions Assumes -p; also outputs package versions"
  echo "  -h, --help        This help message"
}

#Argument parsing
while [ "${#}" != "0" ]; do
  case "${1}" in
    --nocolor|-c)
      COLOR="false"
      shift
      ;;
    --onlynotinst|-i)
      SHOW="NOTINSTALLED"
      shift
      ;;
    --onlyupdates|-u)
      SHOW="UPDATES"
      shift
      ;;
    --pkglist|-l)
      SHOW="PKGLIST"
      shift
      ;;
    --pkgnameonly|-p)
      SHOW="${SHOW} PKGNAME"
      shift
      ;;
    --help|-h)
      showHelp
      exit 0
      ;;
    *)
      echo "Unrecognized parameter: ${1}"
      echo ""
      showHelp
      exit 1
      ;;
  esac
done

# Set locale to C so I don't have to parse translations (although it will probably still work)
export LANG=C
export LC_ALL=C

# Some other variables used to format the output text

# Messages taken from yaourt
if [ "${COLOR}" == "true" ]; then
  RESET="$(tput sgr0)"
  BOLD="$(tput bold)"
  BOLDGREEN="${BOLD}$(tput setaf 2)"
  BOLDWHITE="${BOLD}$(tput setaf 7)"
  BOLDPURPLE="${BOLD}$(tput setaf 5)"
  BOLDRED="${BOLD}$(tput setaf 1)"
  BOLDYELLOW="${BOLD}$(tput setaf 3)"
fi
#No need for else - echo'ing an undeclared variable is allowed in bash

#Information messages
NEWPKGMSG="${BOLDGREEN}==> ${BOLDWHITE}The following packages can be updated:${RESET}"
UPTODATEMSG="${BOLDGREEN}==> ${BOLDWHITE}Everything is up to date!${RESET}"
NOTINSTMSG="${BOLDRED}==> ${BOLDWHITE}The following packages are not installed:${RESET}"

shopt -s expand_aliases
PKGLIST=$(PKGLIST)
#Print package list if needed - order is maintained automatically, so there's no need for hacks
if [ "${SHOW}" == "PKGLIST" ]; then
  echo -e "${PKGLIST}"
  exit 0
fi

#Arrays for package names, installed versions, and PKGBUILD versions
ARRAY_PKGNAME=""
ARRAY_PKGVER_PKG=""
ARRAY_PKGVER_INST=""
#Iterator for array
ARRAY_COUNTER=0
#Array for packages that aren't installed
NOT_INSTALLED=""

for i in ${PKGLIST}; do
  #Enter build directory
  pushd "${i}" > /dev/null

  # Source PKGBUILD since it's a bash script anyway. (And I don't want to parse it)
  source PKGBUILD

  #This method will work for split packages
  for j in ${pkgname[@]}; do
    #Progess display
    echo -en "\r$(tput el)${BOLD}${BOLDYELLOW}==> ${BOLDWHITE}Comparing package versions of: ${BOLDPURPLE}${j}${RESET}"

    # Current installed version
    CURRENTVER=$(pacman -Qi ${j} 2>/dev/null | grep [[:digit:]]-[[:digit:]] | sed 's/^.*:\ \(.*\)$/\1/g')

    # Which version is higher?
    HIGHERVER=$(echo -e "${CURRENTVER}\n${pkgver}-${pkgrel}" | sort | tail -n 1)

    #if PKGBUILD version does not equal current version and the PKGBUILD is the higher version
    if [[ "${pkgver}-${pkgrel}" != "${CURRENTVER}" ]] && [[ "${pkgver}-${pkgrel}" == "${HIGHERVER}" ]]; then
      #Add packages to arrays
      ARRAY_PKGNAME[${ARRAY_COUNTER}]=${j}
      ARRAY_PKGVER_PKG[${ARRAY_COUNTER}]=${HIGHERVER}
      if [ -z "${CURRENTVER}" ]; then
        #If the current version is empty then it's not installed
        ARRAY_PKGVER_INST[${ARRAY_COUNTER}]="notinstalled"
      else
        ARRAY_PKGVER_INST[${ARRAY_COUNTER}]=${CURRENTVER}
      fi
      let ARRAY_COUNTER++
    fi
  done

  # Leave package directory
  popd > /dev/null

  unset pkgname pkgver pkgrel #Some PKGBUILD's aren't written perfectly...
done

#Reset iterator
ARRAY_COUNTER=0

LONGEST_PKGNAME=0
LONGEST_PKGVER_INST=0

while [ "${ARRAY_COUNTER}" != "$((${#ARRAY_PKGNAME[@]}-1))" ]; do
  # Do not installed packages that aren't installed in the list
  if [[ "${ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}" == "notinstalled" ]]; then
    NOT_INSTALLED="${NOT_INSTALLED}${ARRAY_COUNTER};"
    let ARRAY_COUNTER++
    continue
  fi

  #Don't do unnecessary calculations if they are not needed
  if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
    #Find longest package names and versions for formatting
    if [[ "${#ARRAY_PKGNAME[${ARRAY_COUNTER}]}" -gt ${LONGEST_PKGNAME} ]]; then
      LONGEST_PKGNAME=${#ARRAY_PKGNAME[${ARRAY_COUNTER}]}
    fi
    if [[ "${#ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}" -gt ${LONGEST_PKGVER_INST} ]]; then
      LONGEST_PKGVER_INST=${#ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}
    fi
  fi
  let ARRAY_COUNTER++
done

#Clear line
echo -en "\r$(tput el)"

#Show updates
if [ "${SHOW/UPDATES/}" != "${SHOW}" ]; then
  #Don't show if "--pkgnameonly" is chosen
  if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
    #number of elements in semicolon delimited array
    if [ "${ARRAY_COUNTER}" == "$(($(echo ${NOT_INSTALLED[@]} | tr ';' '\n' | wc -l)-1))" ]; then
      #Up to date
      echo -e "${UPTODATEMSG}"
    else
      #Updates are available
      echo -e "${NEWPKGMSG}"
    fi
  fi

  #Reset iterator
  ARRAY_COUNTER=0

  #Formatting - needed to calulate the number of spaces needed later
  if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
    COLUMN_OF_PKGVER_INST=0
      let "COLUMN_OF_PKGVER_INST += 6" # for "unity/"
      let "COLUMN_OF_PKGVER_INST += ${LONGEST_PKGNAME}" # length of the longest package name
      let "COLUMN_OF_PKGVER_INST += 1" # separator
    COLUMN_OF_PKGVER_PKG=0
      let "COLUMN_OF_PKGVER_PKG += ${COLUMN_OF_PKGVER_INST}"
      let "COLUMN_OF_PKGVER_PKG += ${LONGEST_PKGVER_INST}" # length of the longest pkg ver
      let "COLUMN_OF_PKGVER_PKG += 1" # separator
  fi

  while [ "${ARRAY_COUNTER}" != "$((${#ARRAY_PKGNAME[@]}-1))" ]; do
    #If package is not installed, skip it for now
    if $(echo "${NOT_INSTALLED}" | tr ';' '\n' | grep "^${ARRAY_COUNTER}$" 2>/dev/null >/dev/null); then
      let ARRAY_COUNTER++
      continue
    fi

    #Show formatted package name and versions
    if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
      echo -en "${BOLDPURPLE}unity/"
      echo -en "${BOLDWHITE}${ARRAY_PKGNAME[${ARRAY_COUNTER}]}"
      # Column of the package version - the package name length - the length of "unity/"
      SPACES=$((${COLUMN_OF_PKGVER_INST}-${#ARRAY_PKGNAME[${ARRAY_COUNTER}]}-6))
      while [ "${SPACES}" -gt 0 ]; do
        echo -n " "
        let SPACES--
      done
      echo -en "${BOLDGREEN}${ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}"
      # Column of the new package version - the column of the installed package version
      #   - the installed package version length
      SPACES=$((${COLUMN_OF_PKGVER_PKG}-${COLUMN_OF_PKGVER_INST}-${#ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}))
      while [ "${SPACES}" -gt 0 ]; do
        echo -n " "
        let SPACES--
      done
      echo -en "${RESET}-> "
      echo -en "${BOLDRED}${ARRAY_PKGVER_PKG[${ARRAY_COUNTER}]}"
      echo -e "${RESET}"
    else
      #Or just show the package name
      echo "${ARRAY_PKGNAME[${ARRAY_COUNTER}]}"
    fi
    let ARRAY_COUNTER++
  done
fi

LONGEST_PKGNAME=0

#Show separator if only package names are requested
if [ "${SHOW/PKGNAME/}" != "${SHOW}" ]; then
  echo ';;'
fi

#Show not installed packages
if [ "${SHOW/NOTINSTALLED/}" != "${SHOW}" ]; then
  #Find longest package name in the array of not installed packages
  if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
    IFS=';' && for i in ${NOT_INSTALLED}; do
      if [[ "${#ARRAY_PKGNAME[${i}]}" -gt ${LONGEST_PKGNAME} ]]; then
        LONGEST_PKGNAME=${#ARRAY_PKGNAME[${i}]}
      fi
    done

  COLUMN_NOT_INST_VER=0
    let "COLUMN_NOT_INST_VER += 6"
    let "COLUMN_NOT_INST_VER += ${LONGEST_PKGNAME}"
    let "COLUMN_NOT_INST_VER += 1"
  fi

  if [[ "${NOT_INSTALLED}" != ";" ]]; then
    #Show message
    if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
      [ "${SHOW/UPDATES/}" != "${SHOW}" ] && echo ""
      echo -e "${NOTINSTMSG}"
    fi
    IFS=';' && for i in ${NOT_INSTALLED}; do
      #Show formatted package name and version
      if [ "${SHOW/PKGNAME/}" == "${SHOW}" ]; then
        echo -en "${BOLDPURPLE}unity/"
        echo -en "${BOLDWHITE}${ARRAY_PKGNAME[${i}]}"
        SPACES=$((${COLUMN_NOT_INST_VER}-${#ARRAY_PKGNAME[${i}]}-6))
        while [ "${SPACES}" -gt 0 ]; do
          echo -n " "
          let SPACES--
        done
        echo -en "${BOLDYELLOW}(${ARRAY_PKGVER_PKG[${i}]})"
        echo -e "${RESET}"
      else
        #Or just show package name
        echo "${ARRAY_PKGNAME[${i}]}"
      fi
    done
  fi
fi
