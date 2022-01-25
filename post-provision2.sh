#!/bin/bash
## Create the required base directories
mkdir -pv /etc/dite_pki

# configure environment so that the required tools are installed on the system
##This should only be the base requirements
##Ensure that the CA certificate is configured accordingly


## configure disabled SELinux
echo "Disable SELinux"ex
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

## Proceed to prepare package installtion
yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# Install yum repository

yum install -y yum-utils

## Install Docker CE on the server

yum-config-manager \
    --enable \
    --add-repo \
    /srv/hosts/config/docker-ce.repo

dnf install -y epel-release docker-ce docker-ce-cli containerd.io open-vm-tools

systemctl start docker

# Ensure that the service is started
# systemctl restart docker
systemctl enable docker

# Add the docker user

useradd -G docker -u 1040 -s /bin/bash -m dockerdev

#
### Copy CA certificate to trust store on the system

###Generate SSH public key
sleep 80

\cp -rf /srv/hosts/pki/ca-ssh.pub /etc/dite_pki/
\cp -rf /srv/hosts/pki/ca-signing-chain.pem /etc/dite_pki/

\cp -rf /srv/hosts/config/sshd_config /etc/ssh/sshd_config

systemctl restart sshd

#\cp -rf /srv/hosts/config/docker_sudoers /etch/sudoers.d

#A few tips to help make your recording successful:
#
#Try to speak slowly and as clearly as possible.Try to limit the background noise around you.Hold your device about 4 inches from your mouth.If you experience persistent issues, try recording without headphones.