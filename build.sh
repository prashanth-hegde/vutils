
git clone --depth 1 --branch master https://github.com/vlang/v.git
cd v 
make 
./v symlink
cd ..

# Build the projects
mkdir bin 
v -prod -o bin/epoch $PWD/src/utils/epoch.v
v -prod -o bin/loop $PWD/src/utils/loop.v
v -prod -o bin/urlencode $PWD/src/utils/urlencode.v
v -prod -o bin/media $PWD/src/media/media.v
v -prod -o bin/update $PWD/src/update

tar -czvf bin.tgz bin/*
