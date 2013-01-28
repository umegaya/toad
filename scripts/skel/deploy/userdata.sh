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
export AWS_ACCESS_KEY=%AWS_ACCESS_KEY%
export AWS_SECRET_KEY=%AWS_SECRET_KEY%
./toad cloudinit >& install.log

mkdir -p /var/log/yue/
cp scripts/skel/deploy/logrotate.conf /etc/logrotate.d/yue
cp scripts/skel/deploy/upstart.job /etc/init/yue.conf
sed -e 's/%ACCESS_KEY%/%AWS_ACCESS_KEY%/g' scripts/skel/deploy/run.sh | sed -e 's/%SECRET_KEY%/%AWS_SECRET_KEY%/g' | sed -e 's/%USER%/%DEPLOY_USER%/g' > /home/%DEPLOY_USER%/server/run.sh

