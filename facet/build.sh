#!/usr/bin/env bash
#
# If the script fails during run time then sometimes it may fail for example if a docker daemon is already configured
#
# /srv/host is assumed to a mount path which should linked to the build machine
#
# 

set -e

ACREADGE_IP=192.168.56.10
FACET_IP=192.168.56.11
DOMAIN=dite.local
TMP_CONFIG_DIR=/tmp/config
SERVER_HOSTING_OPENEMR=192.168.56.1

#https://asecuritysite.com/rsa/privatekey
# Note: It is assumed that the build script will be run as the root user.
#

echo "[+] Building facet: $FACET_IP"
echo "[+] OS: $(cat /etc/redhat-release)"
echo "[+] Author: m3rl1n th31nitiate"
echo "[+] Date: $(date)"


echo "[+] Configuring hostname"
cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.56.10 acreage.$DOMAIN
192.168.56.11 facet.$DOMAIN
EOF

#I assume the in offsec environment the files would be transfer over to
#the remote system
if grep --quiet 'vagrant' /etc/passwd; then
  echo "[+] Ensure directory file is copied to local system"
  cp /srv/hosts/$(hostname -f | cut -d. -f1)/config.zip /tmp/

  echo "[+] Ensure we chane to the correct working directory"
  cd /tmp
fi

echo "[+] Installing utilities including Docker CE"
yum install -y yum-utils python3-pip dnf unzip

dnf update -y

echo "[*] Ensure configration is unziped on the server"
unzip -o config.zip

echo "Ensure SELinux is disabled"
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

yum-config-manager \
    --enable \
    --add-repo \
    $TMP_CONFIG_DIR/docker-ce.repo

yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

dnf install -y epel-release docker-ce docker-ce-cli containerd.io open-vm-tools expect
dnf update -y sudo

export DITE_PKI_ETC=/etc/dite_pki


echo "[+] Disable SELinux system configuration"
echo "Disable SELinux"
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

echo "[+] Start and enable docker"
systemctl start docker

# Ensure that the service is started
# systemctl restart docker
systemctl enable docker

# Add the docker user, ignore incase user alreaddy exists on system
if ! grep --quiet 'dockerdev' /etc/passwd; then
  useradd -u 1040 -s /bin/bash -m dockerdev
fi

# It is ok to have firewalls enabled
systemctl stop firewalld

echo "[+] Ensure to pull container so its present on system"
docker pull ubuntu


echo "Ensure PKI directory is present on system"
mkdir -pv $DITE_PKI_ETC

if grep --quiet 'vagrant' /etc/passwd; then
  echo "[+] Ensure directory file is copied to local system"
  \cp -r /srv/hosts/facetfiles /tmp/
fi

echo "[+] Ensure docker container is downloaded and running"
#docker run -p 3434:8080 -d gcr.io/kuar-demo/kuard-amd64:blue /kuard

sleep 30

echo "[+] Ensure to move the config files to the correct locations"
\cp -rf /tmp/facetfiles/ca-ssh.pub /etc/dite_pki/
\cp -rf /tmp/facetfiles/ca-signing-chain.pem /etc/dite_pki/

\cp -rf $TMP_CONFIG_DIR/sshd_config /etc/ssh/sshd_config
\cp -rf /etc/dite_pki/ca-signing-chain.pem /usr/share/pki/ca-trust-source/anchors/

/bin/update-ca-trust extract

systemctl restart sshd

echo "[+] Ensure to move the config files to the correct locations"
\cp -rf $TMP_CONFIG_DIR/docker_sudoers /etc/sudoers.d

#Add the docker daemon alias alias docker command to be able to login correctly.
if ! grep --quiet 'docker' /home/dockerdev/.bashrc; then
  echo 'alias docker="sudo docker"' >> /home/dockerdev/.bashrc
  echo 'export PATH=$HOME/bin:$PATH' >> /home/dockerdev/.bashrc
  mkdir -pv /home/dockerdev/bin

  cat <<EOF > /home/dockerdev/bin/docker
#!/bin/bash
/usr/bin/sudo /usr/bin/docker $1 $2
EOF

  chown root:root -R /home/dockerdev/bin
  chmod 665 /home/dockerdev/bin/docker

fi


echo "[+] Dropping flags"
echo "0da7106266afe38c958dfb326dc00816" > /root/proof.txt
echo "e88ed1b0b134d95172950b2c808a2dc4" > /home/dockerdev/local.txt
chmod 0600 /root/proof.txt
chmod 0644 /home/dockerdev/local.txt
chown dockerdev:dockerdev /home/dockerdev/local.txt

echo "[+] Cleaning up"
rm -rf /root/build.sh
rm -rf /root/.cache
rm -rf /root/.viminfo
rm -rf /home/dockerdev/.sudo_as_admin_successful
rm -rf /home/dockerdev/.cache
rm -rf /home/dockerdev/.viminfo
rm -rf /tmp/config
find /var/log -type f -exec sh -c "cat /dev/null > {}" \;

unset DITE_PKI_ETC
unset CA
unset CERTS
unset CONFIG
unset CRL
unset CA_ROOT_PATH
unset CA_KEY
unset CA_SIGNING_PATH
unset DOCKER_PASSPHRASE
unset ROOT_PASSPHRASE
unset SIGNING_PASSPHRASE
