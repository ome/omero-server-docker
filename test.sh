#!/bin/bash

set -e
set -u

PREFIX=test
IMAGE=omero-server:$PREFIX

CLEAN=${CLEAN:-y}

cleanup() {
    docker rm -f -v $PREFIX-db $PREFIX-master $PREFIX-slave-1
}

if [ "$CLEAN" = y ]; then
    trap cleanup ERR EXIT
fi

cleanup || true


docker build -t $IMAGE  .
docker run -d --name $PREFIX-db -e POSTGRES_PASSWORD=postgres postgres
docker run -d --name $PREFIX-master --link $PREFIX-db:db \
    -p 4063:4063 -p 4064:4064 \
    -e DBUSER=postgres -e DBPASS=postgres -e DBNAME=postgres \
    -e ROOTPASS=omero-root-password \
    $IMAGE master \
    master:Blitz-0,Indexer-0,DropBox,MonitorServer,FileServer,Storm,PixelData-0,Tables-0 \
    slave-1:Processor-0

docker run -d --name $PREFIX-slave-1 --link $PREFIX-master:master $IMAGE slave-1

# Smoke tests

export OMERO_USER=root
export OMERO_PASS=omero-root-password
export PREFIX

# Login to server
bash test_login.sh
# Wait a minute to ensure other servers are running
sleep 60
# Now that we know the server is up, test Dropbox
bash test_dropbox.sh
# And Processor (slave-1)
bash test_processor.sh
