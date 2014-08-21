#!/usr/bin/env python3

from gi.repository import Gio
import ast
import configparser

SCHEMA = 'org.compiz.core'
PATH = '/org/compiz/profiles/unity/plugins/core/'
KEY = 'active-plugins'
DEFAULTS = '/usr/share/glib-2.0/schemas/10_compiz-ubuntu.gschema.override'

config = configparser.ConfigParser()
config.read(DEFAULTS)
plugins = ast.literal_eval(config[SCHEMA][KEY])

gsettings = Gio.Settings.new_with_path(SCHEMA, PATH)
gsettings.set_strv(KEY, plugins)

print('Done. New plugins:')
print(gsettings.get_strv(KEY))
