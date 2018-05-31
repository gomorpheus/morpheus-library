#!/bin/bash -eux
echo "Registering vm with RedHat: $1"
subscription-manager register --username $1 --password $2 --auto-attach --force
subscription-manager refresh