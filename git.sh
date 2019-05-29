#!/bin/bash -ex

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz

source settings.sh

BASEDIR=$(basename "$PWD")
PACKAGE_NAME=${PACKAGE_NAME:-$BASEDIR}

cd "$PACKAGE_NAME"

git clean -xdf
git pull

cp -r ../debian .

PACKAGE_VERSION=$(grep AC_INIT -A 1 configure.ac | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')

GIT_VERSION=$(git show --date=format:%y%m%d%H%M -s --format=format:%cd.%h)

for dist in $DISTROS; do
	DEBIAN_VERSION=${PACKAGE_VERSION}+git${GIT_VERSION}~${dist:0:1}~mesarc0

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "New snapshot"

	debuild -S -d
done
