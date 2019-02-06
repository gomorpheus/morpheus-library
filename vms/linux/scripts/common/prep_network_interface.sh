#!/bin/bash -eux
. /tmp/os_detect.sh
set -e
verifyEth0Exists(){
	case "$OS_RELEASE" in
		ubuntu)
			if [[ ${OS_VERSION%.*} > 17 ]]; then
				echo "Ubuntu 18 Detected ... Switching to netplan configuration fix..."
				sed -i -e "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/" /etc/default/grub
				echo "New Grub Config Generated"
				cat /etc/default/grub
				grub-mkconfig -o /boot/grub/grub.cfg
				sed -i -e 's/ens[0-9a-zA-Z]*/eth0/' /etc/netplan/01-netcfg.yaml
			elif [[ ${OS_VERSION%.*} > 14 ]]; then
				sed -i -e "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/" /etc/default/grub
				grub-mkconfig -o /boot/grub/grub.cfg
				sed -i -e 's/en[0-9a-zA-Z]*/eth0/' /etc/network/interfaces
			        sed -i -e '/^.*eth0.*$/d' /etc/network/interfaces
				echo "auto eth0" > /etc/network/interfaces.d/50-cloud-init.cfg
				echo "iface eth0 inet dhcp" >> /etc/network/interfaces.d/50-cloud-init.cfg
			fi
		;;

		debian)
			sed -i -e "s/GRUB_CMDLINE_LINUX=\"\([^\"]*\)\"/GRUB_CMDLINE_LINUX=\"\1 net.ifnames=0 biosdevname=0\"/" /etc/default/grub
			grub-mkconfig -o /boot/grub/grub.cfg
			sed -i -e 's/en[0-9a-zA-Z]*/eth0/' /etc/network/interfaces
			sed -i -e '/^.*eth0.*$/d' /etc/network/interfaces
			echo "auto eth0" > /etc/network/interfaces.d/50-cloud-init.cfg
			echo "iface eth0 inet dhcp" >> /etc/network/interfaces.d/50-cloud-init.cfg
		;;

		centos|rhel|ol)
			sed -i -e 's/quiet/quiet net.ifnames=0 biosdevname=0/' /etc/default/grub
			grub2-mkconfig -o /boot/grub2/grub.cfg
			export iface_file=$(basename "$(find /etc/sysconfig/network-scripts/ -name 'ifcfg*' -not -name 'ifcfg-lo' | head -n 1)")
			export iface_name=${iface_file:6}
			echo $iface_file
			echo $iface_name
			mv /etc/sysconfig/network-scripts/$iface_file /etc/sysconfig/network-scripts/ifcfg-eth0
			sed -i -e "s/$iface_name/eth0/" /etc/sysconfig/network-scripts/ifcfg-eth0
			bash -c 'echo NM_CONTROLLED=\"no\" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
		;;
   
		*)
		;;
	esac  
}

verifyNetworkConfigurationValues(){
	case "$OS_RELEASE" in
		ubuntu)
			echo "Not supported yet"
		;;

		centos|rhel|ol)
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

	    yum -y update openssl
	    yum -y install pcre-devel openssl-devel
	    yum -y install perl gcc make
		;;
   
		*)
		;;
	esac  
}

stat(){
  if [ $? != 0 ]
  then
        echo "failed in installation"
        exit 2
  fi
}

verifyEth0Exists
stat
verifyNetworkConfigurationValues
stat
