–	One scrinario is using ssl in order to generate custom certificates on a system
–	This certificate can then be used to authenticate to a remote docker instance
–	Run a vulnrable application container with vulnarable code mimic aacreageloper workstation
–	Authenticate to vulnrable sockets
–	Virtual hosts brute forcing
–	Effective git enumiration and exploitation
–	Multi account priviledge escalation 

In order for the system to funcation correctly. We want to test the users ability to understand how to use ssh keys in order to authenticate to a remote systemsincluding local ones. To enable the understanding of how TLS certificates work and general PKI.


web server which requires TLS authentication. Possibly hardended cipher. Include attribute based authentication. HTTP password based authentication. A few certificates to ensure attributes are identified. Then a exploitable web application.

- Going to need
- CA Certificate
- Intermididita CA for ssh keys
    - ssh keys for user one
    - ssh keys for host two
- Intermediate CA for services
    - web server certs
    - docker daemon certs


refactor install by adding the following:

  <Directory "/var/www/html/openemr-5_0_1_3">
      AllowOverride FileInfo
  </Directory>
  <Directory "/var/www/html/openemr-5_0_1_3/sites">
      AllowOverride None
  </Directory>
  <Directory "/var/www/html/openemr-5_0_1_3/sites/*/documents">
      order deny,allow
      Deny from all
  </Directory>
  <Directory "/var/www/html/openemr-5_0_1_3/sites/*/edi">
      order deny,allow
      Deny from all
  </Directory>
  <Directory "/var/www/html/openemr-5_0_1_3/sites/*/era">
      order deny,allow
      Deny from all
  </Directory>



Host 192.168.56.10
        Hostname 192.168.56.10
        User vagrant
        IdentitiesOnly yes
        IdentityFile /home/vagrant/.ssh/id_ssh_rsa
        CertificateFile /home/vagrant/.ssh/id_ssh_rsa-cert.pub
        ControlMaster     auto
        ControlPath       ~/.ssh/control-%C
        ControlPersist    yes


maybe privesc to a user with access to the docker domain


https://www.exploit-db.com/exploits/45161

Enumiration of local system for general information including avalible pki dirs

- Add a few user accounts

Generate or find tls keys to use with docker.  Authenticate to dockers local system. Import the container and run it. Run locally avalible container.

Use tls client certificate on a remote system via host option to run a container. Enumirate the host main via the docker host. Purpose enumirate sshd config. In order to find ssh keys including certificates required to authenticate and cipher information that might be needed.

-acreageelop authentication information 


Explore priviledge escalation oppertunities


add ips ssh to defgault port

The purpose of this is to perform & teach the way in which PKI can be used and also comprimised. 

Enusre to add security information that can be enumirable in order to allow the attack to understand how to use various attributes.



Enumirate users via docker to find system configurations that can be used for host based authentication

From docker it could be good to enumirate the host system via 
git server is whole diffirent system


    1  ls
    2  cat /etc/ssh/ssh_config.d/05-redhat.conf 
    3  cat /etc/ssh/ssh_config.d/sshd_config.config 
    4  sudo cat /etc/ssh/ssh_config.d/sshd_config.config 
    5  exit
    6  yum search docker
    7  sudo yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
    8  sudo yum install docker-ce docker-ce-cli containerd.io
    9  docker 
   10  docker run --help
   11  docker 
   12  docker --help
   13  history 

[vagrant@dev ~]$ sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 10.3.28-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE DATABASE openemr;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> CREATE USER 'openemr_user'@'localhost' IDENTIFIED BY 'PASSWORD';
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON openemr.* TO 'openemr_user'@'localhost';
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> exit


[root@dev vagrant]# history 
    1  cp -r /tmp/openemr-5_0_1_3/ /var/www/html/openerm
    2  chmod 666 -R /var/www/html/openerm/interface/
    3  chmod 666 -R /var/www/html/openerm/sites/
    4  ls -al /var/www/html/openerm/
    5  ls -al /var/www/html/openerm/sites/
    6  ls -al /var/www/html/openerm/sites/default/
    7  systemctl restart apache2
    8  systemctl restart httpd
    9  ls /var/www/html/
   10  cat /var/log/httpd/access_log .
   11  cat /var/log/httpd/error_log 
   12  rm -rf /var/www/html/openerm/
   13  cp -r /tmp/openemr-5_0_1_3/ /var/www/html/openerm
   14  chmod 666 /var/www/html/openerm/sites/default/sqlconf.php
   15  chmod 666 /var/www/html/openerm/interface/modules/zend_modules/config/application.config.php
   16  ls -al /var/www/html/openerm/sites/default/sqlconf.php
   17  systemctl restart http
   18  ls -al /var/www/html/openerm/sites/default/
   19  vi /etc/selinux/config 
   20  sestatus 
   21  reboot
   22  car /var/log/httpd/access_log 
   23  tail /var/log/httpd/access_log 
   24  cat /var/log/php-fpm/error.log 
   25  cat /var/log/php-fpm/www-error.log 
   26* chmod 666 -R /var/www/html/openerm/interface/
   27  yum search php json
   28  yum install php-json
   29  history 


[vagrant@dev ~]$ history 
    1  cp -r /tmp/openemr-5_0_1_3/ /var/www/html/opememr
    2  sudo cp -r /tmp/openemr-5_0_1_3/ /var/www/html/opememr
    3  nano /var/www/html/phpinfo.php
    4  vim /var/www/html/phpinfo.php
    5  vi /var/www/html/phpinfo.php
    6  sudo vi /var/www/html/phpinfo.php
    7  systemctl start httpd
    8  sudo systemctl start httpd
    9  sudo systemctl status httpd
   10  q
   11  ifconfig
   12  ip addr
   13  iptables -L
   14  sudo iptables -L
   15  systemctl status firewalld
   16  sudo systemctl stop firewalld
   17  curl localhost
   18  ls /vagrant/
   19  ls /var/www/html/
   20  yum search php xml
   21  yum install php-xml 
   22  sudo yum install php-xml 
   23  systemctl status apache2
   24  systemctl status apache
   25  systemctl status httpd
   26  systemctl restart httpd
   27  sudo systemctl restart httpd
   28  sudo systemctl status httpd
   29  yum search php mb_string
   30  yum search mb_string
   31  sudo nano /etc/yum.repos.d/CentOS-Base.repo
   32  sudo nano /etc/yum.repos.d/CentOS-Linux-BaseOS.repo 
   33  sudo vi /etc/yum.repos.d/CentOS-Linux-BaseOS.repo 
   34  yum search epel
   35  sudo yum install epel-release
   36  yum update
   37  sudo yum search php
   38  yum search php mb_string
   39  dnf 
   40  dnf search php-mbstring
   41  dnf install php-mbstring
   42  sudo dnf install php-mbstring
   43  systemctl restart httpd
   44  sudo systemctl restart httpd
   45  sudo chmod o+rw -R /var/www/html/opememr/
   46  sudo chmod 666 -R /var/www/html/opememr/
   47  ls -al /var/www/html/
   48  ls -al /var/www/html/opememr/
   49  ls
   50  ls -al 
   51  ls -al /tmp/
   52  rm -rf /var/www/html/opememr/
   53  sudo rm -rf /var/www/html/opememr/
   54  sudo su 
   55  sudo systemctl status httpd
   56  sudo systemctl start httpd
   57  sestatus 
   58  sudo chmod 666 -R /var/www/html/openerm/sites/default/documents
   59  sudo chmod 666 -R /var/www/html/openerm/sites/default/edi
   60  sudo chmod 666 -R /var/www/html/openerm/sites/default/era
   61  sudo chmod 666 -R /var/www/html/openerm/sites/default/letter_templates
   62  sudo chmod 666 -R /var/www/html/openerm/gacl/admin/templates_c
   63  sudo chmod 666 -R /var/www/html/openerm/interface/main/calendar/modules/PostCalendar/pntemplates/compiled
   64  sudo chmod 666 -R /var/www/html/openerm/interface/main/calendar/modules/PostCalendar/pntemplates/cache
   65  sudo systemctl status mysql
   66  sudo systemctl status mysqld
   67  sudo systemctl status mariadb
   68  sudo systemctl start mariadb
   69  sudo mysql
   70  systemctl restart httpd
   71  sudo systemctl restart httpd
   72  curl localhost
   73  curl localhost/openemr
   74  curl localhost/openerm
   75  curl -L localhost/openerm
   76  ls /var/log/httpd/
   77  sudo ls /var/log/httpd/
   78  ls /var/log/httpd/
   79  sudo su 
   80  history


Ansible playbook
–	Create user account, random idealy
–	Install docker and required dependcies
–	Install nginx and required modules
-   Install yum repo https://download.docker.com/linux/centos/docker-ce.repo


docker -D -H "192.168.56.10:5555" --tlsverify --tlscacert=/etc/pki/o3h_certs/ca-docker.pem --tlscert=/etc/pki/o3h_certs/certificate-client.pem --tlskey=/etc/pki/o3h_certs/certificate-client.key -l debug version
exit

Ensure to deploy a contianer so that it can be used

Disable docker sudo and enable ssh auth with cert

Run kurd app on with http based auth



======

In order to build the system it might be requirement to edit the config file to suite your5 local enviuronemnts requirement.
In this instance we are going to use vagrant. This is a system that can be used for configuration managent mainly focused towards localacreageelopment. We also use ansible for system configuration since it is pretty simple tool to get get aquantited with.

Weacreageelop use the machine centos 8. This system is to be configured to run a web application and some service required to for the teaching assisment.

The build steps are pretty simple to follow when reviewing the ansible playbook.

It is possible either use a ISO system in order to provision and test the config or alternatively use vagrant then port to your local environment.

If you choose to use vagrant you can do the following. Run the system with --no-provision. This should bring both system up at which point it should be possible to run provision which should detect all systems.

Once this run is done which is a bit messy at the momment it is then possible to perform  start performing systems configuration. We start by configuring the currenlty existing web application.

The process is pretty straight forwards it involves configuring the database and then vulnrable application feature. I believe once this is done all what is required is to disable the http interface of the system. Since mostly the application would be access by https.

That is pretty much it for system. The application initial interface would be the https interface.




                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$ curl --cert http-client.pem --cert-type PEM --key http-client.key --key-type PEM https://192.168.56.10/openemr-5_0_1_3/ -vvvv                                                                  56 ⨯
*   Trying 192.168.56.10:443...
* Connected to 192.168.56.10 (192.168.56.10) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$ curl --cert http-client.pem --cert-type PEM --key http-client.key --key-type PEM https://192.168.56.10/openemr-5_0_1_3/ -vvvv                                                                  60 ⨯
*   Trying 192.168.56.10:443...
* Connected to 192.168.56.10 (192.168.56.10) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$ curl --cert http-client.pem --cert-type PEM --key http-client.key --key-type PEM https://192.168.56.10/openemr-5_0_1_3/ --cacert ca.pem -vvvv                                                  60 ⨯
*   Trying 192.168.56.10:443...
* Connected to 192.168.56.10 (192.168.56.10) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: ca.pem
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: CN=acreage
*  start date: Dec 12 02:18:32 2021 GMT
*  expire date: Dec 13 02:18:32 2022 GMT
*  subjectAltName: host "192.168.56.10" matched cert's IP address!
*  issuer: CN=Dite Intermediate http CA
*  SSL certificate verify ok.
> GET /openemr-5_0_1_3/ HTTP/1.1
> Host: 192.168.56.10
> User-Agent: curl/7.79.1
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, CERT verify (15):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* TLSv1.3 (IN), TLS alert, internal error (592):
* OpenSSL SSL_read: error:14094438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error, errno 0
* Closing connection 0
curl: (56) OpenSSL SSL_read: error:14094438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error, errno 0
                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$ curl --cert http-client.pem --cert-type PEM --key http-client.key --key-type PEM https://192.168.56.10/openemr-5_0_1_3/ --cacert ca.pem -vvvv                                                  56 ⨯
*   Trying 192.168.56.10:443...
* Connected to 192.168.56.10 (192.168.56.10) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: ca.pem
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: CN=acreage
*  start date: Dec 12 02:18:32 2021 GMT
*  expire date: Dec 13 02:18:32 2022 GMT
*  subjectAltName: host "192.168.56.10" matched cert's IP address!
*  issuer: CN=Dite Intermediate http CA
*  SSL certificate verify ok.
> GET /openemr-5_0_1_3/ HTTP/1.1
> Host: 192.168.56.10
> User-Agent: curl/7.79.1
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, CERT verify (15):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Mark bundle as not supporting multiuse
< HTTP/1.1 302 Found
< Date: Mon, 13 Dec 2021 02:56:30 GMT
< Server: Apache/2.4.37 (centos) OpenSSL/1.1.1g
< X-Powered-By: PHP/7.2.24
< Location: setup.php?site=default
< Content-Length: 0
< Content-Type: text/html; charset=UTF-8
< 
* Connection #0 to host 192.168.56.10 left intact
                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$ curl --cert http-client.pem --cert-type PEM --key http-client.key --key-type PEM https://192.168.56.10/openemr-5_0_1_3/  -vvvv               
*   Trying 192.168.56.10:443...
* Connected to 192.168.56.10 (192.168.56.10) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS alert, unknown CA (560):
* SSL certificate problem: unable to get local issuer certificate
* Closing connection 0
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
                                                                                                                                                                                                        
┌──(m3rl1n㉿TaRDiS-AttAcK-c0ns0l3)-[~]
└─$                            

import http.client
import json
import ssl
 
# Defining certificate related stuff and host of endpoint
certificate_file = '/home/m3rl1n/http-client.pem'
certificate_secret= '/home/m3rl1n/http-client.key'
host = 'example.com'
 
# Defining parts of the HTTP request
request_url='/a/http/url'
request_headers = {
    'Content-Type': 'application/json'
}
request_body_dict={
    'Temperature': 38,
    'Humidity': 80
}
 
# Define the client certificate settings for https connection
context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
context.load_cert_chain(certfile=certificate_file, password=certificate_secret)
 
# Create a connection to submit HTTP requests
connection = http.client.HTTPSConnection(host, port=443, context=context)
 
# Use connection to submit a HTTP POST request
connection.request(method="POST", url=request_url, headers=request_headers, body=json.dumps(request_body_dict))
 
# Print the HTTP response from the IOT service endpoint
response = connection.getresponse()
print(response.status, response.reason)
data = response.read()
print(data)