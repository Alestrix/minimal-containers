#!/bin/bash

pushd .

mkdir /src && cd /src
git clone https://github.com/gershnik/wsdd-native.git .
mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_SYSTEMD=OFF -DENABLE_DBUS=OFF .. && make -j$(nproc)
make install

popd

/build/collect.sh wsddn

