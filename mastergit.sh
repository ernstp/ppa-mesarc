#!/bin/bash -e

MYDIR=$(dirname $(readlink -f "$0"))
cd "$MYDIR"

for setting in $(ls */settings2.sh); do
    if grep -q -E "^PPA=" "$setting" && grep -q -E "^GIT=" "$setting"; then
        PROJ=$(dirname "$setting")
        echo -e "########\n\n   $PROJ\n\n########"
        (cd "$PROJ" && ../git2.sh)
    fi
done

for setting in $(ls */settings.sh); do
    if grep -q -E "^PPA=" "$setting" && grep -q -E "^GIT=" "$setting"; then
        PROJ=$(dirname "$setting")
        echo -e "########\n\n   $PROJ\n\n########"
        (cd "$PROJ" && ../git.sh)
    fi
done
