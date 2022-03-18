# Build Guide for Dite network 

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

**Value of local.txt**: 0da7106266afe38c958dfb326dc00816  

**Location of proof.txt**: /root/proof.txt  

**Value of proof.txt**: e88ed1b0b134d95172950b2c808a2dc4

#############################################

## Required Settings

**CPU**: 1 CPU  x 1
**Memory**: 1GB  x 1
**Disk**: 10GB x 1

#### Manual configuration of root and user password on system

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

5. Ensure to set the IP to suite your environment and that `/tmp/facetfiles` are transfer from the remote system to this facet `/tmp`.

6Run the build script in order to start the provisioning process. 

7This script should provision the system as over all intended

