#!/bin/bash
set -e

if [ -e "/var/opt/morpheus/vm/morpheus.env" ]; then
	source /var/opt/morpheus/vm/morpheus.env
fi

rm -rf /etc/init/elasticsearch.override
initctl reload-configuration
update-rc.d elasticsearch defaults 95 10
service elasticsearch start