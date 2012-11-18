#!/usr/bin/env python3
# Written by Xiao-Long Chen <chenxiaolong@cxl.epac.to>

# listSource -> The file which contains the list of packages.
#   This script expects every PKGBUILD to be in its own
#   directory named after the appropriate entry in the list.
#   This is usually the README file.
#
# For example, if the README file contained this:
#-------------------------------------------------------
#   This is my project blah
#   Build order:
#   1. packagea         -> description A
#   2. packageb *       -> discription B
#   3. packagec         -> discription C
#
#   Packages marked with '*' are optional
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
listSource="README"

# regexSearch -> The regular expression to search for the
#   build order lines. This regular expression should match
#   only the lines that include the package names.
# regexFormat -> Array of regular expression to format the
#   build order into a list of package names. This array of
#   regular expressions should format the format the line by
#   removing unneeded parts from the line.
#
# For example, the regular expression for finding the build
#   order lines could be:
#-------------------------------------------------------
# """^[0-9]+\..*->"""
#-------------------------------------------------------
# The regular expression for formatting the list could be:
#-------------------------------------------------------
# ["""^[0-9]+\. +""", """[ *]*[ \t]+->.*$\n"""]
#-------------------------------------------------------
# Breakdown of the regular expression for searching:
#   ^     = Beginning of line.
#   [0-9] = Characters from 0 to 9.
#   +     = One of more of the previous expression, so in
#           English, "1 or more [0-9]'s" or "1 or more digits.
#   \.    = The period character. The backslash is needed
#           since a period has a special regular expression
#           meaning.
#   .     = Any character.
#   *     = Zero or more of the previous expression. So, "0 or
#           or more of any character."
#         = Umm, well, a space character.
#   +     = Same as before: one or more of the previous expr.
#           So, "1 or more spaces."
#   .     = Any character.
#   *     = Zero or more of any character.
#   ->    = The literal '->' text.
#
# Any line that contained all of the above would be matched.
# The result after using this search regex would be:
#-------------------------------------------------------
#   1. packagea         -> description A
#   2. packageb *       -> discription B
#   3. packagec         -> discription C
#-------------------------------------------------------
#
# Breakdown of the first formatting regular expression:
#   ^     = Beginning of line
#   [0-9] = Characters from 0 to 9 (ie. a digit).
#   +     = One or more digits.
#   \.    = A literal period.
#         = A literal space.
#   +     = One or more spaces.
#
# Any text that contains all of the above will be removed.
# The result would be:
#-------------------------------------------------------
#   packagea         -> description A
#   packageb *       -> discription B
#   packagec         -> discription C
#-------------------------------------------------------
#
# Breakdown of the second formatting regular expression:
#   [ *]  = One of the characters inside the []. In this
#           case, a space or an asterisk will be matched.
#   *     = Zero of more of the previous expression. In
#           this case, "0 or more of any combination of
#           spaces and asterisks."
#   [ \t] = A space or a tab character.
#   +     = One or more of any combination of tabs and
#           spaces.
#   ->    = The literal '->' text.
#   .     = Any character.
#   *     = Zero or more of any character.
#   $     = End of line.
#   \n    = Newline character.
#
# Any text that contains all of the above will be removed.
# The final result would be:
#-------------------------------------------------------
#   packagea
#   packageb
#   packagec
#-------------------------------------------------------

# The regular expressions should be quoted with 3 double
# quotation marks ("""). This prevents Python from evaluating
# the text (such as the newline '\n').
regexSearch="""^[0-9]+:.*->"""
regexFormat=["""^[0-9]+: +""", """[ *]*[ \t]+->.*$\n"""]

############################################################
# Unless you understand Python 3, please do not edit below #
############################################################

import sys

scriptVersion = "Wed, 07 Dec 2011 19:41:55 -0500"
show = []
valid = ("pkgname", "pkgver", "pkgbase", "instver")
packages = []
pkginfo = []

# Use a array of nodes to represent the package information. There will be a 'package' node
#   and a 'subpackage node'
#
# The 'package' node can be considered as a group of 'subpackage' nodes or a parent. It represents
#   a PKGBUILD/pkgbase. The 'subpackage' node represents the pkgname variable in the PKGBUILD and
#   contains fields for the PKGBUILD version and the installed version (if installed).
#
# Diagram: (Single package):
#
# |------------|    |---------------|
# |  PKGBUILD  |    |   packagea    |
# |------------| -> |---------------|
# | [packagea] |    | pkgver=1.0-1  |
# |            |    | instver=0.9-2 |
# |            |    | upgrade=True  |
#
#-------------------------------------------------------
# Diagram: (Split package):
# |------------|    |----------------|    |----------------|    |----------------|
# |  PKGBUILD  |    |    packageb    |    |    libpkgb     |    |    daemonb     |
# |------------| -> |----------------| -> |----------------| -> |----------------|
# | [packageb] |    | pkgver=2.0b-1  |    | pkgver=2.0b-1  |    | pkgver=2.0b-1  |
# | [libpkgb]  |    | instver=1.97-5 |    | instver=2.0b-1 |    | instver=1.97-5 |
# | [daemonb]  |    | upgrade=True   |    | upgrade=False  |    | upgrade=True   |

class subpackage:
  def __init__(self, pkgname):
    self._pkgname = pkgname
    self._pkgver = ""
    self._instver = ""
    self._upgrade = False

  def __str__(self):
    return(self._pkgname)

  def get_pkgname(self):
    return(self._pkgname)

  def get_pkgver(self):
    return(self._pkgver)

  def get_instver(self):
    return(self._instver)

  def get_upgrade(self):
    return(self._upgrade)

  def set_pkgver(self, ver):
    self._pkgver = ver

  def set_instver(self, ver):
    self._instver = ver

  def set_upgrade(self, upgrade):
    self._upgrade = upgrade

class pkgbuild:
  def __init__(self, pkgbase):
    self._pkgbase = pkgbase
    self._subpackages = []

  def __str__(self):
    return(self._pkgbase)

  def append(self, subpackage):
    self._subpackages.append(subpackage)

  def get(self):
    return(self._subpackages)

  def get_all_pkgname(self): # Is this needed?
    temp = []
    for i in self._subpackages:
      temp.append(i.get_pkgname())
    return(temp)

  def get_pkgbase(self):
    return(self._pkgbase)

  def find_package(self, pkgname):
    for i in self._subpackages:
      if i.get_pkgname() == pkgname:
        return(i)
      else:
        return(None)

def parseArgs():
  import argparse
  import textwrap

  # Allow changing of global variables
  global show

  # Parse arguments from command line
  argParser = argparse.ArgumentParser()
  argParser.formatter_class = argparse.RawDescriptionHelpFormatter
  argParser.description = textwrap.dedent("""
  Arch Linux package update checker script for a group of PKGBUILDs
  ------------------------------------------------------------------
    Package list file: """ + listSource + """
    Package list search regex: """ + regexSearch + """
    Package list formatting regex: ['""" + """', '""".join(regexFormat) + """']
  """)
  argParser.epilog = "Blah, Blah, Blah. No epilog yet..."

  # Options
  argParser.add_argument("-c", "--nocolor",
                         help="Disable colorized output",
                         action='store_const',
                         const="!color",
                         dest="color",
                         default="color")
  argParser.add_argument("-f", "--noformat",
                         help="Disable formatting of output",
                         action='store_const',
                         const="!formatting",
                         dest="formatting",
                         default="formatting")

  # Show and list are mutually exclusive
  showGroup = argParser.add_mutually_exclusive_group()
  showGroup.add_argument("-s", "--show",
                         help="Comma separated list of information to show. Valid options: pkgname, pkgver, instver",
                         action='store',
                         nargs='+',
                         default=["pkgname", "pkgver", "instver"])
  showGroup.add_argument("-d", "--pkgdir",
                         help="Only show package directory names. Useful for scripts that need to get a list of upgrades and enter the appropriate PKGBUILD directory.",
                         action='store_const',
                         const='pkgdir',
                         default='!pkgdir')
  showGroup.add_argument("-l", "--list",
                         help="Print package list from " + listSource + " and quit",
                         action='store_const',
                         const="list",
                         default="!list")

  #argParser.add_argument("-p", "--progress",
  #                       help="Display progress",
  #                       action='store_const',
  #                       const="progress",
  #                       default="!progress")
  argParser.add_argument("-v", "--version",
                         help="Show script version",
                         action='version',
                         version="Version: " + scriptVersion)
  args = argParser.parse_args()

  # If you user specified what to show, update the global variable
  invalid = []
  for item in args.show:
    # Split the comma delimited list
    itemList = item.split(',')
    for item2 in itemList:
      # Add item to global 'show'
      if item2 in valid:
        show.append(item2)
      else:
        invalid.append(item2)
  if invalid:
    print("Invalid options for -s/--show:", invalid)
    sys.exit(1)

  # Add the rest of the options to global 'show'
  show.append(args.pkgdir)
  show.append(args.list)
  show.append(args.color)
  show.append(args.formatting)
  #show.append(args.progress)

def parseSource():
  import fileinput
  import re

  global packages

  matched = []

  # Compiled regex object will be faster
  regexSearchCompiled = re.compile(regexSearch)
  regexFormatCompiled = []

  for i in regexFormat:
    regexFormatCompiled.append(re.compile(i))

  # Search file with search regex
  with fileinput.input(files=(listSource), mode='r') as f:
    for line in f:
      match = re.search(regexSearchCompiled, line)
      if match:
        matched.append(line)

  for i in matched:
    temp = i
    for j in regexFormatCompiled:
      temp = re.split(j, temp)
      temp = "".join(temp)
    packages.append(temp)

def parsePkgbuild(package):
  import subprocess

  global pkginfo

  # Create data structure to store package info
  temp = pkgbuild(package)

  # Skip checks in PKGBUILDs
  envUpdate = {'UPDATE_SCRIPT' : 'true'}

  # Get information from PKGBUILD
  process = subprocess.Popen(
    ['/bin/bash', '-c', 'source ./PKGBUILD && echo "${pkgname[@]}" && echo "${pkgver}-${pkgrel}"'],
    stdout=subprocess.PIPE,
    cwd=package,
    env=envUpdate,
    universal_newlines=True
  )

  # We only care about the stdout
  output = process.communicate()[0].split('\n')

  # Create subpackages
  for pkgname in output[0].split():
    temp2 = subpackage(pkgname)
    temp2.set_pkgver(output[1])
    temp.append(temp2)

  pkginfo.append(temp)

def getInstVers():
  import os
  import subprocess

  # Set environment language to C to make parsing of output easier
  envLang = {'LANG' : 'C'}

  # Get a list of all packages
  allPackages = []
  allPkgnames = []
  for i in pkginfo:
    tempSubpkg = i.get()
    # Need to use extend so Python doesn't create a list of lists
    allPackages.extend(tempSubpkg)
    for j in tempSubpkg:
      # Get package names to send to pacman
      allPkgnames.append(j.get_pkgname())

  # Run pacman
  process = subprocess.Popen(
    ["pacman", "-Q"] + allPkgnames,
    stderr=subprocess.PIPE,
    stdout=subprocess.PIPE,
    env=envLang,
    universal_newlines=True
  )

  # The fact that error messages are sent to stderr makes splitting the installed and not installed packages easy
  stdout, stderr = process.communicate()

  # Split stdout to get the installed versions
  installed = stdout.split('\n')

  # Remove last element (empty "\n" from command)
  del(installed[-1])

  # Insert the package version for installed packages
  counter = 0
  while installed:
    # The output is in the format
    #   package 1.0-1
    temp = installed[0].split()
    # Take advantage of the sorted order
    if temp[0] == allPkgnames[counter]:
      allPackages[counter].set_instver(temp[1])
      del(installed[0])
      del(allPkgnames[counter])
      del(allPackages[counter])
    else:
      counter += 1

  # Split stderr to get packages that aren't installed
  notinstalled = stderr.split('\n')
  # Remove last element (empty "\n" from command)
  del(notinstalled[-1])

  # Insert "NOTINSTALLED" for packages that aren't installed
  counter = 0

  while notinstalled:
    # pacman 4 has a new error message that shows if there's a local file with the same same as the package
    if "warning" in notinstalled[0]:
      del(notinstalled[0])
      continue

    # Error messages are in the format:
    #   error: package "blah" not found
    #   error: package 'blah' not found (in pacman 4)
    # The package name will always be in the second element of the list when splitting by a double quote
    # (single quote in pacman 4)

    # Get pacman version and compare it
    pacmanver = 4.0
    process = subprocess.Popen(
      ['vercmp','`pacman -Q pacman`',str(pacmanver)],
      stdout=subprocess.PIPE,
      universal_newlines=True
    )
    vercmp = process.communicate()[0].split('\n')[0]
    if int(vercmp) >= 0: # Returns 0 if equal to pacmanver and 1 if newer
      temp = notinstalled[0].split('\'')[1]
    else:
      temp = notinstalled[0].split('"')[1]

    # Take advantage of the sorted order
    if temp == allPkgnames[counter]:
      allPackages[counter].set_instver("NOTINSTALLED")
      del(notinstalled[0])
      del(allPkgnames[counter])
      del(allPackages[counter])
    else:
      counter += 1

def checkUpgrades():
  import subprocess
  
  for i in pkginfo:
    temp = i.get()
    for j in temp:
      if j.get_instver() != "NOTINSTALLED":
        process = subprocess.Popen(
          ['vercmp',str(j.get_pkgver()),str(j.get_instver())],
          stdout=subprocess.PIPE,
          universal_newlines=True
        )
        vercmp = process.communicate()[0].split('\n')[0]

        if int(vercmp) > 0:
          # Upgrate = true
          j.set_upgrade(True)

def main():
  # Parse command line arguments
  parseArgs()

  # Parse package list source file
  parseSource()

  # If package list is requested, print the package list and quit.
  if 'list' in show:
    for i in packages:
      print(i)
    sys.exit(0)

  # Parse PKGBUILDs
  for i in packages:
    parsePkgbuild(i)

  # Get the installed version of the packages
  getInstVers()

  # Check for upgrades
  checkUpgrades()

  # At this point, all the information about the packages are gathered.
  for i in pkginfo:
    for j in i.get():
      if j.get_upgrade():
        if "pkgdir" in show:
          print("Package base        : " + i.get_pkgbase())
          print("  PKGBUILD version  : " + j.get_pkgver())
          print("  Installed version : " + j.get_instver())
          break
        else:
          print("Package name        : " + j.get_pkgname())
          print("  PKGBUILD version  : " + j.get_pkgver())
          print("  Installed version : " + j.get_instver())

### Begin program ###
if __name__ == '__main__':
  main()
