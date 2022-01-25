#!/bin/bash

## Configure shell variables
OUT=/etc/dite_pki
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/dite_pki/config
CRL=$OUT/crl
DEFAULT_DIST_NAME="/DC=re/DC=Dite Inc/O=Dite Intermediate CA"
CA_KEY=$CA/Dite_CA/private/Dite_CA.key
CA_ROOT_PATH=$CA/Dite_CA
CA_SIGNING_PATH=$CA/Intermediate_CA

#### CA passwords
export SIGNING_PASSPHRASE='654321'
export ROOT_PASSPHRASE='123456'

## Create the required base directories
mkdir -pv /etc/dite_pki
mkdir -pv /var/www/html/private
mkdir -pv /var/www/html/private/notes
mkdir -pv /opt/temp-pki-cache
mkdir -pv $CONFIG
mkdir -pv $CA_SIGNING_PATH
mkdir -pv $CA_ROOT_PATH
mkdir -pv $CA/Dite_CA/private

## This should only be the base requirements
# #Ensure that the CA certificate is configured accordingly


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

#dnf update -y

dnf install -y epel-release docker-ce docker-ce-cli containerd.io open-vm-tools expect

systemctl start docker

# Ensure that the service is started
# systemctl restart docker
systemctl enable docker

# Add the docker user
useradd -G docker -u 1040 -s /bin/bash -m dockerdev

## ~Install http packages and configuration as required
echo "Install packages required for OpenEMR operations"
dnf install -y php-mbstring mariadb-server mariadb php-xml.x86_64 python3-PyMySQL.noarch python3-libselinux.x86_64 php-json.x86_64 httpd php php-mysqlnd mod_ssl

\cp -rf /srv/hosts/config/httppassword /etc/httpd/htpasswd

\cp -rf /srv/hosts/config/apache2.config /etc/httpd/conf.d/ssl.conf

\cp -rf /srv/hosts/config/docker.service /etc/systemd/system/multi-user.target.wants/docker.service

systemctl daemon-reload
\cp /srv/hosts/web/* /var/www/html/

## Download the OpenEMR packaging system

if [[ ! -e /var/www/html/openemr-5_0_1_3 ]]; then
    curl -L http://192.168.56.1/openemr-5_0_1_3.tar.gz -o /tmp/openemr-5_0_1_3.tar.gz
    tar xvf /tmp/openemr-5_0_1_3.tar.gz -C /var/www/html/
fi

OpenEMRFiles=('sites/default/sqlconf.php' 'interface/modules/zend_modules/config/application.config.php' 'sites/default/documents' 'sites/default/edi' 'sites/default/era' 'sites/default/letter_templates' 'gacl/admin/templates_c' 'interface/main/calendar/modules/PostCalendar/pntemplates/compiled' 'interface/main/calendar/modules/PostCalendar/pntemplates/cache')

systemctl start mariadb

for i in "${OpenEMRFiles[@]}"; do
    chmod 0666 /var/www/html/openemr-5_0_1_3/"$i"
done

### Provision database as intended
mysql < /srv/hosts/config/openemr_doc.sql

## Copy base config files and HTML images
\cp -rf /srv/hosts/pki/etc/* $CONFIG

\cp -rf /srv/hosts/web/index.php /var/www/html/
\cp -rf /srv/hosts/images/background.jpg /var/www/html/
\cp -rf /srv/hosts/web/index.html /var/www/html/private/
\cp -rf /srv/hosts/web/style.css /var/www/html/private/

### 1. Create Root CA

if [[ ! -e $CA_ROOT_PATH/db/Dite_CA.db ]]; then
    echo "Creating database files required for CA"
    mkdir -p $CA_ROOT_PATH/private $CA_ROOT_PATH/db $CRL $CERTS
    chmod 700 $CA_ROOT_PATH/private

    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db
    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db.attr
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crt.srl
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crl.srl
fi

if [[ ! -e $CA/Dite_CA.crt ]]; then

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

## 2. Create Signing CA

if [[ ! -e $CA_SIGNING_PATH/db/Intermediate_CA.db ]]; then

    echo "Creating database files required for CA"
    mkdir -p $CA_SIGNING_PATH/private $CA_SIGNING_PATH/db crl certs
    chmod 700 $CA_SIGNING_PATH/private

    \cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db
    \cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db.attr
    echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crt.srl
    echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crl.srl
fi

if [[ ! -e $CA_SIGNING_PATH/Intermediate_CA.crt ]]; then

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

### 3.2. server

if [[ ! -e $CERTS/web.crt ]]; then

  subjectAltName="DNS:acreage.dite.local DNS:dite.local IP:192.168.56.10" \
  openssl req -new \
      -config $CONFIG/csr-server.conf \
      -out $CERTS/web.csr \
      -keyout $CERTS/web.key \
      -subj="/DC=re/O=Dite Inc/CN=acreage.dite.local"


  openssl ca \
      -batch \
      -config $CONFIG/ca-signing.conf \
      -in $CERTS/web.csr \
      -out $CERTS/web.crt \
      -passin env:SIGNING_PASSPHRASE \
      -extensions ext_server

fi

if [[ ! -e $CERTS/docker.crt ]]; then

  subjectAltName="DNS:docker.acreage.dite.local DNS:acreage.dite.local IP:192.168.56.10" \
  openssl req -new \
      -config $CONFIG/csr-server.conf \
      -out $CERTS/docker.csr \
      -keyout $CERTS/docker.key \
      -subj="/DC=re/O=Dite Inc/CN=docker.acreage.dite.local"


  openssl ca \
      -batch \
      -config $CONFIG/ca-signing.conf \
      -in $CERTS/docker.csr \
      -out $CERTS/docker.crt \
      -passin env:SIGNING_PASSPHRASE \
      -extensions ext_server

fi

#
## 3. Operate Signing CA
#
### 3.1. e-mail
#
export DOCKER_PASSPHRASE='a12345'
#
if [[ ! -e $CERTS/dockerdev.p12 ]]; then

  openssl req -new \
      -passout env:DOCKER_PASSPHRASE \
      -subj="/DC=re/O=Dite Inc/CN=Docker Development/emailAddress=dockerdev@dite.re/" \
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


openssl ca -gencrl \
    -batch \
    -config $CONFIG/ca-signing.conf \
    -out $CRL/ca-signing.crl \
    -passin env:SIGNING_PASSPHRASE
#

#\cp -rf /srv/hosts/config/apache2.config /etc/httpd/conf.d/ssl.conf
#
\cp $CA/ca-signing-chain.pem /usr/share/pki/ca-trust-source/anchors/
#
/usr/bin/update-ca-trust

\cp -rf $CA/ca-signing-chain.pem /var/www/html/private
\cp -rf $CERTS/dockerdev.p12 /var/www/html/private

#
### Copy CA certificate to trust store on the system
#
### /usr/bin/update-ca-trust This will enable you to update the CA store
#
###Generate SSH public key

\cp -rf /srv/hosts/pki/id_rsa* /etc/dite_pki/

/usr/bin/expect <<EOD | grep ssh-rsa > /etc/dite_pki/ca-ssh.pub
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private/Intermediate_CA.key -y
expect "Enter passphrase:"
send "654321\n"
expect eof
EOD

/usr/bin/expect <<EOD
spawn /usr/bin/ssh-keygen -s $CA_SIGNING_PATH/private/Intermediate_CA.key -I 'edcbb' -z 0003 -n root /etc/dite_pki/id_rsa.pub
expect "Enter passphrase:"
send "654321\n"
expect eof
EOD

\cp -rf /srv/hosts/pki/id_rsa* /etc/dite_pki/

systemctl restart httpd
systemctl enable httpd
\cp -rf /srv/hosts/config/daemon.json /etc/docker/daemon.json
systemctl restart docker
systemctl enable docker

\cp -rf /etc/dite_pki/ca-ssh.pub /srv/hosts/pki/ca-ssh.pub
\cp -rf $CA/ca-signing-chain.pem /srv/hosts/pki/ca-signing-chain.pem
systemctl restart sshd





#\cp -rf /srv/hosts/config/docker_sudoers /etch/sudoers.d

#A few tips to help make your recording successful:
#
#Try to speak slowly and as clearly as possible.Try to limit the background noise around you.Hold your device about 4 inches from your mouth.If you experience persistent issues, try recording without headphones.