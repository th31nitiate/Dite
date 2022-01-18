#!/bin/bash
OUT=/etc/dite_pki
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/dite_pki/config
CRL=$OUT/crl
DEFAULT_DIST_NAME="/DC=re/DC=Dite Inc/O=Dite Intermediate CA"
CA_KEY=$CA/Dite_CA/private/Dite_CA.key
CA_ROOT_PATH=$CA/Dite_CA
CA_SIGNING_PATH=$CA/Intermediate_CA



mkdir -pv /etc/dite_pki
mkdir -pv /var/www/html/private
mkdir -pv /var/www/html/private/notes
mkdir -pv /opt/temp-pki-cache
mkdir -pv $CONFIG
mkdir -pv $CA_SIGNING_PATH
mkdir -pv $CA_ROOT_PATH
mkdir -pv $CA/Dite_CA/private

# configure environment so that the required tools are installed on the system
##This should only be the base requirements
##Ensure that the CA certificate is configured accordingly

echo "Disable SELinux"
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

yum install -y yum-utils

yum-config-manager \
    --enable \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
#
dnf update -y
#
dnf install -y epel-release python3-cryptography python3-pexpect.noarch python36.x86_64 python3-firewall python3-pip  epel-release python3-cryptography docker-ce python3-pexpect.noarch docker-ce-cli containerd.io open-vm-tools #python3-docker.noarch
#
echo "Install packages required for OpenEMR"
dnf install -y python36.x86_64 python3-firewall python3-pip python3-cryptography  php-mbstring mariadb-server mariadb php-xml.x86_64 python3-PyMySQL.noarch python3-libselinux.x86_64 epel-release php-json.x86_64 python3-pexpect.noarch httpd php php-mysqlnd mod_ssl
#
cp -rf /srv/hosts/pki/etc/* $CONFIG

systemctl start docker
systemctl enable docker
##
##
systemctl restart httpd
systemctl enable httpd

cp -rf /srv/hosts/config/daemon.json /etc/docker/daemon.json
#
##
### 1. Create Root CA
##
if [[ ! -e $CA_ROOT_PATH/db/Dite_CA.db ]]; then
    echo "Creating database files required for CA"
    mkdir -p $CA_ROOT_PATH/private $CA_ROOT_PATH/db $CRL $CERTS
    chmod 700 $CA_ROOT_PATH/private

    cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db
    cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db.attr
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crt.srl
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crl.srl
fi
#
export ROOT_PASSPHRASE='123456'
#
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
#
#
## 2. Create Signing CA

mkdir -p $CA_SIGNING_PATH/private $CA_SIGNING_PATH/db crl certs
chmod 700 $CA_SIGNING_PATH/private

cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db
cp /dev/null $CA_SIGNING_PATH/db/Intermediate_CA.db.attr
echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crt.srl
echo 01 > $CA_SIGNING_PATH/db/Intermediate_CA.crl.srl
#
export SIGNING_PASSPHRASE='654321'
#
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
export FRED_PASSPHRASE='a12345'
#
if [[ ! -e $CERTS/fred.p12 ]]; then

  openssl req -new \
      -passout env:FRED_PASSPHRASE \
      -subj="/DC=re/O=Dite Inc/CN=Fred Flintstone/emailAddress=fred@dite.re/" \
      -config $CONFIG/csr-email.conf \
      -out $CERTS/fred.csr \
      -keyout $CERTS/fred.key

  openssl ca \
      -batch \
      -passin env:SIGNING_PASSPHRASE \
      -config $CONFIG/ca-signing.conf \
      -in $CERTS/fred.csr \
      -out $CERTS/fred.crt \
      -extensions ext_email

  openssl pkcs12 -export \
      -passin env:FRED_PASSPHRASE \
      -passout env:FRED_PASSPHRASE \
      -name "Fred Flintstone" \
      -inkey $CERTS/fred.key \
      -in $CERTS/fred.crt \
      -out $CERTS/fred.p12

fi
#
## Create PEM bundle
#cat $CERTS/fred.key \
#    $CERTS/fred.crt \
#    > $CERTS/fred.pem
#

#
#create_certificate() {
#
#    if [[ ! -e $CERTS/$1.crt ]]; then
#        subjectAltName=$2 \
#        openssl req -new \
#            -config $CONFIG/csr-server.conf \
#            -out $CERTS/$1.csr \
#            -keyout $CERTS/$1.key \
#            -subj="$DEFAULT_DIST_NAME /CN=$1"
#
#        openssl ca \
#            -batch \
#            -config $CONFIG/ca-signing.conf \
#            -in $CERTS/$2.csr \
#            -out $CERTS/$2.crt \
#            -passin env:SIGNING_PASSPHRASE \
#            -extensions ext_server
#    fi
#}
#
#if [[ ! -e $CERTS/acreage.local.crt ]]; then
#
#    subjectAltName=DNS:acreage.dite.local\
#    openssl req -new \
#        -config $CONFIG/csr-server.conf \
#        -out $CERTS/acreage.org.csr \
#        -keyout $CERTS/acreage.org.key \
#        -subj="/DC=re/O=Dite Inc/CN=acreage.dite.local"
#
#
#    openssl ca \
#        -batch \
#        -config $CONFIG/ca-signing.conf \
#        -in $CERTS/acreage.org.csr \
#        -out $CERTS/acreage.org.crt \
#        -passin env:SIGNING_PASSPHRASE \
#        -extensions ext_server
#
#fi
#
## 3.6 Create CRL
#
openssl ca -gencrl \
    -batch \
    -config $CONFIG/ca-signing.conf \
    -out $CRL/ca-signing.crl \
    -passin env:SIGNING_PASSPHRASE
#
cp /srv/hosts/web/* /var/www/html/
#
if [[ ! -e /var/www/html/openemr-5_0_1_3 ]]; then
    curl -L http://172.16.48.181/openemr-5_0_1_3.tar.gz -o /tmp/openemr-5_0_1_3.tar.gz
    tar xvf /tmp/openemr-5_0_1_3.tar.gz -C /var/www/html/
fi

#cp /srv/hosts/config/apache2.config /etc/httpd/conf.d/ssl.conf
#
cp $CA/ca-signing-chain.pem /usr/share/pki/ca-trust-source/anchors/
#
/usr/bin/update-ca-trust
#
### Copy CA certificate to trust store on the system
#
### /usr/bin/update-ca-trust This will enable you to update the CA store
#
###Generate SSH public key

expect "Enter passphrase:"
send "654321"
/usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private//Intermediate_CA.key -y
expect "Enter passphrase:"
send "654321"

/usr/bin/expect <<EOD
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private/Intermediate_CA.key -y > /tmp/sshkey
expect "Enter passphrase:"
send "654321\n"
expect eof
EOD


/usr/bin/expect <<EOD | grep ssh-rsa > /tmp/sshfile
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private//Intermediate_CA.key -y
expect "Enter passphrase:"
send "$1\n"
expect eof
EOD




#
#/usr/bin/ssh-keygen -s $CA_SIGNING_PATH/private/Dite_Intermediate_CA.key -I 'edcbb' -z '0003' -n dockerdev $CA/dockerdev.pub
#expect "Enter passphrase:"
#send "654321"


#!/bin/bash
OUT=/etc/dite_pki
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/dite_pki/config
CRL=$OUT/crl
DEFAULT_DIST_NAME="/DC=re/DC=Dite Inc/O=Dite Intermediate CA"
CA_KEY=$CA/Dite_CA/private/Dite_CA.key
CA_ROOT_PATH=$CA/Dite_CA
CA_SIGNING_PATH=$CA/Intermediate_CA

/usr/bin/expect <<EOD
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private//Intermediate_CA.key -y
expect "Password"
send "$1\n"
expect eof
EOD