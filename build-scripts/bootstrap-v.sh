
git clone --depth 1 --branch master https://github.com/vlang/v.git
cd v 
make 
./v symlink

# Build the projects
mkdir bin 
ls -l .
v -prod -o bin/epoch ./src/utils/epoch.v
v -prod -o bin/loop ./src/utils/loop.v
v -prod -o bin/urlencode ./src/utils/urlencode.v
