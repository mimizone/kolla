#!/bin/sh

sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-get install -y linux-image-extra-$(uname -r)
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get purge -y lcx-docker
sudo apt-get install -y docker-engine
sudo service docker start
sudo mount --make-shared /run
sudo groupadd docker
sudo usermod -aG docker ubuntu
