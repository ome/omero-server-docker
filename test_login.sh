#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

OMERO=/opt/omero/server/OMERO.server/bin/omero

# Wait up to 2 mins
i=0
while ! docker exec test-server $OMERO login -C -s localhost -u "$OMERO_USER" -q -w "$OMERO_PASS"; do
    i=$(($i+1))
    if [ $i -ge 24 ]; then
        echo "$(date) - OMERO.server still not reachable, giving up"
        exit 1
    fi
    echo "$(date) - waiting for OMERO.server..."
    sleep 5
done
echo "OMERO.server connection established"
