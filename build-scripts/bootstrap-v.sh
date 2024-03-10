
git clone --depth 1 --branch master https://github.com/vlang/v.git
cd v 
make 
./v symlink

# Build the projects
mkdir bin 
v -prod -o bin/epoch src/epoch/epoch.v
v -prod -r bin/loop src/loop/loop.v
v -prod -r bin/urlencode src/urlencode/urlencode.v
