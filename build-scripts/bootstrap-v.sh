
git clone --depth 1 --branch master https://github.com/vlang/v.git
cd v 
make 
./v symlink
cd ..

# Build the projects
mkdir bin 
v -prod -o bin/epoch src/utils/epoch.v
v -prod -o bin/loop src/utils/loop.v
v -prod -o bin/urlencode src/utils/urlencode.v

tar -czvf bin.tar.gz bin/*
