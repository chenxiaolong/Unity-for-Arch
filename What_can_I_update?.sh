#!/bin/bash
# Written by Xiao-Long Chen <chenxiaolong@cxl.epac.to>

# Set locale to C so I don't have to parse translations (although it will probably
#   still work
export LANG=C
export LC_ALL=C

# Some other variables used to format the output text

# Messages taken from yaourt
RESET="$(tput sgr0)"
BOLD="$(tput bold)"
BOLDGREEN="${BOLD}$(tput setaf 2)"
BOLDWHITE="${BOLD}$(tput setaf 7)"
BOLDPURPLE="${BOLD}$(tput setaf 5)"
BOLDRED="${BOLD}$(tput setaf 1)"
BOLDYELLOW="${BOLD}$(tput setaf 3)"

NEWPKGMSG="${BOLDGREEN}==> ${BOLDWHITE}The following packages can be updated:${RESET}"
UPTODATEMSG="${BOLDGREEN}==> ${BOLDWHITE}Everything is up to date!${RESET}"
NOTINSTMSG="${BOLDRED}==> ${BOLDWHITE}The following packages are not installed:${RESET}"

PKGLIST=$(cat README | grep "^[[:digit:]][[:digit:]]:" | sed -e 's/^..:\ \(.*[a-z0-9]\)\ .*->.*$/\1/g')
ARRAY_PKGNAME=""
ARRAY_PKGVER_PKG=""
ARRAY_PKGVER_INST=""
ARRAY_COUNTER=0
NOT_INSTALLED=""

for i in ${PKGLIST}; do
  pushd "${i}" > /dev/null

  # Source PKGBUILD since it's a bash script anyway. (And I don't want to parse it)
  source PKGBUILD

  for j in ${pkgname[@]}; do
    echo -en "\r$(tput el)${BOLD}${BOLDYELLOW}==> ${BOLDWHITE}Comparing package versions of: ${BOLDPURPLE}${j}${RESET}"

    # Current installed version
    CURRENTVER=$(pacman -Qi ${j} 2>/dev/null | grep [[:digit:]]-[[:digit:]] | sed 's/^.*:\ \(.*\)$/\1/g')

    # Which version is higher?
    HIGHERVER=$(echo -e "${CURRENTVER}\n${pkgver}-${pkgrel}" | sort | tail -n 1)

    if [[ "${pkgver}-${pkgrel}" != "${CURRENTVER}" ]] && [[ "${pkgver}-${pkgrel}" == "${HIGHERVER}" ]]; then
      ARRAY_PKGNAME[${ARRAY_COUNTER}]=${j}
      ARRAY_PKGVER_PKG[${ARRAY_COUNTER}]=${HIGHERVER}
      if [ -z "${CURRENTVER}" ]; then
        ARRAY_PKGVER_INST[${ARRAY_COUNTER}]="notinstalled"
      else
        ARRAY_PKGVER_INST[${ARRAY_COUNTER}]=${CURRENTVER}
      fi
      let ARRAY_COUNTER++
    fi
  done

  # Leave package directory
  popd > /dev/null

  unset pkgname pkgver pkgrel
done

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

  if [[ "${#ARRAY_PKGNAME[${ARRAY_COUNTER}]}" -gt ${LONGEST_PKGNAME} ]]; then
    LONGEST_PKGNAME=${#ARRAY_PKGNAME[${ARRAY_COUNTER}]}
  fi
  if [[ "${#ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}" -gt ${LONGEST_PKGVER_INST} ]]; then
    LONGEST_PKGVER_INST=${#ARRAY_PKGVER_INST[${ARRAY_COUNTER}]}
  fi
  let ARRAY_COUNTER++
done

if [ "${ARRAY_COUNTER}" -eq 0 ]; then
  echo -e "\r$(tput el)${UPTODATEMSG}"
  exit 0
else
  echo -e "\r$(tput el)${NEWPKGMSG}"
fi

ARRAY_COUNTER=0

COLUMN_OF_PKGVER_INST=0
  let "COLUMN_OF_PKGVER_INST += 6" # for "unity/"
  let "COLUMN_OF_PKGVER_INST += ${LONGEST_PKGNAME}" # length of the longest package name
  let "COLUMN_OF_PKGVER_INST += 1" # separator
COLUMN_OF_PKGVER_PKG=0
  let "COLUMN_OF_PKGVER_PKG += ${COLUMN_OF_PKGVER_INST}"
  let "COLUMN_OF_PKGVER_PKG += ${LONGEST_PKGVER_INST}" # length of the longest pkg ver
  let "COLUMN_OF_PKGVER_PKG += 1" # separator

while [ "${ARRAY_COUNTER}" != "$((${#ARRAY_PKGNAME[@]}-1))" ]; do
  if $(echo "${NOT_INSTALLED}" | tr ';' '\n' | grep "^${ARRAY_COUNTER}$" 2>/dev/null >/dev/null); then
    let ARRAY_COUNTER++
    continue
  fi

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
  let ARRAY_COUNTER++
done

LONGEST_PKGNAME=0

IFS=';' && for i in ${NOT_INSTALLED}; do
  if [[ "${#ARRAY_PKGNAME[${i}]}" -gt ${LONGEST_PKGNAME} ]]; then
    LONGEST_PKGNAME=${#ARRAY_PKGNAME[${i}]}
  fi
done

COLUMN_NOT_INST_VER=0
  let "COLUMN_NOT_INST_VER += 6"
  let "COLUMN_NOT_INST_VER += ${LONGEST_PKGNAME}"
  let "COLUMN_NOT_INST_VER += 1"

if [[ "${NOT_INSTALLED}" != ";" ]]; then
  echo -e "\n${NOTINSTMSG}"
  IFS=';' && for i in ${NOT_INSTALLED}; do
    echo -en "${BOLDPURPLE}unity/"
    echo -en "${BOLDWHITE}${ARRAY_PKGNAME[${i}]}"
    SPACES=$((${COLUMN_NOT_INST_VER}-${#ARRAY_PKGNAME[${i}]}-6))
    while [ "${SPACES}" -gt 0 ]; do
      echo -n " "
      let SPACES--
    done
    echo -en "${BOLDYELLOW}(${ARRAY_PKGVER_PKG[${i}]})"
    echo -e "${RESET}"
  done
fi
