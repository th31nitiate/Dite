#!/bin/bash
for i in $(ls /home); do
 /usr/bin/cat /dev/null > /home/$i/.bash_history && history -c && exit
done

/usr/bin/rm /var/log/*