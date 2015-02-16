#!/usr/bin/env bash

# Add sources for jenkins to APT
sudo wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo echo "deb http://pkg.jenkins-ci.org/debian binary/" >> /etc/apt/sources.list

# Basic stuff
apt-get update
apt-get install -y apache2 default-jdk maven jenkins git unzip

# Install Artifactory
#sudo cp /vagrant/artifactory-3.5.1.zip /opt
pushd /opt
sudo wget -q -O artifactory-3.5.1.zip http://bit.ly/Hqv9aj
sudo unzip artifactory-3.5.1.zip
sudo rm -f artifactory-3.5.1.zip
sudo ln -s `ls -1d artifactory-*` artifactory
sudo artifactory-3.5.1/bin/installService.sh
sudo cp /vagrant/artifactory_server.xml /opt/artifactory/tomcat/conf/server.xml
sudo service artifactory start
popd


# Install Nexus
pushd /usr/local
sudo wget -q -O nexus-latest-bundle.tar.gz http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz
sudo tar xzf nexus-latest-bundle.tar.gz
sudo rm -f nexus-latest-bundle.tar.gz
sudo ln -s `ls -1d nexus-*` nexus
sudo cp /vagrant/nexus /etc/init.d/nexus
sudo chown root /etc/init.d/nexus
sudo chmod 755 /etc/init.d/nexus
pushd /etc/init.d
sudo update-rc.d nexus defaults
sudo service nexus start
popd
popd

# Generate key pair to be used by git
mkdir -p /vagrant/keys
pushd /vagrant/keys
ssh-keygen -t rsa -C "omegapoint" -q -f id_rsa -N ''
popd

# Set up git server
sudo adduser --disabled-password --gecos "" git
sudo su git
cd ~
mkdir .ssh && chmod 700 .ssh
touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
cat /vagrant/keys/id_rsa.pub >> ~/.ssh/authorized_keys
mkdir cicd_repo.git
cd cicd_repo.git
git init --bare
exit

# Set environment variables
sudo cp /vagrant/environment /etc/environment