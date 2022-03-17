# Build Guide for Dite network 

The systems' purpose is to teach the usage of different types of authentication methods based on PKI. In corporate environments there a multitude of requirements, one of the main requirements is to effectively encrypt data. This is at rest and in transit. Thus PKI technologies have to be implemented to make this possible. Strong authentication is import, so we also aim to show how TLS can be used in order ensure to strength public facing login interfaces. To enable the ability to think lateral it also important to understand how to evaluate one's privileges by using alternative authentication methods. Understanding these things would also enable an administrator to secure the infrastructure and reduce the attack surface by adding an extra barrier to application which contain vulnerabilities.

## Status

**NTP**: Off  
**Firewall**: On  
**Updates**: Off  
**ICMP**: On  
**IPv6**: Off  
**AV or Security**: Off

## Overview

**OS**: CentOS 8

**Hostname**: acreage

**Vulnerability 1**: Vulnerable web application 

**Vulnerability 2**: Misconfigured docker daemon 

**Admin Username**: root  

**Admin Password**: CowabungaItsTimeToSurf991  

**Low Priv Username**: dockerdev

**Low Priv Password**: CatchThatWaveMyDude751  

**Location of local.txt**: /home/dockerdev/local.txt  

**Value of local.txt**:  c93a7db6cef3e65eb16850dc69c24b20  

**Location of proof.txt**: /root/proof.txt  

**Value of proof.txt**: 238e81ba6935e520eb5928fd03343afc

#############################################

**OS**: CentOS 8

**Hostname**: facet

**Vulnerability 1**: SSH PKI based authentication

**Vulnerability 2**: Misconfigured daemon service

**Admin Username**: root  

**Admin Password**: CowabungaItsTimeToSurf991  

**Low Priv Username**: dockerdev

**Low Priv Password**: CatchThatWaveMyDude751  

**Location of local.txt**: /home/dockerdev/local.txt  

**Value of local.txt**: 3f15318374adb8600ba3e3b48681370d  

**Location of proof.txt**: /root/proof.txt  

**Value of proof.txt**: c395f273ed118c4bdba3d1390b49d82de8e3b4264b91686d41f5796d3aab290a


## MITRE Framework Alightment

T1583.004 	Acquire Infrastructure: Server
T1608.003   Stage Capabilities: Install Digital Certificate
T1588.004 	Digital Certificates
T1190       Exploit Public-Facing Application
T1569.002 	Service Execution
T1610       Deploy Container
T1548.003 	Sudo and Sudo Caching
T1552.004 	Private Keys
T1569.002 	Service Execution

## Required Settings

**CPU**: 1 CPU  x 2
**Memory**: 1GB  x 2
**Disk**: 10GB x 2

## Build Guide

It is possible to use a few configurations in this instance. This could be vagrant or your own configuration dependent on your general requirements. The system has too be CentOS 8 and have support for ssh.

1. Install Ubuntu CentOS system our use provided artificates

It is possible to use the provided vagrant file in order to perform this step.
This file should provision of the required attributes for this running service.

2. Enable network connectivity 

The network configuration is quite simple point to point interface. It might be needed to configure specific attributes to suit your environment. Though the attribute that require amending are slightly limited.

3. Prepare your environment including install the required OS

If you use the provided image and vagrant then all should be functionally well. This should be an installation on CentOS 7 system with SSELinux disabled.

4. Review the configuration parameters for the build script in within the variable to be run against the system.

5. Run the build script in order to start the provisioning process.


---====

3. Prepare your environment including install the required OS

If you use the provided image and vagrant then all should be functionally well. This should be an installation on CentOS 7 system with SSELinux disabled.

4. Review the configuration parameters for the build script in within the variable to be run against the system.

5. Run the build script in order to start the provisioning process.


---===


6. Configure the web application service

Verify application installation was successful

![](acreage/images/configapp0.png)

Set the confgiuration for the application database settings and default credentials. The password which you choose for the data base in the ansible script should be funcational.

![](acreage/images/configapp1.png)

Verify the SQL server has been configured correctly.

![](acreage/images/configapp2.png)

At this stage ensure to click continue for all the steps until you reach the final page at which point you be redirected to the login page.

Once the login page is visable login via the defualt credentials `admin:admin`.

![](acreage/images/configapp3.png)

Configure the pateints portal by going to `administration > global > patient portal`, should be enabled. Verify that the online registration widget is also configured. 

![](acreage/images/configapp4.png)

Once this is done it means that we should be to able to proceed to the portal page with out much complication. Clicking on the register link should take us to the following page.

![](acreage/images/configapp5.png)

Once the application is configured as shown. It is possible to then proceed with the process of enabled SSL verification then restarting the apache2 service.

![](acreage/images/configapp7.png)

7. Once configured accurately the service should be ready to funcation accordingly.

On both systems, the alternative system is automaticaly configrued as should. Thus it should be funcational the users required level.

8. All services and system should be configured as intended.

Ensure to docker daemon user to the docker daemons group. on facet
