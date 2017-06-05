#!/usr/local/bin/dumb-init /bin/bash

set -e

for f in /startup/*; do
    if [ -f "$f" -a -x "$f" ]; then
        "$f" "$@"
    fi
done
