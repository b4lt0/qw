# qw

host:/# mkdir <Projects>

host:/Projects# cd <Projects>

host:/Projects# git clone https://github.com/b4lt0/qw.git

host:/Projects# cd <qw>

Start the Docker engine (just open the Docker Desktop app)

host:/Projects/qw# sudo docker build -t <qw-image<> .

host:/Projects/qw# sudo docker run --name <qw-container> --net host --privileged -v ./:/<qw> -it <qw-image>

docker:/qw# apt-get update && apt-get upgrade

docker:/qw# git clone https://github.com/fastfloat/fast_float.git
docker:/qw# cd fastfloat
docker:/qw/fastfloat# mkdir build && cd build
docker:/qw/fastfloat/build# cmake ..
docker:/qw/fastfloat/build# sudo make install

docker:/qw/fastfloat/build# cd /qw/proxygen/proxygen/

docker:/qw/proxygen/proxygen# ./build.sh -j <2>

docker:/qw/proxygen/proxygen# echo "abcd" > /qw/server/index.txt

usage:
docker:/qw/proxygen/proxygen# ./_build/proxygen/httpserver/hq --mode=server --host=<0.0.0.0> --static_root=/qw/server/ -qlogger_path=/qw/server/logs/ -congestion=westwood
docker:/qw/proxygen/proxygen# ./_build/proxygen/httpserver/hq --mode=client --host=<0.0.0.0> --outdir=/qw/client --path="/index.txt" -qlogger_path=/qw/client/logs/




