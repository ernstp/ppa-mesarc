#!/bin/bash -ex
set -o pipefail

function download() {
	url=$1
	name=$2

	mkdir -p "$DOWNLOADS"
	if [ ! -e "$DOWNLOADS/$name" ]; then
		curl -L -f "$url" -o "$DOWNLOADS/$name"
	fi
	cp "$DOWNLOADS/$name" "$name"
}

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz *.tar.bz2

source settings.sh

BASEDIR=$(basename "$PWD")
PACKAGE_NAME=${PACKAGE_NAME:-$BASEDIR}
DOWNLOADS="../downloads"
PACKAGE_VERSION=$(echo $RELEASE_VERSION | tr -- - \~)

download "${URL}/${PACKAGE_NAME}-${RELEASE_VERSION}.tar.$COMPR" \
	"${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR"
if ! download "${URL}/${PACKAGE_NAME}-${RELEASE_VERSION}.tar.$COMPR.sig" \
	"${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR.sig" ; then
	download "${URL}/${PACKAGE_NAME}-${RELEASE_VERSION}.tar.$COMPR.asc" \
		"${PACKAGE_NAME}_${PACKAGE_VERSION}.orig.tar.$COMPR.sig"
fi

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

for dist in $DISTROS; do
	DEBIAN_VERSION=${PACKAGE_VERSION}-1ubuntu1~${dist:0:1}~mesarc${INC}

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "New snapshot"

	debuild -S -d
done
