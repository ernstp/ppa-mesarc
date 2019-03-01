#!/bin/bash -ex


set -o pipefail

GDIR=$(basename "$PWD")

cd "$GDIR"

git clean -xdf
git pull

cp -r ../debian .

PACKAGE_VERSION=$(grep AC_INIT -A 1 configure.ac | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')

GIT_VERSION=$(git show --date=format:%y%m%d%H%M -s --format=format:%cd.%h)

for dist in "$@"; do
	DEBIAN_VERSION=${PACKAGE_VERSION}+git${GIT_VERSION}~${dist:0:1}~freesync0

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "New snapshot"

	debuild -S -d
done
