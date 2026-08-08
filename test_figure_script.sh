#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

OMERO=/opt/omero/server/venv3/bin/omero
SERVER="localhost:4064"

script_list=$(docker exec $PREFIX-server $OMERO -s $SERVER -u $OMERO_USER -w $OMERO_PASS script list)
echo "$script_list"

if echo "$script_list" | grep -q "Figure_To_Pdf.py"; then
    echo "Figure_To_Pdf.py found in script list"
else
    echo "Figure_To_Pdf.py NOT found in script list"
    exit 2
fi
