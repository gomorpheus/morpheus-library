#!/bin/bash
. /tmp/os_detect.sh

install(){
  case "$OS_RELEASE" in
   ubuntu)
    add-apt-repository ppa:chris-lea/nginx-devel  -y
    apt-get update -y
    add-apt-repository  ppa:ondrej/php -y
    apt-get update -y
    apt-get install nginx php7.1 php7.1-fpm -y --force-yes
    ;;
   
   centos|rhel|ol)
   if [ -z $PHP71_DOWNLOAD_URL ]; then
   echo "No PHP_DOWNLOAD_URL was set in environment, this should be set in Packer."
    exit 1
   fi

    yum -y install $PHP71_DOWNLOAD_URL
    sed -i "s/enabled=0/enabled=1/g" /etc/yum.repos.d/remi-php71.repo
    yum clean all
    yum install php71 php71-php-fpm nginx -y
    ;;
   
   *)
    ;;
   esac
}

configure(){
  case "$OS_RELEASE" in
   ubuntu)
    cp -f /tmp/default /etc/nginx/sites-available/default
    ;;
  
   centos|rhel|ol)
    sed -i "s/;listen.owner = nobody/listen.owner = nginx/" /etc/opt/remi/php71/php-fpm.d/www.conf
    sed -i "s/;listen.group = nobody/listen.group = nginx/" /etc/opt/remi/php71/php-fpm.d/www.conf
    sed -i "s/apache/nginx/" /etc/opt/remi/php71/php-fpm.d/www.conf
    sed -i "s/127.0.0.1:9000/\/var\/run\/php-fpm\/php-fpm.sock/"  /etc/opt/remi/php71/php-fpm.d/www.conf
    /bin/mkdir -p /var/run/php-fpm
    cp -f /tmp/nginx.conf /etc/nginx/nginx.conf

    echo 'Welcome to Nginx' > /usr/share/nginx/html/index.html
    ;;
    
   *)
    ;;
   esac
}

restart_service(){
  case "$OS_RELEASE" in
   ubuntu)
    /etc/init.d/nginx restart
    /etc/init.d/php7.1-fpm restart
    ;;

   centos|rhel|ol)
    systemctl restart php71-php-fpm.service 
    systemctl restart nginx.service 
    systemctl enable php71-php-fpm.service 
    systemctl enable nginx.service 
    ;;  
 
   *)
    ;;
    esac
}

stat(){
if [ $? != 0 ]
then
	echo "error in  installing packages"
	exit 2
fi
}


install
stat
configure
stat
restart_service
