#!/bin/bash -eu

sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-e*
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-e*

sed 's/#PasswordAuthentication yes/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
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

rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

#dhclient -v

touch /var/log/wtmp
touch /var/log/lastlog

set +e
# Zero out the rest of the free space using dd, then delete the written file.
/sbin/swapoff -a
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
