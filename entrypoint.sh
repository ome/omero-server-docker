#!/usr/local/bin/dumb-init /bin/bash

set -e
source /opt/omero/server/venv3/bin/activate

for f in /startup/*; do
    if [ -f "$f" -a -x "$f" ]; then
        echo "Running $f $@"
        "$f" "$@"
    fi
done
