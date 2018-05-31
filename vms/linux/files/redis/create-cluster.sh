#!/bin/bash
set -e

if [ -e "/var/opt/morpheus/vm/morpheus.env" ]; then
	source /var/opt/morpheus/vm/morpheus.env
fi

echo -n "Current user: $USER"

USER_X=root

echo "USER_X: $USER_X"

CUSTOM_CREATE_COMMAND="echo yes | /usr/src/redis/src/redis-trib.rb create --replicas 1 $@"

echo "CREATE_COMMAND: $CUSTOM_CREATE_COMMAND"
sudo su - $USER_X -c "$CUSTOM_CREATE_COMMAND"

#sudo su - $USER_X -c "echo yes | /usr/src/redis/src/redis-trib.rb create --replicas 1 $@"
