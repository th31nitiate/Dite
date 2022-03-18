# Exploitation Guide for Dite network 


The systems' purpose is to teach the usage of different types of authentication methods based on PKI. In corporate environments there a multitude of requirements, one of the main requirements is to effectively encrypt data. This is at rest and in transit. Thus PKI technologies have to be implemented to make this possible. Strong authentication is import, so we also aim to show how TLS can be used in order ensure to strength public facing login interfaces. To enable the ability to think lateral it also important to understand how to evaluate one's privileges by using alternative authentication methods. Understanding these things would also enable an administrator to secure the infrastructure and reduce the attack surface by adding an extra barrier to application which contain vulnerabilities.


## MITRE Framework Alignment

| Syntax | Description |
| --- | ----------- |
| T1583.004 | Acquire Infrastructure: Server |
| T1608.003 | Stage Capabilities: Install Digital Certificate |
| T1588.004 | Digital Certificates |
| T1190 | Exploit Public-Facing Application |
| T1569.002 | Service Execution |
| T1610 | Deploy Container |
| T1548.003 | Sudo and Sudo Caching |
| T1552.004 | Private Keys |


## Local testing

In order to run this on the local system please user `vagrant up --no-provision`. The once please login to each system via `vagrant ssh <systemname>`. Once logged in ensure to disable selinux for compatibility reasons. Once linux is disabled please reboot each vm. It would then be possible to run vagrant provision.

## Guides

###Best thing would be to create VMWare snapshot and then image af5ter performing the build

[acreage-build](./acreage/build-guide.md)

[facet-build](./facet/build-guide.md)

[acreage walkthrough](./acreage/walkthrough.md)

[facet walkthrough](./facet/walkthrough.md)

