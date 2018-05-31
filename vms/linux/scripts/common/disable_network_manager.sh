#!/bin/bash -ex
. /tmp/os_detect.sh

stopNetworkManager(){
	echo "Stopping NetworkManager"
	case "$OS_RELEASE" in
		ubuntu)
			echo "Not supported yet"
		;;

		centos|rhel|ol)
			if rpm -qa | grep -q NetworkManager-config-server; then
				yum -y remove NetworkManager-config-server
			else
				echo "NetworkManager-config-server is not installed"
			fi
			if rpm -qa | grep -q NetworkManager; then
				service NetworkManager stop
			else
				echo "NetworkManager is not installed"
			fi
		;;
   
		*)
		;;
	esac  
}

disableNetworkManager(){
	echo "Disabling NetworkManager"
	case "$OS_RELEASE" in
		ubuntu)
			echo "Not supported yet"
		;;

		centos|rhel|ol)
			echo "CentOS or RedHat or Oracle flavor detected. Disabling NetworkManager now"
			chkconfig NetworkManager off
			systemctl mask NetworkManager.service
#			yum -y remove NetworkManager
		;;
   
		*)
		;;
	esac  
}

startNetworkService(){
	echo "Starting network service"
	case "$OS_RELEASE" in
		ubuntu)
			echo "Not supported yet"
		;;

		centos|rhel|ol)
			service network start
		;;
   
		*)
		;;
	esac  
}

enableNetworkService(){
	echo "Enabling network service"
	case "$OS_RELEASE" in
		ubuntu)
			echo "Not supported yet"
		;;

		centos|rhel|ol)
			chkconfig network on
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

stopNetworkManager
stat
disableNetworkManager
stat
startNetworkService
stat
enableNetworkService
stat