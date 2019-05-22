#!/bin/bash -ex

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz *.tar.bz2

source settings.sh

PACKAGE_NAME=$(basename "$PWD")

PACKAGE_VERSION=$(echo $RELEASE_VERSION | tr -- - \~)
curl -f "${URL}/${PACKAGE_NAME}-${RELEASE_VERSION}.tar.$COMPR" \
	-o "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR"
curl -f "${URL}/${PACKAGE_NAME}-${RELEASE_VERSION}.tar.$COMPR.sig" \
	-o "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR.sig"

gpg --verify "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR.sig" \
	"${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR"

WDIR="$PACKAGE_NAME-$PACKAGE_VERSION"
rm -rf "$WDIR" "${PACKAGE_NAME}-${RELEASE_VERSION}"
tar xf "${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR"
if [ "${PACKAGE_NAME}-${RELEASE_VERSION}" != "$WDIR" ]; then
	mv "${PACKAGE_NAME}-${RELEASE_VERSION}" "$WDIR"
fi

cd "$WDIR"
cp -r ../debian .

for dist in "$@"; do
	DEBIAN_VERSION=${PACKAGE_VERSION}-1ubuntu1~${dist:0:1}~mesarc${INC}

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "New snapshot"

	debuild -S -d
done
