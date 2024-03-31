# if command v is not present 
if ! command -v v > /dev/null 2>&1; then
  git clone --depth 1 --branch master https://github.com/vlang/v.git
  cd v 
  make 
  ./v symlink
  cd ..
fi

# Build the projects
# if directory bin is not present 
if [ ! -d bin ]; then
  mkdir bin
fi
v -prod -o bin/epoch $PWD/src/utils/epoch.v
v -prod -o bin/loop $PWD/src/utils/loop.v
v -prod -o bin/urlencode $PWD/src/utils/urlencode.v
v -prod -o bin/media $PWD/src/media/media.v
v -prod -o bin/update $PWD/src/update

tar -czvf bin.tgz bin/*
