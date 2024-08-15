#!/bin/bash
#init script for setup server

#This script can be executed on any server and this will install required packages on each server

# Get the full hostname
full_hostname=$(hostname)

# Extract the first three characters
first_chars=${full_hostname:0:2}

# Update kerner 
/sbin/uptrack-upgrade -y
 
# update packages
 yum clean all
/bin/yum -y update

sudo firewall-cmd --state
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl mask --now firewalld

setenforce=0

if [ ${first_chars} == 'ap' ];then 
    echo "Install application servers"
    
    yum install -y oraclelinux-developer-release-el8
    yum install -y nginx python36-oci-cli php php-fpm php-mysqlnd php-json sendmail htop mc clamav clamav-update rclone
 
    echo "1" > /usr/share/nginx/html/healthcheck.html
    service nginx start

    mkdir /data

    #install certboot files

fi

if [ ${first_chars} == 'db' ];then 
    echo "Install apdatabase servers"
    yum install -y mysql-server
    service mysqld start
fi



