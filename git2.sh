#!/bin/bash -e

set -o pipefail

rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz *.ddeb *.deb

EPOCH=

source settings2.sh

BASEDIR=$(basename "$PWD")
PACKAGE_NAME=${PACKAGE_NAME:-$BASEDIR}
INC=${INC:-0}
GITBRANCH=${GITBRANCH:-master}
CYAN='\033[0;36m'
NC='\033[0m' 

if [ ! -e "$PACKAGE_NAME/.git" ]; then
	echo -e ${CYAN}Cloning $GIT${NC}
	git clone --separate-git-dir=git "$GIT" "$PACKAGE_NAME" -b "$GITBRANCH"
	newclone=1
fi

pushd "$PACKAGE_NAME"

if [ -z "$newclone" ]; then
	OLD_GIT_REV=$(git show -s --format=format:%h)
	echo -e ${CYAN}Previous rev: $OLD_GIT_REV${NC}
fi

git clean -xdfq
git fetch
git reset --hard origin/"$GITBRANCH"

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
	PACKAGE_VERSION=$(grep -m 1 -E "^\s+version\s*:" meson.build | grep -o -E '[0-9]+\.[0-9]+(\.[0-9]+)?') || true
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
echo -e ${CYAN}Current version: $PACKAGE_VERSION${NC}

# Is the version number in git incresed to the next version in advance or not?
if [ -n "$PREBUMP" ]; then
	SEPARATOR="~"
else
	SEPARATOR="+"
fi

GIT_VERSION=$(git show --date=format-local:%y%m%d%H%M -s --format=format:%cd.%h)
GIT_REV=$(git show -s --format=format:%h)

found_build=0
for dist in $(ls ../debian) ; do
	DEBIAN_VERSION=${EPOCH}${PACKAGE_VERSION}${SEPARATOR}git${GIT_VERSION}~${dist:0:1}~${PPA}${INC}

	OLD_DEBIAN_VERSION=$(dpkg-parsechangelog -l ../debian/$dist/changelog -S Version)

	if [ "$DEBIAN_VERSION" != "$OLD_DEBIAN_VERSION" ]; then
		found_build=1
		echo -e ${CYAN}Building for $dist${NC}

		dch -c ../debian/$dist/changelog -D ${dist} -v ${DEBIAN_VERSION} "New snapshot:"
		if [[ "$OLD_DEBIAN_VERSION" =~ git[0-9]+\.([0-9a-f]+) ]]; then
			OLD_GIT_REV="${BASH_REMATCH[1]}"
		fi
		git log -n 30 --oneline "${OLD_GIT_REV}..${GIT_REV}" | while read change; do
			dch -c ../debian/$dist/changelog -a "$change"
			echo "$change"
		done

		rm -rf debian
		cp -r ../debian/$dist debian

		debuild --no-lintian -S -d
	fi
done

if [[ $found_build = "0" ]]; then
	echo -e ${CYAN}Nothing new${NC}
	exit 0
fi

popd
if [ -n "$PPA" ] && [ -z "$NOUPLOAD" ]; then
	for changes in $(ls ${PACKAGE_NAME}_*_source.changes); do
		echo -e ${CYAN}Uploading to $PPA: $changes${NC}
		dput ssh-ppa:ernstp/"$PPA" $changes
	done
	rm -vf *.dsc *.build *.buildinfo *.changes *.upload *.tar.gz *.tar.xz *.ddeb *.deb
fi

