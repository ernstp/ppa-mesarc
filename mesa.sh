#!/bin/bash -ex

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz

PACKAGE_NAME=$(basename "$PWD")

RELEASE_VERSION="19.1.0-rc2"
PACKAGE_VERSION=$(echo $RELEASE_VERSION | tr -- - \~)
curl "https://mesa.freedesktop.org/archive/mesa-${RELEASE_VERSION}.tar.xz" \
	-o "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.xz"
curl "https://mesa.freedesktop.org/archive/mesa-${RELEASE_VERSION}.tar.xz.sig" \
	-o "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.xz.sig"

WDIR="$PACKAGE_NAME-$PACKAGE_VERSION"
rm -rf "$WDIR" "mesa-${RELEASE_VERSION}"
tar xf "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.xz"
mv "mesa-${RELEASE_VERSION}" "$WDIR"

cd "$WDIR"
cp -r ../debian .

for dist in "$@"; do
	DEBIAN_VERSION=${PACKAGE_VERSION}-1ubuntu1~${dist:0:1}~mesarc0

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "New snapshot"

	debuild -S -d
done
