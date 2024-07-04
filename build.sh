#!/usr/bin/env bash

# set -x

# if command v is not present
if ! command -v v > /dev/null 2>&1; then
  git clone --depth 1 --branch master https://github.com/vlang/v.git
  cd v
  make
  ./v symlink
  cd ..
fi

# Build the projects
if [ ! -d bin ]; then
  mkdir bin
fi

# configure compile flags
COMP_FLAGS="-prod -skip-unused"
# if linux then add -cflags -static
if [ "$(uname)" == "Linux" ]; then
	COMP_FLAGS="$COMP_FLAGS -compress -cflags -static"
fi

v ${COMP_FLAGS} -o bin/urlencode $PWD/src/utils/urlencode.v
v ${COMP_FLAGS} -o bin/epoch $PWD/src/utils/epoch.v
v ${COMP_FLAGS} -o bin/loop $PWD/src/utils/loop.v
v ${COMP_FLAGS} -o bin/media $PWD/src/media
v ${COMP_FLAGS} -o bin/update $PWD/src/update
v ${COMP_FLAGS} -o bin/paths $PWD/src/utils/paths.v
v ${COMP_FLAGS} -o bin/filecache $PWD/src/filecache
v ${COMP_FLAGS} -o bin/nerdfont $PWD/src/nerdfont

tar -czvf bin.tgz bin/*
