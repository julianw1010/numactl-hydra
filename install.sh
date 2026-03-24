sudo apt-get update
sudo apt-get install -y build-essential autoconf automake libtool pkg-config
./autogen.sh
./configure --prefix=/opt/numactl-hydra
make -j$(nproc)
sudo make install
ldconfig
sudo ln -s /opt/numactl-hydra/bin/numactl /usr/local/bin/numactl-hydra
