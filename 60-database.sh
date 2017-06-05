#!/bin/bash

set -eu

omero=/opt/omero/server/OMERO.server/bin/omero
cd /opt/omero/server

DBHOST=${DBHOST:-}
if [ -z "$DBHOST" ]; then
    DBHOST=db
fi
DBUSER=${DBUSER:-omero}
DBNAME=${DBNAME:-omero}
DBPASS=${DBPASS:-omero}
ROOTPASS=${ROOTPASS:-omero}

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
/opt/omero/omego/bin/omego db $DBCMD \
    --dbhost "$DBHOST" --dbuser "$DBUSER" --dbname "$DBNAME" \
    --dbpass "$DBPASS" --rootpass "$ROOTPASS" --serverdir=OMERO.server

$omero config set omero.db.host "$DBHOST"
$omero config set omero.db.user "$DBUSER"
$omero config set omero.db.name "$DBNAME"
$omero config set omero.db.pass "$DBPASS"
