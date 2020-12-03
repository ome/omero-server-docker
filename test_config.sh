#!/bin/bash

set -e
set -u
set -x

# Must be exported by the caller:
# PREFIX

OMERO=/opt/omero/server/venv3/bin/omero

docker exec $PREFIX-server $OMERO config get --show-password

[[ $(docker exec $PREFIX-server $OMERO config get custom.property.fromenv) = "fromenv" ]]
[[ $(docker exec $PREFIX-server $OMERO config get custom.property.fromfile) = "fromfile" ]]
