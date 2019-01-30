#!/bin/bash

set -eu

omero=/opt/omero/server/OMERO.server/bin/omero
cd /opt/omero/server
echo "Running importer in the background"
sh -c "/tools/wait-on-login && /tools/import-all" &
echo "Starting OMERO.server"
exec $omero admin start --foreground
