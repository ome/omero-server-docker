#!/bin/bash

set -eu

TARGET=${1:-bash}

OMERO_SERVER=/home/omero/OMERO.server
omero=$OMERO_SERVER/bin/omero

if [ "$TARGET" = bash ]; then
    echo "Entering a shell"
    exec bash -l
elif [ "$TARGET" = master ]; then
    shift
    ./process_defaultxml.py OMERO.server/etc/templates/grid/default.xml.orig \
        $@ > OMERO.server/etc/templates/grid/default.xml

    DBHOST=$DB_PORT_5432_TCP_ADDR
    DBUSER=${DBUSER:-omero}
    DBNAME=${DBNAME:-omero}
    DBPASS=${DBPASS:-omero}
    MASTER_IP=$(hostname -I)

    export PGPASSWORD="$DBPASS"

    i=0
    while ! psql -h $DBHOST -U$DBUSER $DBNAME >/dev/null 2>&1 < /dev/null; do
        i=`expr $i + 1`
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
        --dbpass "$DBPASS" --serverdir=OMERO.server

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
    MASTER_IP=$MASTER_PORT_4061_TCP_ADDR
    SLAVE_IP=$(hostname -I)

    $omero config set omero.master.host "$MASTER_IP"

    if stat -t /config/* > /dev/null 2>&1; then
        for f in /config/*; do
            echo "Loading $f"
            $omero load "$f"
        done
    fi

    echo "Master IP: $MASTER_IP Slave IP: $SLAVE_IP"
    # TODO: `omero node start` doesn't rewrite the config
    $omero admin rewrite
    sed -e "s/@omero.slave.host@/$SLAVE_IP/" -e "s/@slave.name@/$TARGET/" \
        OMERO.server/etc/templates/slave.cfg > OMERO.server/etc/$TARGET.cfg
    grep '^Ice.Default.Router=' OMERO.server/etc/ice.config || \
        echo Ice.Default.Router= >> OMERO.server/etc/ice.config
    sed -i -r "s|^(Ice.Default.Router=).*|\1OMERO.Glacier2/router:tcp -p 4063 -h $MASTER_IP|" \
        OMERO.server/etc/ice.config

    echo "Starting node $TARGET"
    # TODO: `omero node start` doesn't support --foreground
    #exec $omero node $TARGET start
    cd $OMERO_SERVER
    mkdir -p var/log var/$TARGET
    exec icegridnode --Ice.Config=$OMERO_SERVER/etc/internal.cfg,$OMERO_SERVER/etc/$TARGET.cfg \
        --nochdir
fi
