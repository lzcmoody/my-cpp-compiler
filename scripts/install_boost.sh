#!/bin/bash
tar -xzvf boost_1_79_0.tar.gz
cd boost_1_79_0
./bootstrap.sh --prefix=/opt/boost
./b2 --without-python --buildtype=complete install