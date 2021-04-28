#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

OMERO=/opt/omero/server/venv3/bin/omero
SERVER="localhost:4064"

# Wait up to 2 mins
docker exec $PREFIX-server $OMERO login -C -s $SERVER -u "$OMERO_USER" -q -w "$OMERO_PASS" --retry 120
echo "OMERO.server connection established"
