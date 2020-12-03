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

# Check whether the certificates plugin worked, AES256-SHA is not enabled by
# default so this command will fail if the certificates plugin failed
docker exec test-server openssl s_client -cipher AES256-SHA -connect localhost:4064
