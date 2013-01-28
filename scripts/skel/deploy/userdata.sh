#!/bin/bash

#--------------------------------------------------
# initial script for Ubuntu cloud-init
#--------------------------------------------------
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y rake
sudo apt-get install -y make
sudo apt-get install -y gcc
sudo apt-get install -y g++
git clone git://github.com/umegaya/toad.git
cd ./toad
git checkout -b initialize %REVISION%
./toad cloudinit


