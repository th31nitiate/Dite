#!/usr/bin/env bash
set -e

#
# Note: It is assumed that the build script will be run as the root user.
#

echo "[+] Building acreage"
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

dnf install -y epel-release docker-ce docker-ce-cli containerd.io open-vm-tools expect

yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

echo "[+] Initializing base variables"
OUT=/etc/dite_pki
CA=$OUT/ca
CERTS=$OUT/certs
CONFIG=/etc/dite_pki/config
CRL=$OUT/crl
CA_KEY=$CA/Dite_CA/private/Dite_CA.key
CA_ROOT_PATH=$CA/Dite_CA
CA_SIGNING_PATH=$CA/Intermediate_CA

echo "[+] Configure base directory system"
mkdir -pv /etc/dite_pki
mkdir -pv /var/www/html/private
mkdir -pv /var/www/html/private/notes
mkdir -pv /opt/temp-cache/.pki
mkdir -pv $CONFIG
mkdir -pv $CA_SIGNING_PATH
mkdir -pv $CA_ROOT_PATH
mkdir -pv $CA/Dite_CA/private


echo "[+] Disable SELinux system configuration"
echo "Disable SELinux"ex
sed -i 's/permissive/disabled/g' /etc/selinux/config
sestatus

echo "[+] Start and enable docker"
systemctl start docker

# Ensure that the service is started
# systemctl restart docker
systemctl enable docker

# Add the docker user
useradd -G docker -u 1040 -s /bin/bash -m dockerdev

systemctl stop firewalld

echo "[+] Ensure to pull container so its present on system"
docker pull ubuntu

echo "[+] Install packages required for OpenEMR operations"
dnf install -y php-mbstring mariadb-server mariadb php-xml.x86_64 python3-PyMySQL.noarch python3-libselinux.x86_64 php-json.x86_64 httpd php php-mysqlnd mod_ssl

echo "[+] Copy HTTP Password , apache2 config and docker service file"
\cp -rf /srv/hosts/config/httppassword /etc/httpd/htpasswd

\cp -rf /srv/hosts/config/apache2.config /etc/httpd/conf.d/ssl.conf

\cp -rf /srv/hosts/config/docker.service /etc/systemd/system/multi-user.target.wants/docker.service

systemctl daemon-reload

echo "[+] Copy base HTML files"
\cp /srv/hosts/web/* /var/www/html/

echo "[+] Download OpenEMR archive and untar it in to the correct location"
if [[ ! -e /var/www/html/openemr-5_0_1_3 ]]; then
    curl -L http://192.168.56.1/openemr-5_0_1_3.tar.gz -o /tmp/openemr-5_0_1_3.tar.gz
    tar xvf /tmp/openemr-5_0_1_3.tar.gz -C /var/www/html/
fi

echo "[+] Configure permissions accordingly"
OpenEMRFiles=('sites/default/sqlconf.php' 'interface/modules/zend_modules/config/application.config.php' 'sites/default/documents' 'sites/default/edi' 'sites/default/era' 'sites/default/letter_templates' 'gacl/admin/templates_c' 'interface/main/calendar/modules/PostCalendar/pntemplates/compiled' 'interface/main/calendar/modules/PostCalendar/pntemplates/cache')

for i in "${OpenEMRFiles[@]}"; do
    chmod 0666 /var/www/html/openemr-5_0_1_3/"$i"
done


echo "[+] Configure MariaDB system"

systemctl start mariadb

systemctl enable mariadb

mysql < /srv/hosts/config/openemr_doc.sql

echo "[+] Copy PKI config to the correct location"

\cp -rf /srv/hosts/pki/etc/* $CONFIG

echo "[+] Copy web files to the correct location"

\cp -rf /srv/hosts/web/index.php /var/www/html/
\cp -rf /srv/hosts/web/background.jpg /var/www/html/
\cp -rf /srv/hosts/web/index.html /var/www/html/private/
\cp -rf /srv/hosts/web/style.css /var/www/html/private/

if [[ ! -e $CA_ROOT_PATH/db/Dite_CA.db ]]; then
    echo "[+] Creating database files required for CA"
    mkdir -p $CA_ROOT_PATH/private $CA_ROOT_PATH/db $CRL $CERTS
    chmod 700 $CA_ROOT_PATH/private

    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db
    \cp /dev/null $CA_ROOT_PATH/db/Dite_CA.db.attr
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crt.srl
    echo 01 > $CA_ROOT_PATH/db/Dite_CA.crl.srl
fi

export ROOT_PASSPHRASE='123456'

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

export SIGNING_PASSPHRASE='123456'

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

export SIGNING_PASSPHRASE='123456'

if [[ ! -e $CERTS/docker.crt ]]; then

    echo "[+] Creating docker web certificate from Intermediate CA Certificates"
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

export DOCKER_PASSPHRASE='admin'

if [[ ! -e $CERTS/dockerdev.p12 ]]; then

    echo "[+] Creating docker p12 client cert & key from Intermediate CA Certificates"
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
\cp -rf /srv/hosts/pki/id_rsa* /etc/dite_pki/

echo "[+] Generate CA trusted SSH public key"
/usr/bin/expect <<EOD | grep ssh-rsa > /etc/dite_pki/ca-ssh.pub
spawn /usr/bin/ssh-keygen -f $CA_SIGNING_PATH/private/Intermediate_CA.key -y
expect "Enter passphrase:"
send "123456\n"
expect eof
EOD

echo "[+] Generate authentication certificate for SSH key"
/usr/bin/expect <<EOD
spawn /usr/bin/ssh-keygen -s $CA_SIGNING_PATH/private/Intermediate_CA.key -I 'edcbb' -z 0003 -n root /etc/dite_pki/id_rsa.pub
expect "Enter passphrase:"
send "123456\n"
expect eof
EOD

echo "[+] Ensure to (restart, enable) httpd server server and configure (restart/enable) docker daemon service"
systemctl restart httpd
systemctl enable httpd
\cp -rf /srv/hosts/config/daemon.json /etc/docker/daemon.json
systemctl restart docker
systemctl enable docker

echo "[+] Configure SSHD service for authentication"
\cp -rf /etc/dite_pki/ca-ssh.pub /srv/hosts/pki/ca-ssh.pub
\cp -rf $CA/ca-signing-chain.pem /srv/hosts/pki/ca-signing-chain.pem
\cp -rf /srv/hosts/config/sshd_config /etc/ssh/sshd_config
systemctl restart sshd

echo "[+] Configure SSHD service for authentication"
\cp -rf $CA/ca-signing-chain.pem /opt/temp-cache/.pki/
\cp -rf $CA_SIGNING_PATH/private/Intermediate_CA.key /opt/temp-cache/.pki/
chmod o+rwx /opt/temp-cache/.pki/

echo "[+] Dropping flags"
echo "c93a7db6cef3e65eb16850dc69c24b20" > /root/proof.txt
echo "238e81ba6935e520eb5928fd03343afc" > /home//home/dockerdev/local.txt
chmod 0600 /root/proof.txt
chmod 0644 /home/dockerdev/local.txt
chown dockerdev:dockerdev /home/dylan/local.txt


echo "[+] Cleaning up"
rm -rf /root/build.sh
rm -rf /root/.cache
rm -rf /root/.viminfo
rm -rf /home/dockerdev/.sudo_as_admin_successful
rm -rf /home/dockerdev/.cache
rm -rf /home/dockerdev/.viminfo
find /var/log -type f -exec sh -c "cat /dev/null > {}" \;
