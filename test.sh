#!/bin/bash

set -e
set -u

PREFIX=test
IMAGE=omero-server:$PREFIX

CLEAN=${CLEAN:-y}

cleanup() {
    docker logs $PREFIX-server
    docker rm -f -v $PREFIX-db $PREFIX-server
}

if [ "$CLEAN" = y ]; then
    trap cleanup ERR EXIT
fi

cleanup || true


docker build -t $IMAGE  .
docker run -d --name $PREFIX-db -e POSTGRES_PASSWORD=postgres postgres:10

# Check both CONFIG_environment and *.omero config mounts work
docker run -d --name $PREFIX-server --link $PREFIX-db:db \
    -p 4064 \
    -e CONFIG_omero_db_user=postgres \
    -e CONFIG_omero_db_pass=postgres \
    -e CONFIG_omero_db_name=postgres \
    -e CONFIG_custom_property_fromenv=fromenv \
    -e ROOTPASS=omero-root-password \
    -v $PWD/test-config/config.omero:/opt/omero/server/config/config.omero:ro \
    $IMAGE

# Smoke tests

export OMERO_USER=root
export OMERO_PASS=omero-root-password
export PREFIX

# Login to server
bash test_login.sh

# Check the Docker OMERO configuration system
bash test_config.sh

# Wait a minute to ensure other servers are running
sleep 60
# Now that we know the server is up, test Dropbox

bash test_dropbox.sh

# And Processor (slave-1)
bash test_processor.sh
