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

NEWPKGMSG="${BOLDGREEN}==> ${BOLDWHITE}The following packages can be updated:${RESET}"

PKGLIST=$(cat README | grep "^[[:digit:]][[:digit:]]:" | sed -e 's/^..:\ \(.*[a-z]\)\ .*->.*$/\1/g')
NEWPKG=""

echo -e "\r$(tput el)${NEWPKGMSG}"
for i in ${PKGLIST}; do
  pushd "${i}" > /dev/null

  # Source PKGBUILD since it's a bash script anyway. (And I don't want to parse it)
  source PKGBUILD

  for j in ${pkgname[@]}; do
    echo -en "\r$(tput el)Comparing package versions of: ${j}"

    # Current installed version
    CURRENTVER=$(pacman -Qi ${j} | grep [[:digit:]]-[[:digit:]] | sed 's/^.*:\ \(.*\)$/\1/g')

    # Which version is higher?
    HIGHERVER=$(echo -e "${CURRENTVER}\n${pkgver}" | sort | tail -n 1)

    if [[ "${pkgver}" == "${HIGHERVER}" ]]; then
      SPACES=""
      SPACES_COLUMN="65"
      if [ -z "${CURRENTVER}" ]; then CURRENTVER="(not installed)"; fi
      SPACESCOUNT=$((${SPACES_COLUMN}-6-${#j}-${#pkgver}))
      while [ "${SPACESCOUNT}" -gt 0 ]; do
        SPACES="${SPACES} "
        let SPACESCOUNT--
      done
      echo -e "\r$(tput el)${BOLDPURPLE}unity/${BOLDWHITE}${j}${SPACES}${BOLDGREEN}${CURRENTVER}${RESET} -> ${BOLDRED}${pkgver}-${pkgrel}${RESET}"
      NEWPKG="${NEWPKG}${j}"
    fi
  done

  # Leave package directory
  popd > /dev/null

  unset pkgname pkgver pkgrel
done

echo -e "\r$(tput el)"
if [ -z "${NEWPKG}" ]; then
  echo "${BOLDGREEN}==> ${BOLDWHITE}Nothing to upgrade :)${RESET}"
fi
