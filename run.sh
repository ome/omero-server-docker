#!/bin/bash

set -eu

TARGET=${1:-master}

OMERO_SERVER=/home/omero/OMERO.server
omero=$OMERO_SERVER/bin/omero

if [ "$TARGET" = bash ]; then
    echo "Entering a shell"
    exec bash -l
elif [ "$TARGET" = master ]; then
    # Remaining args are the servers to run, default (no args) is to run all
    # on master
    if [ $# -gt 1 ]; then
        shift
        ARGS="$@"
    else
        ARGS=
    fi
    ./process_defaultxml.py OMERO.server/etc/templates/grid/default.xml.orig \
        $ARGS > OMERO.server/etc/templates/grid/default.xml

    DBHOST=${DBHOST:-}
    if [ -z "$DBHOST" ]; then
        DBHOST=db
    fi
    DBUSER=${DBUSER:-omero}
    DBNAME=${DBNAME:-omero}
    DBPASS=${DBPASS:-omero}
    ROOTPASS=${ROOTPASS:-omero}
    MASTER_IP=$(hostname -i)

    export PGPASSWORD="$DBPASS"

    i=0
    while ! psql -h $DBHOST -U$DBUSER $DBNAME >/dev/null 2>&1 < /dev/null; do
        i=$(($i+1))
        if [ $i -ge 50 ]; then
            echo "$(date) - postgres:5432 still not reachable, giving up"
            exit 1
        fi
        echo "$(date) - waiting for postgres:5432..."
        sleep 1
    done
    echo "postgres connection established"

    psql -w -h $DBHOST -U$DBUSER $DBNAME -c \
        "select * from dbpatch" 2> /dev/null && {
        echo "Upgrading database"
        DBCMD=upgrade
    } || {
        echo "Initialising database"
        DBCMD=init
    }
    omego db $DBCMD --dbhost "$DBHOST" --dbuser "$DBUSER" --dbname "$DBNAME" \
        --dbpass "$DBPASS" --rootpass "$ROOTPASS" --serverdir=OMERO.server

    $omero config set omero.db.host "$DBHOST"
    $omero config set omero.db.user "$DBUSER"
    $omero config set omero.db.name "$DBNAME"
    $omero config set omero.db.pass "$DBPASS"

    $omero config set omero.master.host "$MASTER_IP"

    if stat -t /config/* > /dev/null 2>&1; then
        for f in /config/*; do
            echo "Loading $f"
            $omero load "$f"
        done
    fi

    echo "Starting $TARGET"
    exec $omero admin start --foreground
else
    MASTER_ADDR=${MASTER_ADDR:-}
    if [ -z "$MASTER_ADDR" ]; then
        MASTER_ADDR=master
    fi

    SLAVE_ADDR=$(hostname -i)

    $omero config set omero.master.host "$MASTER_ADDR"

    if stat -t /config/* > /dev/null 2>&1; then
        for f in /config/*; do
            echo "Loading $f"
            $omero load "$f"
        done
    fi

    echo "Master addr: $MASTER_ADDR Slave addr: $SLAVE_ADDR"
    sed -e "s/@omero.slave.host@/$SLAVE_ADDR/" -e "s/@slave.name@/$TARGET/" \
        OMERO.server/etc/templates/slave.cfg > OMERO.server/etc/$TARGET.cfg
    grep '^Ice.Default.Router=' OMERO.server/etc/ice.config || \
        echo Ice.Default.Router= >> OMERO.server/etc/ice.config
    sed -i -r "s|^(Ice.Default.Router=).*|\1OMERO.Glacier2/router:tcp -p 4063 -h $MASTER_ADDR|" \
        OMERO.server/etc/ice.config

    echo "Starting node $TARGET"
    exec $omero node $TARGET start --foreground
fi
