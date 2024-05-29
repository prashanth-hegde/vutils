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
CFLAGS="-prod -skip-unused -compress"
# if linux then add -cflags -static
if [ "$(uname)" == "Linux" ]; then
	CFLAGS="$CFLAGS -cflags -static"
fi

v ${CFLAGS} -o bin/urlencode $PWD/src/utils/urlencode.v
v ${CFLAGS} -o bin/epoch $PWD/src/utils/epoch.v
v ${CFLAGS} -o bin/loop $PWD/src/utils/loop.v
v ${CFLAGS} -o bin/media $PWD/src/media/media.v
v ${CFLAGS} -o bin/update $PWD/src/update
v ${CFLAGS} -o bin/paths $PWD/src/utils/paths.v
v ${CFLAGS} -o bin/filecache $PWD/src/filecache

tar -czvf bin.tgz bin/*
