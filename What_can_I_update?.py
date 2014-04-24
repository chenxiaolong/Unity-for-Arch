#!/usr/bin/env python3
# Written by Xiao-Long Chen <chenxiaolong@cxl.epac.to>

import argparse
import os
import re
import subprocess
import sys
import textwrap

try:
    import pyalpm
except:
    print('Please install the pyalpm package')
    sys.exit(1)

from pycman import config
from pycman import pkginfo

list_source = 'README.md'
script_version = 'Thu, 24 Apr 2014 13:07:55 -0400'
topdir = os.path.dirname(os.path.realpath(__file__))

handle = config.init_with_config('/etc/pacman.conf')
db = handle.get_localdb()
packages = list()

show_valid = ['pkgver', 'instver']
show = []
show_list = False
show_pkgbase = False
show_pkgdir = False


class subpackage:
    def __init__(self, pkgname, pkgver):
        self.pkgname = pkgname
        self.pkgver = pkgver
        self.instver = None
        self.upgrade = False

        self.instver = self.get_installed_version()
        if self.instver:
            self.upgrade = self.need_upgrade()
        else:
            self.upgrade = True

    def __str__(self):
        return(self.pkgname)

    def get_installed_version(self):
        pkg = db.get_pkg(self.pkgname)
        if pkg:
            return pkg.version
        else:
            return None

    def need_upgrade(self):
        vcmp = pyalpm.vercmp(self.pkgver, self.instver)
        return vcmp > 0


class pkgbuild:
    def __init__(self, pkgbase):
        self.pkgbase = pkgbase
        self.rdesc = None  # Description from README.md
        self.subpackages = []

        # Don't do anything if we're listing packages
        if show_list:
            return

        pkgnames = self.get_var_from_pkgbuild('pkgname[@]').split(' ')
        pkgver = self.get_var_from_pkgbuild('pkgver')
        pkgrel = self.get_var_from_pkgbuild('pkgrel')
        epoch = self.get_var_from_pkgbuild('epoch')
        if epoch:
            version = '%s:%s-%s' % (epoch, pkgver, pkgrel)
        else:
            version = '%s-%s' % (pkgver, pkgrel)

        for pkgname in pkgnames:
            pkg = subpackage(pkgname, version)
            self.subpackages.append(pkg)

    def __str__(self):
        return(self._pkgbase)

    def append(self, subpackage):
        self.subpackages.append(subpackage)

    def find_package(self, pkgname):
        for i in self._subpackages:
            if i.pkgname == pkgname:
                return(i)
            else:
                return(None)

    def get_var_from_pkgbuild(self, var):
        directory = os.path.join(topdir, self.pkgbase)

        process = subprocess.Popen(
            ['bash', '-c', 'source ./PKGBUILD && echo ${%s}' % var],
            stdout=subprocess.PIPE,
            cwd=directory,
            universal_newlines=True
        )
        output = process.communicate()[0].split('\n')
        if output:
            return output[0]
        else:
            return None


def parse_arguments():
    global show, show_list, show_pkgbase, show_pkgdir

    # Parse arguments from command line
    argParser = argparse.ArgumentParser()
    argParser.formatter_class = argparse.RawDescriptionHelpFormatter
    argParser.description = textwrap.dedent('''
    Arch Linux package update checker script for a group of PKGBUILDs
    ------------------------------------------------------------------
      Package list file: ''' + list_source + '''
    ''')

    # Show and list are mutually exclusive
    showGroup = argParser.add_mutually_exclusive_group()
    showGroup.add_argument('-s', '--show',
                           help='List of information to show. Valid options: pkgver, instver',
                           action='store',
                           nargs='+',
                           default=['pkgver', 'instver'])
    showGroup.add_argument('-b', '--pkgbase',
                           help='Show base package name instead of each subpackage\'s name',
                           action='store_true')
    showGroup.add_argument('-d', '--pkgdir',
                           help='Only show package directory names of upgradable packages',
                           action='store_true')
    showGroup.add_argument('-l', '--list',
                           help='Print package list from ' + list_source + ' and quit',
                           action='store_true')
    argParser.add_argument('-v', '--version',
                           help='Show script version',
                           action='version',
                           version='Version: ' + script_version)
    args = argParser.parse_args()

    invalid = []
    for arg in args.show:
        showopts = arg.split(',')
        for opt in showopts:
            if opt in show_valid:
                show.append(opt)
            else:
                invalid.append(opt)

    if invalid:
        print('Invalid options for -s/--show:', invalid)
        sys.exit(1)

    if args.list:
        show_list = True

    if args.pkgbase:
        show_pkgbase = True

    if args.pkgdir:
        show_pkgdir = True


def parse_source():
    global packages

    r = re.compile(r'^\s*\|\s*([^\|]+?)\s*\|\s*([^\|]+?)\s*\|')

    # Look for markdown table

    ready = False
    with open(list_source, 'r') as f:
        for line in f:
            if not line:
                continue

            m = re.search(r, line)
            if m:
                name = m.group(1)
                desc = m.group(2)

                if name.startswith('-'):
                    ready = True
                    continue

                if ready:
                    pkg = pkgbuild(name)
                    pkg.rdesc = desc
                    packages.append(pkg)

            else:
                ready = False


def main():
    # Parse command line arguments
    parse_arguments()

    # Parse package list source file
    parse_source()

    # If package list is requested, print the package list and quit.
    if show_list:
        for package in packages:
            print(package.pkgbase)
        sys.exit(0)

    # At this point, all the information about the packages are gathered.
    for package in packages:
        for subpackage in package.subpackages:
            if subpackage.upgrade:
                if show_pkgdir:
                    print(package.pkgbase)
                    break

                elif show_pkgbase:
                    print('Package base        : ' + package.pkgbase)
                    if 'pkgver' in show:
                        print('  PKGBUILD version  : ' + subpackage.pkgver)
                    if 'instver' in show:
                        msg = '  Installed version : %s'
                        if subpackage.instver:
                            print(msg % subpackage.instver)
                        else:
                            print(msg % '(not installed)')
                    print('')
                    break

                else:
                    print('Package name        : ' + subpackage.pkgname)
                    if 'pkgver' in show:
                        print('  PKGBUILD version  : ' + subpackage.pkgver)
                    if 'instver' in show:
                        msg = '  Installed version : %s'
                        if subpackage.instver:
                            print(msg % subpackage.instver)
                        else:
                            print(msg % '(not installed)')
                    print('')

if __name__ == '__main__':
    main()
