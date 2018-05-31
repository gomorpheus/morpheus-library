#!/bin/bash -eu

for nic in /etc/sysconfig/network-scripts/ifcfg-eth*;
do
  sed -i /HWADDR/d $nic;
  sed -i /UUID/d $nic;
done

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

#sed -i -e 's/quiet/quiet net.ifnames=0 biosdevname=0/' /etc/default/grub
sed -i -e 's/\<rhgb\>//g' /etc/default/grub
sed -i -e 's/quiet/console=ttyS0,38400n8d/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
#grub2-mkconfig -o /boot/grub/grub.cfg
export iface_file=$(basename "$(find /etc/sysconfig/network-scripts/ -name 'ifcfg*' -not -name 'ifcfg-lo' | head -n 1)")
export iface_name=${iface_file:6}
echo $iface_file
echo $iface_name
mv /etc/sysconfig/network-scripts/$iface_file /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i -e "s/$iface_name/eth0/" /etc/sysconfig/network-scripts/ifcfg-eth0

cat /etc/sysconfig/network-scripts/ifcfg-eth0

if grep -q PEERDNS /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i "s/PEERDNS=no/PEERDNS=yes/g" /etc/sysconfig/network-scripts/ifcfg-eth0
else
	echo PEERDNS="yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q NM_CONTROLLED /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i "s/NM_CONTROLLED=yes/NM_CONTROLLED=no/g" /etc/sysconfig/network-scripts/ifcfg-eth0
else
	echo NM_CONTROLLED="no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q DEFROUTE /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i "s/DEFROUTE=no/DEFROUTE=yes/g" /etc/sysconfig/network-scripts/ifcfg-eth0
else
echo DEFROUTE="yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q ONBOOT /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i "s/ONBOOT=no/ONBOOT=yes/g" /etc/sysconfig/network-scripts/ifcfg-eth0
else
	echo ONBOOT="yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q DEVICE /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i '/^DEVICE=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi
echo DEVICE="eth0" >> /etc/sysconfig/network-scripts/ifcfg-eth0

if grep -q IPV6 /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i '/^IPV6/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q NETBOOT /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i '/^NETBOOT=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q PEERDNS /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i '/^PEERDNS=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi

if grep -q PEERROUTES /etc/sysconfig/network-scripts/ifcfg-eth0; then
	sed -i '/^PEERROUTES=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
fi

cat /etc/sysconfig/network-scripts/ifcfg-eth0

# disable network manager
service NetworkManager stop
chkconfig NetworkManager off
service network start
chkconfig network on

touch /var/log/wtmp
touch /var/log/lastlog

set +e
# Zero out the rest of the free space using dd, then delete the written file.
/sbin/swapoff -a
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
