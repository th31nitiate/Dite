#!/usr/bin/env bash
#
#It is assumed that the shared folder between system in  configuration will be /srv/hosts
#This folder could be mounted via NFS or another network file share system acceable from both systems
#


set -e

ACREADGE_IP=192.168.56.10
FACET_IP=192.168.56.11
DOMAIN=dite.local
TMP_CONFIG_DIR=/tmp/config
SERVER_HOSTING_OPENEMR=192.168.56.1

# https://asecuritysite.com/rsa/privatekey
# Note: It is assumed that the build script will be run as the root user.


echo "[+] Building facet: $ACREADGE_IP"
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



## This seems like a bit of mess though it should be fine
echo "[+] Initializing base variables"
export DITE_PKI_ETC=/etc/dite_pki
export CA=$DITE_PKI_ETC/ca
export CERTS=$DITE_PKI_ETC/certs
export CONFIG=$DITE_PKI_ETC/config
export CRL=$DITE_PKI_ETC/crl
export CA_ROOT_PATH=$CA/Dite_CA
export CA_KEY=$CA_ROOT_PATH/private/Dite_CA.key
export CA_SIGNING_PATH=$CA/Intermediate_CA
export DOCKER_PASSPHRASE='admin'
export SIGNING_PASSPHRASE='123456'
export ROOT_PASSPHRASE='123456'

echo "[+] Configure base directory system"
mkdir -pv $DITE_PKI_ETC
mkdir -pv /var/www/html/private/notes
mkdir -pv /opt/temp-cache/.pki
mkdir -pv $CONFIG
mkdir -pv $CA_SIGNING_PATH
mkdir -pv $CA_ROOT_PATH/private

echo "[*] Install remi repos to ensure we have the correct packages"
#This repositry seems to safe to use in some instances
dnf install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y

echo "[+] Update DNF packages on the remote system"
dnf update -y

yum-config-manager --enable remi-php56

echo "[+] Install packages required for OpenEMR operations"
dnf install -y php-mbstring mariadb-server mariadb php-xml.x86_64 python36-PyMySQL.noarch libselinux-python3.x86_64 php-JsonSchema.noarch php-jsonlint.noarch httpd php php-mysqlnd mod_ssl


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

echo "[+] Copy HTTP Password , apache2 config and docker service file"
\cp -rf $TMP_CONFIG_DIR/httppassword /etc/httpd/htpasswd

\cp -rf $TMP_CONFIG_DIR/apache2.config /etc/httpd/conf.d/ssl.conf

\cp -rf $TMP_CONFIG_DIR/docker.service /etc/systemd/system/multi-user.target.wants/docker.service

#Ensure to add docker user to the correct to correct group
usermod -G docker -a dockerdev

systemctl daemon-reload

echo "[+] Copy base HTML files"
\cp $TMP_CONFIG_DIR/web/* /var/www/html/

echo "[+] Download OpenEMR archive and untar it in to the correct location"
if [[ ! -e /var/www/html/openemr-5_0_1_3 ]]; then
    curl -L http://$SERVER_HOSTING_OPENEMR/openemr-5_0_1_3.tar.gz -o /tmp/openemr-5_0_1_3.tar.gz
    tar xvf /tmp/openemr-5_0_1_3.tar.gz -C /var/www/html/
fi

echo "[*] Fix time and date issue with the apache2 server config"
sed -i 's/;date.timezone =/date.timezone = Europe\/london/g' /etc/php.ini

echo "[+] Configure permissions accordingly"
OpenEMRFiles=('sites/default/sqlconf.php' 'interface/modules/zend_modules/config/application.config.php' 'sites/default/documents' 'sites/default/edi' 'sites/default/era' 'sites/default/letter_templates' 'gacl/admin/templates_c' 'interface/main/calendar/modules/PostCalendar/pntemplates/compiled' 'interface/main/calendar/modules/PostCalendar/pntemplates/cache')

for i in "${OpenEMRFiles[@]}"; do
    chmod 0666 /var/www/html/openemr-5_0_1_3/"$i"
done

echo "[+] Configure MariaDB system"
systemctl start mariadb

systemctl enable mariadb

mysql < $TMP_CONFIG_DIR/openemr_doc.sql

echo "[+] Copy PKI config to the correct location"

\cp -rf $TMP_CONFIG_DIR/pki/etc/* $CONFIG

echo "[+] Copy web files to the correct location"

\cp -rf /tmp/config/web/index.php /var/www/html/
\cp -rf /tmp/config/web/background.jpg /var/www/html/
\cp -rf /tmp/config/web/index.html /var/www/html/private/
\cp -rf /tmp/config/web/style.css /var/www/html/private/

if [[ ! -e $CA_ROOT_PATH/db/Dite_CA.db ]]; then
    echo "[+] Creating database files required for CA"
    mkdir -p $CA_ROOT_PATH/private $CA_ROOT_PATH/db $CRL $CERTS
    chmod 700 $CA_ROOT_PATH/private

    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db
    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db.attr
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crt.srl
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crl.srl
fi

if [[ ! -e $CA/Dite_CA.crt ]]; then

    echo "[+] Creating base Root CA Certificates"
    openssl req -new \
        -passout env:ROOT_PASSPHRASE \
        -config $CONFIG/ca-root.conf \
        -out $CA/ca-root.csr \
        -keyout $CA_KEY

    openssl ca -selfsign \
        -batch \
        -passin env:ROOT_PASSPHRASE \
        -config $CONFIG/ca-root.conf \
        -in $CA/ca-root.csr \
        -out $CA/Dite_CA.crt \
        -extensions ext_ca_root
fi

if [[ ! -e $CA_SIGNING_PATH/db/Intermediate_CA.db ]]; then

    echo "Creating database files required for Intermediate CA"
    mkdir -p $CA_SIGNING_PATH/private $CA_SIGNING_PATH/db crl certs
    chmod 700 $CA_SIGNING_PATH/private

    \cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db
    \cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db.attr
    echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crt.srl
    echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crl.srl
fi

if [[ ! -e $CA_SIGNING_PATH/Intermediate_CA.crt ]]; then

    echo "[+] Creating Intermediate CA Certificates"
    openssl req -new \
        -passout env:SIGNING_PASSPHRASE \
        -config $CONFIG/ca-signing.conf \
        -out $CA_SIGNING_PATH/Intermediate_CA.csr \
        -keyout $CA_SIGNING_PATH/private/Intermediate_CA.key

    openssl ca \
        -batch \
        -passin env:ROOT_PASSPHRASE \
        -config $CONFIG/ca-root.conf \
        -in $CA_SIGNING_PATH/Intermediate_CA.csr \
        -out $CA/Intermediate_CA.crt \
        -extensions ext_ca_signing

    cat $CA/Intermediate_CA.crt \
        $CA/Dite_CA.crt \
        > $CA/ca-signing-chain.pem

fi

if [[ ! -e $CERTS/web.crt ]]; then

    echo "[+] Creating web certificate from Intermediate CA Certificates"
    subjectAltName="DNS:acreage.$DOMAIN, IP:$ACREADGE_IP, IP:127.0.0.1" \
    openssl req -new \
        -config $CONFIG/csr-server.conf \
        -out $CERTS/web.csr \
        -keyout $CERTS/web.key \
        -subj "/DC=re/O=Dite Inc/CN=acreage"

    openssl ca \
        -batch \
        -config $CONFIG/ca-signing.conf \
        -in $CERTS/web.csr \
        -out $CERTS/web.crt \
        -passin env:SIGNING_PASSPHRASE \
        -extensions ext_server

fi

if [[ ! -e $CERTS/docker.crt ]]; then

    echo "[+] Creating docker web certificate from Intermediate CA Certificates"
    subjectAltName="DNS:docker.acreage.$DOMAIN, DNS:acreage.$DOMAIN, IP:$ACREADGE_IP, IP:127.0.0.1" \
    openssl req -new \
        -config $CONFIG/csr-server.conf \
        -out $CERTS/docker.csr \
        -keyout $CERTS/docker.key \
        -subj "/DC=re/O=Dite Inc/CN=docker.acreage.$DOMAIN"

    openssl ca \
        -batch \
        -config $CONFIG/ca-signing.conf \
        -in $CERTS/docker.csr \
        -out $CERTS/docker.crt \
        -passin env:SIGNING_PASSPHRASE \
        -extensions ext_server

fi

if [[ ! -e $CERTS/dockerdev.p12 ]]; then

    echo "[+] Creating docker p12 client cert & key from Intermediate CA Certificates"
    openssl req -new \
        -passout env:DOCKER_PASSPHRASE \
        -subj "/DC=re/O=Dite Inc/CN=Docker Development/emailAddress=dockerdev@dite.re/" \
        -config $CONFIG/csr-email.conf \
        -out $CERTS/dockerdev.csr \
        -keyout $CERTS/dockerdev.key

    openssl ca \
        -batch \
        -passin env:SIGNING_PASSPHRASE \
        -config $CONFIG/ca-signing.conf \
        -in $CERTS/dockerdev.csr \
        -out $CERTS/dockerdev.crt \
        -extensions ext_email

    openssl pkcs12 -export \
        -passin env:DOCKER_PASSPHRASE \
        -passout env:DOCKER_PASSPHRASE \
        -name "Docker Development" \
        -inkey $CERTS/dockerdev.key \
        -in $CERTS/dockerdev.crt \
        -out $CERTS/dockerdev.p12

fi

echo "[+] Generate certificate revocation list"
openssl ca -gencrl \
    -batch \
    -config $CONFIG/ca-signing.conf \
    -out $CRL/ca-signing.crl \
    -passin env:SIGNING_PASSPHRASE

\cp $CA/ca-signing-chain.pem /usr/share/pki/ca-trust-source/anchors/

/usr/bin/update-ca-trust

echo "[+] Generate certificate revocation list"
\cp -rf $CA/ca-signing-chain.pem /var/www/html/private/notes/
\cp -rf $CERTS/dockerdev.p12 /var/www/html/private/notes/

echo "[+] Prepare authentication keys though not entirely required"
\cp -rf /tmp/config/pki/id_rsa* /etc/dite_pki/

echo "[+] Ensure the intermediate CA key has the right configuration"
chmod 0600 $CA_SIGNING_PATH/private/Intermediate_CA.key

echo "[+] Generate CA trusted SSH public key"
/usr/bin/expect -c "
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private/Intermediate_CA.key -y
expect \"Enter passphrase:\"
send \"$SIGNING_PASSPHRASE\n\"
expect eof" | grep ssh-rsa > /etc/dite_pki/ca-ssh.pub

echo "[+] Generate authentication certificate for SSH key" #We make an incorrect key so user is to generate one with intermediate key
/usr/bin/expect -c "
spawn /usr/bin/ssh-keygen -s $CA_SIGNING_PATH/private/Intermediate_CA.key -I 'edcbb' -z 0003 -n root /etc/dite_pki/id_rsa.pub
expect \"Enter passphrase:\"
send \"$SIGNING_PASSPHRASE\n\"
expect eof"

echo "[+] Ensure to (restart, enable) httpd server server and configure (restart/enable) docker daemon service"
systemctl restart httpd
systemctl enable httpd
\cp -rf $TMP_CONFIG_DIR/daemon.json /etc/docker/daemon.json
systemctl restart docker
systemctl enable docker

echo "[+] Configure SSHD service for authentication and export public key"
\mkdir /tmp/facetfiles
\cp -rf /etc/dite_pki/ca-ssh.pub /tmp/facetfiles/ca-ssh.pub
\cp -rf $CA/ca-signing-chain.pem /tmp/facetfiles/ca-signing-chain.pem
\cp -rf $TMP_CONFIG_DIR/sshd_config /etc/ssh/sshd_config
systemctl restart sshd

echo "[+] Configure SSHD service for authentication"
\cp -rf $CA/ca-signing-chain.pem /opt/temp-cache/.pki/
\cp -rf $CA_SIGNING_PATH/private/Intermediate_CA.key /opt/temp-cache/.pki/
chmod o+rw /opt/temp-cache/.pki/

find /etc/dite_pki/ -name '*.key' ! -name 'dockerdev.key' -exec chmod 0640  {} \;

if grep --quiet 'vagrant' /etc/passwd; then
  echo "[+] Ensure directory file is copied to local system"
  \cp -r /tmp/facetfiles /srv/hosts/
fi

echo "[+] Dropping flags"
echo "c93a7db6cef3e65eb16850dc69c24b20" > /root/proof.txt
echo "238e81ba6935e520eb5928fd03343afc" > /home/dockerdev/local.txt
chmod 0600 /root/proof.txt
chmod 0644 /home/dockerdev/local.txt
chown dockerdev:dockerdev /home/dockerdev/local.txt

echo "[+] Ensure to transfer the files stored in /tmp/facetfiles"

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
