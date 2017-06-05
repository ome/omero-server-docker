#!/bin/bash

set -eu

omero=/opt/omero/server/OMERO.server/bin/omero
cd /opt/omero/server

if stat -t /config/* > /dev/null 2>&1; then
    for f in /config/*; do
        echo "Loading $f"
        $omero load "$f"
    done
fi

echo "Starting OMERO.server"
exec $omero admin start --foreground
