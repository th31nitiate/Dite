# Build Guide for Dite network 

The systems' purpose is to teach the usage of different types of authentication methods based on PKI. In corporate environments there a multitude of requirements, one of the main requirements is to effectively encrypt data. This is at rest and in transit. Thus PKI technologies have to be implemented to make this possible. Strong authentication is import, so we also aim to show how TLS can be used in order ensure to strength public facing login interfaces. To enable the ability to think lateral it also important to understand how to evaluate one's privileges by using alternative authentication methods. Understanding these things would also enable an administrator to secure the infrastructure and reduce the attack surface by adding an extra barrier to application which contain vulnerabilities.

## Status

**NTP**: Off  
**Firewall**: Off  
**Updates**: Off  
**ICMP**: On  
**IPv6**: Off  
**AV or Security**: Off
**SELinux**: Off

## Overview

**OS**: CentOS 7

**Hostname**: facet

**Vulnerability 1**: SSH PKI based authentication

**Vulnerability 2**: Misconfiguration within daemon service

**Admin Username**: root  

**Admin Password**: CowabungaItsTimeToSurf991  

**Low Priv Username**: dockerdev

**Low Priv Password**: CatchThatWaveMyDude751  

**Location of local.txt**: /home/dockerdev/local.txt  

**Value of local.txt**: 3f15318374adb8600ba3e3b48681370d  

**Location of proof.txt**: /root/proof.txt  

**Value of proof.txt**: c395f273ed118c4bdba3d1390b49d82de8e3b4264b91686d41f5796d3aab290a

#############################################

## Required Settings

**CPU**: 1 CPU  x 1
**Memory**: 1GB  x 1
**Disk**: 10GB x 1

## Build Guide

It is possible to use a few configurations in this instance. This could be vagrant or your own configuration dependent on your general requirements. The system has too be CentOS 7 ideally.

1. Install a CentOS 7 system

Ensure you disabled the firewall
Ensure you disable SELinux on the system

2. Enable network connectivity 

The network configuration is a simple point to point interface. It might be needed to configure specific attributes to suit your environment. Though the attributes that require amending are slightly limited. A flat network should surface.

3. Prepare your environment including installing the required OS

This means ensuring the ability to run the script. This can be provided by remote storage system such as nfs or a http server, though you would need to run it locally. 

4. Review the configuration parameters for the build script within the exported variable's section.

5. Run the build script in order to start the provisioning process. 

6. This script should provision the system as over all intended

