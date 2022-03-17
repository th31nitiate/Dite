
# Facet

## Enumeration

Upon scanning the network we find that and host we find that there is a few ports open on the remote system. SSH and what appears to be a web application port on 3434. After inspecting this application we find that it seems to be a docker container. This container enables us to have further enumeration of the system.

After some inspection we find the application is not vulnerable, so we review other means of accessing the system. The SSH port could be possible based on information collected from the previous system.

We find that user certificate authentication is possible on the system. There is multiple options that can be used in this instance. 

## Exploitation

We could generate new authentication keys using ssh-keygen. We have the user local `dockerdev` which could be also exist on the remote. 

Through using openssl and ssh-keygen to inspect some certification in the dite_certs directory which have information such as the user the key belongs to.

Once the keys are in place with the certificate. We attempt to ssh to the remote system. We find this to be successful when use the use certificate and key alongside the user `dockerdev`. 

## Escalation

This user seems like it may have access to the docker socket. Upon login into the user account this does not seem to be the case. Attempting to run docker commands does not seem useful since the user is not part of the dockers users group. We see that it is possible to run docker ps but not any other docker commands.

This means that sudoers file might be in user so an alternative way enumerate runnable commands is required. Upon a little more inspection of the docker page we find that docker support SSH as a daemon. 

The docker ssh method does not support ssh arguments. Thus, it was important to export the keys and user certificates to the correct location. Then configure an sshd_config file with similar properties as the following.

```
Host facet.dite.local
        Hostname facet.dite.local
        User dockerdev
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa
        CertificateFile ~/.ssh/id_rsa-cert.pub
        ControlMaster     auto
        ControlPath       ~/.ssh/control-%C
        ControlPersist    yes
```

Then it is possible to configure the system via `export DOCKER_HOST=ssh://dockerdev@192.168.56.11`. It is possible to make this exchangeable with the DNS name. Need to verify the principle used to sign th certificate is a valid.

It seems to be also possible to perform these steps using the `-H ssh://dockerdev@facet.dite.local`

The docker interface may use an alternative service. When we provide this setting including the correct ssh configuration. We find that we are able to authenticate on the remote system. This includes running docker containers.

At this point we can proceed to use the container present on the system to mount volume, add user or retrieve the proof.txt file. 