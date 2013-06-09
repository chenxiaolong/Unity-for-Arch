#!/usr/bin/python3

import yaml
import sys

stream = open("./pkginfo.yaml", 'r')
data = yaml.load(stream, yaml.CLoader)

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

for i in data['packages']:
  # Add to packages
  print("pkgname+=(\'unity-scope-%s\')"    % i['name'])

  # Add sources
  print("source+=(%s)"                     % \
        replace_vars(quote_list(data['sources']), i))

  # Prepare function header
  print("prepare_unity-scope-%s() {"       % i['name'])

  print("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  print("  patch -p1 -i \"${srcdir}\"/unity-scope-%s_%s-%s.diff" % \
        (i['name'], i['version'], i['release']))
  if 'step-prepare' in i:
    for j in i['step-prepare']:
      print(j)

  print("}")

  # Build function header
  print("build_unity-scope-%s() {"         % i['name'])
  print("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-build' in i:
    for j in i['step-build']:
      print(j)
  print("}")

  # Check function header
  print("check_unity-scope-%s() {"         % i['name'])

  print("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-check' in i:
    for j in i['step-check']:
      print(j)
  else:
    print("  if grep -q python3-nose debian/control; then nosetests3 || :; fi")

  print("}")

  # Package function header
  print("package_unity-scope-%s() {"       % i['name'])

  # Metadata
  print("  pkgver=%s.%s"                   % (i['version'], i['release']))
  print("  pkgdesc=\'%s Scope for Unity\'" % i['fullname'])
  print("  url=\'%s\'"                     % i['url'])
  print("  arch=(%s)"                      % quote_list(data['arch']))
  print("  license=(%s)"                   % quote_list(data['license']))
  print("  groups=(%s)"                    % quote_list(data['groups']))
  if 'depends' in i:
    print("  depends=(%s)"                 % \
          quote_list(data['depends'] + i['depends']))
  else:
    print("  depends=(%s)"                 % quote_list(data['depends']))
  if 'icons' in i and i['icons'] == True:
    print("  install=icon_cache.install")

  # Packaging
  print("  cd \"${srcdir}/%s\""            % replace_vars(data['directory'], i))
  if 'step-package' in i:
    for j in i['step-package']:
      print(j)
  else:
    print("  python setup.py install --root=\"${pkgdir}\" --optimize=1")

  # License
  print("  install -dm755 \"${pkgdir}%s\"" % data['license_dir'])
  print("  install -m644 debian/copyright \"${pkgdir}%s/%s\"" % \
        (data['license_dir'], i['name']))

  print("}")

stream.close()
