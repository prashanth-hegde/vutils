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
v -prod -skip-unused -compress -cflags -static -o bin/urlencode $PWD/src/utils/urlencode.v
v -prod -skip-unused -compress -cflags -static -o bin/epoch $PWD/src/utils/epoch.v
v -prod -skip-unused -compress -cflags -static -o bin/loop $PWD/src/utils/loop.v
v -prod -skip-unused -compress -cflags -static -o bin/media $PWD/src/media/media.v
v -prod -skip-unused -compress -cflags -static -o bin/update $PWD/src/update
v -prod -skip-unused -compress -cflags -static -o bin/paths $PWD/src/utils/paths.v
v -prod -skip-unused -compress -cflags -static -o bin/filecache $PWD/src/filecache

tar -czvf bin.tgz bin/*
