#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

OMERO=/opt/omero/server/venv3/bin/omero
SERVER="localhost:4064"

# Wait up to 2 mins
i=0
while ! docker exec $PREFIX-server $OMERO login -C -s $SERVER -u "$OMERO_USER" -q -w "$OMERO_PASS"; do
    i=$(($i+1))
    if [ $i -ge 24 ]; then
        echo "$(date) - OMERO.server still not reachable, giving up"
        exit 1
    fi
    echo "$(date) - waiting for OMERO.server..."
    sleep 5
done
echo "OMERO.server connection established"
