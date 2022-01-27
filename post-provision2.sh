#!/bin/bash
## Create the required base directories
mkdir -pv /etc/dite_pki

# Configure environment so that the required tools are installed on the system
# This should only be the base requirements
# Ensure that the CA certificate is configured accordingly

echo "[+] Building face"
echo "[+] OS: CentOS 8"
echo "[+] Author: m3rl1n th31nitiate"
echo "[+] Date: $(date)"

echo "[+] Configuring hostname"
cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.56.10 acreage.dite.local
192.168.56.11 facet.dite.local
EOF

echo "[+] Installing utilities including Docker CE"
yum install -y yum-utils

echo "Disable SELinux"
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

yum-config-manager \
    --enable \
    --add-repo \
    /srv/hosts/config/docker-ce.repo


systemctl stop firewalld


dnf update -y sudo

dnf install -y epel-release docker-ce docker-ce-cli containerd.io open-vm-tools


echo "[+] Enable docker service"
systemctl start docker
systemctl enable docker

echo "[+] Ensure the dockerdev user is present"
useradd -u 1040 -s /bin/bash -m dockerdev

echo "[+] Ensure docker container is downloaded and running"
docker run -p 3434:8080 -d gcr.io/kuar-demo/kuard-amd64:blue /kuard

sleep 30

echo "[+] Ensure to move the config files to the correct locations"
\cp -rf /srv/hosts/pki/ca-ssh.pub /etc/dite_pki/
\cp -rf /srv/hosts/pki/ca-signing-chain.pem /etc/dite_pki/

\cp -rf /srv/hosts/config/sshd_config /etc/ssh/sshd_config
\cp -rf /srv/hosts/pki/ca-signing-chain.pem /usr/share/pki/ca-trust-source/anchors/

/bin/update-ca-trust extract

systemctl restart sshd

echo "[+] Ensure to move the config files to the correct locations"
\cp -rf /srv/hosts/config/docker_sudoers /etc/sudoers.d

echo "[+] Dropping flags"
echo "3f15318374adb8600ba3e3b48681370d" > /root/proof.txt
echo "238e81ba6935e520eb5928fd03343afc" > /home//home/dockerdev/local.txt
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
find /var/log -type f -exec sh -c "cat /dev/null > {}" \;
