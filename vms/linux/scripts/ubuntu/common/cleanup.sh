#!/bin/bash -e
set -e
. /tmp/os_detect.sh

apt-get update
apt-get -y autoremove

if [[ $OS_VERSION =~ ^17 ]]; then
	if [ -f /etc/default/grub ]; then
		sed -i -e 's/quiet/quiet net.ifnames=0 biosdevname=0/' /etc/default/grub
		update-grub
	fi
fi

sudo sed -i 's/PermitRootLogin .*/PermitRootLogin forced-commands-only/' /etc/ssh/sshd_config
unset HISTFILE
sudo find / -name "authorized_keys" -exec rm -f {} \;
# Delete unneeded files.
files=(/home/vagrant/*.sh
/home/cloud-user/*.sh
/tmp/*
/etc/udev/rules.d/70-persistent-net.rules
/lib/udev/rules.d/75-persistent-net-generator.rules
/dev/.udev/ /var/lib/dhcp/*
/var/run/*/*.pid
/var/run/*.pid
/var/log/syslog*
/var/log/messages*
/var/log/maillog*
/var/log/mail.log*
/var/log/*.log
/var/log/lastlog
/var/log/btmp*
/var/log/utmp*
/var/log/wtmp*
/root/.ssh/*
/root/.bash_history
/home/*/.bash_history
/tmp/*.json)

set +e
for f in "${files[@]}"
do
  sudo rm -rf $f
done

touch /var/log/wtmp
touch /var/log/lastlog
echo manual | sudo tee /etc/init/ureadahead.override
set +e
# Zero out the rest of the free space using dd, then delete the written file.
/sbin/swapoff -a
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
# Clear Machine Id for ubuntu 18 bug
if [[ ${OS_VERSION%.*} > 17 ]]; then
truncate -s 0 /etc/machine-id
fi
# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
