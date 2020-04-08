#!/bin/bash -e
set -e
. /tmp/os_detect.sh

# Turn off DNS lookups for SSH
echo "UseDNS no" >> /etc/ssh/sshd_config

	
zypper install -y git wget curl vim cloud-init
	
	


if [[ $VAGRANT  =~ true || $VAGRANT =~ 1 || $VAGRANT =~ yes ]]; then
	mkdir -pm 700 /home/vagrant/.ssh
	wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
	chmod 0600 /home/vagrant/.ssh/authorized_keys
	chown -R vagrant:vagrant /home/vagrant/.ssh
fi

echo "uname -r: $(uname -r)"
if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
		zypper update -y
fi
