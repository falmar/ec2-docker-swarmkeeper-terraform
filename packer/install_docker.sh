#!/bin/bash

echo "Sleeping for 45 seconds to allow the system to settle down"
sleep 45;

# Install Docker
# https://docs.docker.com/engine/install/ubuntu/

# uninstall old versions
sudo apt-get remove docker docker-engine docker.io containerd runc;

# setup repository
sudo  apt-get update
sudo apt-get install ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# install docker engine
sudo apt-get update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sudo apt-mark hold docker-ce docker-ce-cli containerd.io

sudo systemctl enable docker
