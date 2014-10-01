#!/usr/bin/env python3

from collections import OrderedDict
import bz2
import os
import re
import subprocess
import sys
import urllib.request


def run_command(command,
                stdin_data=None,
                cwd=None,
                shell=False,
                universal_newlines=True):
    try:
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            shell=shell,
            universal_newlines=universal_newlines
        )
        output, error = process.communicate(input=stdin_data)

        exit_code = process.returncode

        return (exit_code, output, error)

    except:
        raise Exception('Failed to run command: "%s"' % ' '.join(command))


def unquote(string):
    if len(string) >= 3 and string.startswith('"') and \
            string.endswith('"') and not string.endswith(r'\"'):
        return string[1:-1]
    else:
        return string


def parse_params(params):
    strpairs = list()
    inquote = False
    curpair = str()
    prevchar = ''

    for c in params:
        if c == '"' and prevchar != '\\':
            inquote = not inquote
        elif c == ',' and not inquote:
            strpairs.append(curpair.strip())
            curpair = str()
            prevchar = ''
            continue

        prevchar = c
        curpair += c

    if curpair:
        strpairs.append(curpair.strip())

    pairs = dict()

    for pair in strpairs:
        partition = pair.partition('=')
        key = unquote(partition[0].strip())
        value = unquote(partition[2].strip())

        pairs[key] = value

    return pairs


def get_bash_var(var):
    if not var:
        raise Exception('No variable(s) specified')

    if type(var) == list:
        formatted = str()

        for v in var:
            formatted += '%s=${%s} ' % (v, v)

        exit_code, output, error = run_command(
            ['bash', '-c', 'source %s && echo %s' % (filename, formatted)]
        )

        if not output or not output.partition('\n')[0]:
            return None

        return output.partition('\n')[0].split(' ')

    else:
        exit_code, output, error = run_command(
            ['bash', '-c', 'source %s && echo ${%s}' % (filename, var)]
        )

        if not output or not output.partition('\n')[0]:
            return None

        return output.partition('\n')[0]


def replace_bash_vars(formatstr):
    split = re.split(r'(\${.+?})', formatstr)

    result = str()

    for piece in split:
        if not piece.startswith('$'):
            result += piece
        else:
            var = re.search(r'\${(.+?)}', piece)
            if not var:
                raise Exception('Failed to parse "%s"' % piece)

            value = get_bash_var(var.group(1))
            if not value:
                raise Exception('Failed to get ${%s} from %s' % (var, filename))

            result += value

    return result


def get_pkgbuild_ver(params):
    for param in params:
        value = params[param]

        if param == 'format':
            return replace_bash_vars(value)

        elif param == 'auto':
            pkgver = get_bash_var('pkgver')
            actualver = get_bash_var('_actual_ver')
            extraver = get_bash_var('_extra_ver')
            ubuntuver = get_bash_var('_ubuntu_ver')
            ubunturel = get_bash_var('_ubuntu_rel')
            ppaver = get_bash_var('_ppa_ver')
            pparel = get_bash_var('_ppa_rel')

            version = str()

            if actualver and extraver:
                version += actualver + extraver
            else:
                version += pkgver

            if ubuntuver:
                version += ' Ubuntu ' + ubuntuver
            elif ppaver:
                version += ' PPA ' + ppaver

            if ubunturel:
                version += ' ' + ubunturel
            elif pparel:
                version += ' ' + pparel

            return version

        else:
            raise Exception('Invalid parameter "%s"' % param)


def get_ubuntu_ver(params):
    repo = params['repo']
    name = replace_bash_vars(params['name'])
    native = 'native' in params

    url = 'https://launchpad.net/ubuntu/%s/+source/%s' % (repo, name)

    if native:
        regex = r'^.*current\ release\ \((.*)\).*$'
    else:
        regex = r'^.*current\ release\ \((.*)-(.*)\).*$'

    with urllib.request.urlopen(url) as f:
        for line in f:
            match = re.search(regex, line.decode('UTF-8'))
            if not match:
                continue

            if native:
                return match.group(1)
            else:
                return ' '.join(match.groups())

    return None


def get_archlinux_ver(params):
    repo = params['repo']
    name = replace_bash_vars(params['name'])
    arch = params['arch']

    url = 'https://www.archlinux.org/packages/%s/%s/%s/' % (repo, arch, name)
    regex = r'^.*%s\ (.*)-(.*)\ .+$' % re.escape(name)

    with urllib.request.urlopen(url) as f:
        for line in f:
            if not '<title>' in line.decode('UTF-8'):
                continue

            match = re.search(regex, line.decode('UTF-8'))
            if not match:
                continue

            return ' '.join(match.groups())

    return None


def get_gnome_ver(params):
    name = replace_bash_vars(params['name'])
    majorver = params['majorver']

    url = 'http://ftp.gnome.org/pub/GNOME/sources/%s/%s/' % (name, majorver)
    regex = r'>LATEST-IS-(.*)<'

    # Sometimes, there are multiple "LATEST-IS-..." files
    latest = None

    with urllib.request.urlopen(url) as f:
        for line in f:
            match = re.search(regex, line.decode('UTF-8'))
            if not match:
                continue

            latest = match.group(1)

    return latest


def get_launchpad_ver(params):
    name = replace_bash_vars(params['name'])

    if 'tarname' in params:
        tarname = replace_bash_vars(params['tarname'])
    else:
        tarname = name

    url = 'https://launchpad.net/%s/+download' % name
    regex = r'>%s[-_]+(.+?)\.tar' % re.escape(tarname)

    with urllib.request.urlopen(url) as f:
        for line in f:
            match = re.search(regex, line.decode('UTF-8'))
            if not match:
                continue

            return match.group(1)

    return None


def get_ppa_ver(params):
    name = replace_bash_vars(params['name'])
    ppaurl = params['url']
    native = 'native' in params
    norel = 'norel' in params

    ppaurl = ppaurl.lstrip('ppa:')
    url = 'http://ppa.launchpad.net/%s/ubuntu/pool/main/%s/%s/?C=M;O=A' % \
        (ppaurl, name[0:1], name)

    if native:
        regex = r'>%s_(.+?)-(.+?)\.tar\.[a-z\.]+<' % re.escape(name)
    elif norel:
        regex = r'>%s_(.+?)\.(debian|diff)\.[a-z\.]+<' % re.escape(name)
    else:
        regex = r'>%s_(.+?)-(.+?)\.(?:debian|diff)\.[a-z\.]+<' % re.escape(name)

    latest = None

    with urllib.request.urlopen(url) as f:
        for line in f:
            match = re.search(regex, line.decode('UTF-8'))
            if not match:
                continue

            if native:
                latest = match.group(1) + ' ' + match.group(2)
            elif norel:
                latest = match.group(1)
            else:
                latest = ' '.join(match.groups())

    return latest


def get_ubuntudb_ver(params):
    pkgprefix = params['pkgprefix']
    verprefix = params['verprefix']

    relprefix = None
    if 'relprefix' in params:
        relprefix = params['relprefix']

    ignorerel = 'ignorerel' in params

    repo = params['repo']

    skip = list()
    if 'skip' in params:
        for pkg in params['skip'].split(';'):
            skip.append(pkgprefix + pkg.strip())

    onlyver = None
    if 'onlyver' in params:
        onlyver = params['onlyver']

    url = 'http://archive.ubuntu.com/ubuntu/dists/%s/main/source/Sources.bz2' % repo

    packages = list()
    repovers = list()
    pkgbuildvers = list()

    with urllib.request.urlopen(url) as f:
        with bz2.open(f, 'r') as b:
            curpkg = None

            for line in b:
                linestr = line.decode('UTF-8')

                if linestr.startswith('Package: '):
                    if linestr.startswith('Package: ' + pkgprefix):
                        curpkg = linestr[9:-1]
                        if curpkg in skip:
                            curpkg = None

                elif curpkg and linestr.startswith('Version: '):
                    if ignorerel:
                        repover = linestr[9:-1].partition('-')[0]
                    else:
                        repover = linestr[9:-1].replace('-', ' ')

                    # Strip epoch
                    if ':' in repover:
                        repover = repover.partition(':')[2]

                    if onlyver and not re.search(onlyver, repover):
                        curpkg = None
                        continue

                    packages.append(curpkg)
                    repovers.append(repover)

                    curpkg = None

    shortnames = [p[len(pkgprefix):].replace('-', '_') for p in packages]

    vers = get_bash_var([(verprefix + name) for name in shortnames])
    if relprefix:
        rels = get_bash_var([(relprefix + name) for name in shortnames])

    for i in range(0, len(packages)):
        ver = vers[i].partition('=')[2]

        if relprefix:
            rel = rels[i].partition('=')[2]
            pkgbuildvers.append('%s %s' % (ver, rel))
        else:
            pkgbuildvers.append(ver)

    newpackages = list()
    newrepovers = list()
    newpkgbuildvers = list()

    for i in range(0, len(packages)):
        if repovers[i] == pkgbuildvers[i]:
            continue

        newpackages.append(packages[i])
        newrepovers.append(repovers[i])
        newpkgbuildvers.append(pkgbuildvers[i])

    return newpackages, newrepovers, newpkgbuildvers


def parse_pkgbuild_meta():
    vcinfos = dict()

    with open(filename, 'r') as f:
        for line in f:
            if not line.startswith('#'):
                continue
            else:
                vcline = re.search(r'^#\s*vercheck-(.+?)\s*:\s*(.+)$', line)
                if not vcline:
                    continue
                else:
                    source = vcline.group(1).strip()
                    params = vcline.group(2).strip()
                    vcinfos[source] = params

    return vcinfos


def print_versions(vcinfos):
    # Special functions for split packages with different versions in each
    # split package
    if 'ubuntudb' in vcinfos:
        params = parse_params(vcinfos['ubuntudb'])
        packages, repovers, pkgbuildvers = get_ubuntudb_ver(params)

        for i in range(0, len(packages)):
            print('Package:          ' + packages[i])
            print('PKGBUILD version: ' + pkgbuildvers[i])
            print('Ubuntu version:   ' + repovers[i])
            print()

        return

    versions = dict()
    names = dict()

    names['pkgbuild'] = 'PKGBUILD version'
    names['ubuntu'] = 'Ubuntu version'
    names['archlinux'] = 'Arch Linux version'
    names['gnome'] = 'GNOME version'
    names['launchpad'] = 'Launchpad version'
    names['ppa'] = 'PPA version'

    maxlen = max(len(names[s]) for s in vcinfos) + 1
    vcinfos = OrderedDict(sorted(vcinfos.items(), key=lambda t: t[0]))

    if 'pkgbuild' in vcinfos:
        params = parse_params(vcinfos['pkgbuild'])
        version = get_pkgbuild_ver(params)
        print('%s %s' % ((names['pkgbuild'] + ':').ljust(maxlen), version))
        del vcinfos['pkgbuild']

    if 'ubuntu' in vcinfos:
        params = parse_params(vcinfos['ubuntu'])
        version = get_ubuntu_ver(params)
        print('%s %s' % ((names['ubuntu'] + ':').ljust(maxlen), version))
        del vcinfos['ubuntu']


    for source in vcinfos:
        params = parse_params(vcinfos[source])

        if source == 'archlinux':
            version = get_archlinux_ver(params)
        elif source == 'gnome':
            version = get_gnome_ver(params)
        elif source == 'launchpad':
            version = get_launchpad_ver(params)
        elif source == 'ppa':
            version = get_ppa_ver(params)
        else:
            raise Exception('Unknown source "%s"' % source)
            versions[source] = 'blah'

        print('%s %s' % ((names[source] + ':').ljust(maxlen), version))


def find_pkgbuild():
    # Check if this script is symlinked to a directory containing a PKGBUILD
    directory = os.path.dirname(os.path.realpath(__file__))
    path = os.path.join(directory, 'PKGBUILD')
    if os.path.exists(path):
        return path

    # Check if a directory was passed
    if len(sys.argv) > 1:
        directory = sys.argv[1]
        path = os.path.join(directory, 'PKGBUILD')
        if os.path.exists(path):
            return path

    # Check if we're in a package's directory
    path = os.path.join(os.getcwd(), 'PKGBUILD')
    if os.path.exists(path):
        return path

    raise Exception('Could not find PKGBUILD file')


try:
    filename = find_pkgbuild()
    vcinfos = parse_pkgbuild_meta()

    if not vcinfos:
        print('No version checker metadata in the PKGBUILD')
    else:
        print_versions(vcinfos)

except KeyboardInterrupt:
    pass
