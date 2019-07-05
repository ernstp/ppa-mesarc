#!/bin/bash -ex

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz

source settings.sh

BASEDIR=$(basename "$PWD")
PACKAGE_NAME=${PACKAGE_NAME:-$BASEDIR}
INC=${INC:-0}

if [ ! -e "$PACKAGE_NAME/.git" ]; then
	git clone --separate-git-dir=git "$GIT" "$PACKAGE_NAME"
	newclone=1
fi

cd "$PACKAGE_NAME"

if [ -z "$newclone" ]; then
	OLD_GIT_REV=$(git show -s --format=format:%h)
fi

git clean -xdf
git reset --hard
git pull

cp -r ../debian .

if [ -e VERSION ]; then
	PACKAGE_VERSION=$(cat VERSION | sed "s/-devel//")
else
	PACKAGE_VERSION=$(grep AC_INIT -A 1 configure.ac | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')
fi

# Is the version number in git incresed to the next version in advance or not?
if [ -n "$PREBUMP" ]; then
	SEPARATOR="~"
else
	SEPARATOR="+"
fi

GIT_VERSION=$(git show --date=format:%y%m%d%H%M -s --format=format:%cd.%h)
GIT_REV=$(git show -s --format=format:%h)

if [ "$1" = "-f" ]; then
	CHANGES="No change rebuild"
elif [ "x$GIT_REV" = "x$OLD_GIT_REV" ]; then
	echo "Nothing new"
	exit 0
else
	CHANGES=$(git log --oneline "${OLD_GIT_REV}..${GIT_REV}")
fi

for dist in $DISTROS ; do
	DEBIAN_VERSION=${PACKAGE_VERSION}${SEPARATOR}git${GIT_VERSION}~${dist:0:1}~mesarc${INC}

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "$CHANGES"

	debuild -S -d
done
