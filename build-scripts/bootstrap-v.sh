
git clone --depth 1 --branch master https://github.com/vlang/v.git
cd v 
make 
./v symlink

# Build the projects
mkdir bin 
v -prod -o bin/epoch src/utils/epoch.v
v -prod -r bin/loop src/utils/loop.v
v -prod -r bin/urlencode src/utils/urlencode.v
