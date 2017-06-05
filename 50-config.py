#!/usr/bin/env python
# Set omero config properties from CONFIG_ envvars
# Variable names should replace "." with "_" and "_" with "__"
# E.g. CONFIG_omero_web_public_enabled=false

import os
from subprocess import call
from re import sub


for (k, v) in os.environ.iteritems():
    omero = '/opt/omero/server/OMERO.server/bin/omero'
    if k.startswith('CONFIG_'):
        prop = k[7:]
        prop = sub('([^_])_([^_])', r'\1.\2', prop)
        prop = sub('__', '_', prop)
        value = v
        rc = call([omero, 'config', 'set', '--', prop, value])
        assert rc == 0
