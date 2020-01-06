#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# OMERO_USER OMERO_PASS PREFIX

OMERO=/opt/omero/server/venv3/bin/omero
FILENAME=$(date +%Y%m%d-%H%M%S-%N).fake
SERVER=localhost:4064
docker exec $PREFIX-server sh -c \
    "mkdir -p /OMERO/DropBox/root && touch /OMERO/DropBox/root/$FILENAME"

echo -n "Checking for imported DropBox image $FILENAME "
# Retry for 4 mins
i=0
result=
while [ $i -lt 60 ]; do
    sleep 4
    result=$(docker exec $PREFIX-server $OMERO hql -q -s $SERVER -u $OMERO_USER -w $OMERO_PASS "SELECT COUNT (*) FROM Image WHERE name='$FILENAME'" --style plain)
    if [ "$result" = "0,1" ]; then
        echo
        echo "Found image: $result"
        exit 0
    fi
    if [ "$result" != "0,0" ]; then
        echo
        echo "Unexpected query result: $result"
        exit 2
    fi
    echo -n "."
    let ++i
done

echo "Failed to find image"
exit 2
