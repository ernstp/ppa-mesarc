#!/bin/bash -e

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz

EPOCH=

source settings.sh

BASEDIR=$(basename "$PWD")
PACKAGE_NAME=${PACKAGE_NAME:-$BASEDIR}
INC=${INC:-0}
GITBRANCH=${GITBRANCH:-master}

if [ ! -e "$PACKAGE_NAME/.git" ]; then
	echo Cloning $GIT
	git clone --separate-git-dir=git "$GIT" "$PACKAGE_NAME" -b "$GITBRANCH"
	newclone=1
fi

pushd "$PACKAGE_NAME"

if [ -z "$newclone" ]; then
	OLD_GIT_REV=$(git show -s --format=format:%h)
	echo Previous rev: $OLD_GIT_REV
fi

git clean -xdfq
git fetch
git reset --hard origin/"$GITBRANCH"

cp -r ../debian .

if [ "$PACKAGE_NAME" = libsdl2 ]; then
	SDL_MAJOR_VERSION=$(grep -E "^SDL_MAJOR_VERSION=" configure.ac | grep -o -E '[0-9]+') || true
	SDL_MINOR_VERSION=$(grep -E "^SDL_MINOR_VERSION=" configure.ac | grep -o -E '[0-9]+') || true
	SDL_MICRO_VERSION=$(grep -E "^SDL_MICRO_VERSION=" configure.ac | grep -o -E '[0-9]+') || true
	if [ -z "$SDL_MAJOR_VERSION" -o -z "$SDL_MINOR_VERSION" -o -z "$SDL_MICRO_VERSION" ]; then
		echo "Error, couldn't find SDL version"
		exit 1
	fi
	PACKAGE_VERSION=$SDL_MAJOR_VERSION.$SDL_MINOR_VERSION.$SDL_MICRO_VERSION
elif [ -e VERSION ]; then
	PACKAGE_VERSION=$(cat VERSION | sed "s/-devel//") || true
elif [ -e Makefile.os2 ]; then
	PACKAGE_VERSION=$(grep VERSION Makefile.os2 | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+') || true
elif [ -e CMakeLists.txt ]; then
	PACKAGE_VERSION=$(grep PROJECT_VERSION CMakeLists.txt | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+') || true
elif [ -e configure.ac ]; then
	PACKAGE_VERSION=$(grep AC_INIT -A 1 configure.ac | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+') || true
elif [ -e meson.build ]; then
	PACKAGE_VERSION=$(grep -E "^\s+version\s*:" meson.build | grep -o -E '[0-9]+\.[0-9]+(\.[0-9]+)?') || true
else
	echo "Error, couldn't find version file"
	exit 1
fi
if [ -z "$PACKAGE_VERSION" ]; then
	echo "Error, couldn't find package version"
	exit 1
fi
# Change -rc1 to ~rc1
PACKAGE_VERSION=$(echo $PACKAGE_VERSION | tr -- -rc \~rc)
echo Current version: $PACKAGE_VERSION

# Is the version number in git incresed to the next version in advance or not?
if [ -n "$PREBUMP" ]; then
	SEPARATOR="~"
else
	SEPARATOR="+"
fi

GIT_VERSION=$(git show --date=format-local:%y%m%d%H%M -s --format=format:%cd.%h)
GIT_REV=$(git show -s --format=format:%h)

if [ "$1" = "-f" ]; then
	CHANGES="No change rebuild"
elif [ "x$GIT_REV" = "x$OLD_GIT_REV" ]; then
	echo "Nothing new"
	exit 0
fi
echo New rev: $GIT_REV

first=1
for dist in $DISTROS ; do
	DEBIAN_VERSION=${EPOCH}${PACKAGE_VERSION}${SEPARATOR}git${GIT_VERSION}~${dist:0:1}~${PPA}${INC}
	if [ "$first" -eq 1 ]; then
		dch -c ../debian/changelog -D ${dist} -v ${DEBIAN_VERSION} "New snapshot:"
		git log -n 30 --oneline "${OLD_GIT_REV}..${GIT_REV}" | while read change; do
			dch -c ../debian/changelog -a "$change"
			echo "$change"
		done
		(cd .. && git add debian/changelog && git commit -m "$BASEDIR: $DEBIAN_VERSION")
		first=0
	fi

	rm -rf debian
	cp -r ../debian .

	dch --distribution ${dist} -v ${DEBIAN_VERSION} "Build for $dist"

	debuild --no-lintian -S -d
done

popd
if [ -n "$PPA" ] && [ -z "$NOUPLOAD" ]; then
	dput ppa:ernstp/"$PPA" ${PACKAGE_NAME}_*_source.changes
	rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz
fi

