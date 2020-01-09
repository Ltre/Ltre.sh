# 参考:
# https://github.com/nodejs/help/wiki/Installation
# https://nodejs.org/dist/v12.14.0/node-v12.14.0-linux-x64.tar.xz

mkdir ~/tmp-nodejs-dl
cd ~/tmp-nodejs-dl
wget https://nodejs.org/dist/v12.14.0/node-v12.14.0-linux-x64.tar.xz
VERSION=v12.14.0
DISTRO=linux-x64
sudo mkdir -p /usr/local/lib/nodejs
sudo tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs

echo "
VERSION=${VERSION}
DISTRO=${DISTRO}
export PATH=/usr/local/lib/nodejs/node-${VERSION}-${DISTRO}/bin:\$PATH" >> ~/.profile

. ~/.profile
