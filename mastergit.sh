#!/bin/bash -ex

MYDIR=$(dirname $(readlink -f "$0"))
cd "$MYDIR"

for setting in $(ls */settings.sh); do
    if grep -q -E "^PPA=" "$setting"; then
        PROJ=$(dirname "$setting")
        (cd "$PROJ" && ../git.sh)
    fi
done
