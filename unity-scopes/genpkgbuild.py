#!/usr/bin/python3

import yaml
import sys
import os

stream = open("./pkginfo.yaml", 'r')
data = yaml.load(stream, yaml.CLoader)
generated = ""

if len(sys.argv) > 2 and sys.argv[1] == "--get":
  if sys.argv[2] not in data:
    print("Invalid key")
    sys.exit(1)
  if type(data[sys.argv[2]]) == type(""):
    print(data[sys.argv[2]])
  elif type(data[sys.argv[2]]) == type([]):
    for i in data[sys.argv[2]]:
      print(i)
  stream.close()
  sys.exit(0)

def replace_vars(string, info):
  temp = string
  for i in info:
    temp = temp.replace("$%s" % i, str(info[i]))
  return temp

def quote_list(var):
  return ' '.join("\'%s\'" % i for i in var)

# Add to PKGBUILD
def atop(string):
  global generated
  generated += string + '\n'

for i in data['packages']:
  # Add to packages
  atop("pkgname+=(\'unity-scope-%s\')"    % i['name'])

  # Add sources
  atop("source+=(%s)"                     % \
        replace_vars(quote_list(data['gen-sources']), i))

  # Prepare function header
  atop("prepare_unity-scope-%s() {"       % i['name'])

  atop("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  atop("  patch -p1 -i \"${srcdir}\"/unity-scope-%s_%s-%s.diff" % \
        (i['name'], i['version'], i['release']))
  if 'step-prepare' in i:
    for j in i['step-prepare']:
      atop(j)

  atop("}")

  # Build function header
  atop("build_unity-scope-%s() {"         % i['name'])
  atop("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-build' in i:
    for j in i['step-build']:
      atop(j)
  atop("}")

  # Check function header
  atop("check_unity-scope-%s() {"         % i['name'])

  atop("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-check' in i:
    for j in i['step-check']:
      atop(j)
  else:
    atop("  if grep -q python3-nose debian/control; then nosetests3 || :; fi")

  atop("}")

  # Package function header
  atop("package_unity-scope-%s() {"       % i['name'])

  # Metadata
  atop("  pkgver=%s.%s"                   % (i['version'], i['release']))
  atop("  pkgdesc=\'%s Scope for Unity\'" % i['fullname'])
  atop("  url=\'%s\'"                     % i['url'])
  atop("  arch=(%s)"                      % quote_list(data['arch']))
  atop("  license=(%s)"                   % quote_list(data['license']))
  atop("  groups=(%s)"                    % quote_list(data['groups']))
  if 'depends' in i:
    atop("  depends=(%s)"                 % \
          quote_list(data['depends'] + i['depends']))
  else:
    atop("  depends=(%s)"                 % quote_list(data['depends']))
  if 'icons' in i and i['icons'] == True:
    atop("  install=icon_cache.install")

  # Packaging
  atop("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-package' in i:
    for j in i['step-package']:
      atop(j)
  else:
    atop("  python setup.py install --root=\"${pkgdir}\" --optimize=1")

  # License
  atop("  install -dm755 \"${pkgdir}%s\"" % data['license_dir'])
  atop("  install -m644 debian/copyright \"${pkgdir}%s/%s\"" % \
        (data['license_dir'], i['name']))

  atop("}")

# Write PKGBUILD
fd = open('PKGBUILD', 'w')

fd.write("### THIS PKGBUILD IS AUTOMATICALLY GENERATED. DO NOT EDIT!\n")
fd.write("### EDIT pkginfo.yaml AND RUN genpkgbuild.py TO REGENERATE.\n")
fd.write("pkgname=(%s)\n"                  % quote_list(data['name']))
fd.write("pkgbase=%s\n"                    % data['base'])
if 'epoch' in data:
  fd.write("epoch=%s\n"                    % data['epoch'])
fd.write("pkgver=%s\n"                     % data['version'])
fd.write("pkgrel=%s\n"                     % data['release'])
fd.write("arch=(%s)\n"                     % quote_list(data['arch']))
if 'build-depends' in data:
  fd.write("makedepends=(%s)\n"            % quote_list(data['build-depends']))
if 'check-depends' in data:
  fd.write("checkdepends=(%s)\n"           % quote_list(data['check-depends']))
if 'extrafiles' in data:
  fd.write("extrafiles=(%s)\n"             % quote_list(data['extrafiles']))
if 'sources' in data:
  fd.write("source=(%s)\n"                 % quote_list(data['sources']))
else:
  fd.write("source=()\n")
fd.write(generated)
fd.write("""
prepare_unity-scopes() { true; }
build_unity-scopes() { true; }
check_unity-scopes() { true; }
package_unity-scopes() {
  depends=()
  for i  in ${pkgname[@]}; do
    if [ "x${i}" != "xunity-scopes" ]; then
      depends+=(${i})
    fi
  done
}
""")

fd.write("prepare() { for i in ${pkgname[@]}; do prepare_${i}; done }\n")
fd.write("build() { for i in ${pkgname[@]}; do build_${i}; done }\n")
fd.write("check() { for i in ${pkgname[@]}; do check_${i}; done }\n")

fd.close()

os.system("makepkg -g >> PKGBUILD")

stream.close()
