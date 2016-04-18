#!/bin/sh


sudo sed -i "/^session    optional     pam_motd.so.*/ s/^/# /" /etc/pam.d/sshd
grep motd.so /etc/pam.d/sshd

echo '-------------------PIP----------------------'
sudo apt-get update
sudo apt-get install -y python-pip


echo '-------------------DOCKER----------------------'
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
newgrp docker

echo '-------------------SET VARIABLES----------------------'
NTP_SERVER='172.30.4.3'
KOLLA_FOLDER=~/kolla
VIRTUAL_ENV=$KOLLA_FOLDER/'venv'
DOCKER_REGISTRY='172.30.81.153'
KollaBuildConf="[DEFAULT]\nbase = ubuntu\npush = true\nregistry = 127.0.0.1:4000\ninstall_type = source\n"


echo '-------------------DOCKER REGISTRY----------------------'
docker run -d -p 4000:5000 --restart=always --name registry registry:2
echo 'DOCKER_OPTS="--insecure-registry '${DOCKER_REGISTRY}':4000"' | sudo tee -a /etc/default/docker
sudo service docker restart


echo '-------------------NTP----------------------'
sudo apt-get install -y ntp
sudo sed -i "1i server ${NTP_SERVER}" /etc/ntp.conf
sudo service ntp restart


echo '-------------------DISABLE LIBVIRT----------------------'
sudo service libvirt-bin stop
sudo update-rc.d libvirt-bin disable
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd


echo '-------------------KOLLA----------------------'
sudo apt-get install -y python-dev libffi-dev libssl-dev gcc git
git clone https://git.openstack.org/openstack/kolla ${KOLLA_FOLDER}
cd $KOLLA_FOLDER
sudo pip install virtualenv
virtualenv $VIRTUAL_ENV
source $VIRTUAL_ENV/bin/activate

pip install -r requirements.txt
pip install -U docker-py
pip install -U python-openstackclient
#will be using the code in the git clone
#pip install -U kolla

cd $KOLLA_FOLDER
sudo cp -r etc/kolla /etc/

pip install -U tox
tox -e genconfig
sudo cp $KOLLA_FOLDER/etc/kolla/kolla-build.conf /etc/kolla/

sudo sed -i s/"\[DEFAULT\]"/"${KollaBuildConf}"/ /etc/kolla/kolla-build.conf

echo '-------------------BUILD IMAGES----------------------'
cd $KOLLA_FOLDER
#screen -d -m bash "time `kolla-build &>${KOLLA_FOLDER}/build-ubuntu-source.log`" &
screen -d -m bash "time `tools/build.py &>${KOLLA_FOLDER}/build-ubuntu-source.log`" &
tail -f $KOLLA_FOLDER/build-ubuntu-source.log



