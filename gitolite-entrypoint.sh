#!/bin/bash

/etc/init.d/ssh status

if [  "$?" != 0 ]; then
	/etc/init.d/ssh start
	
	# Add Gitolite server in known_hosts list
	sudo -HEu redmine ssh -o StrictHostKeyChecking=no -p 2222 git@localhost true
fi

/docker-entrypoint.sh $@
