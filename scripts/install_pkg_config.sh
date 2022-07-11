#!/bin/bash
tar -xzvf ./pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure
make
make check
make install