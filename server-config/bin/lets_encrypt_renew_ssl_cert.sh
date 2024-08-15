#!/bin/bash
#Script will renew SSL certificate and then update OCL LB 
# 1/1/2024 - update webroot path

. /etc/profile 

#Renew SSL certificat 


#Renew certificate and then call oci LB update script once 
#2/18/2023
# script folder /root/server-config/bin
/usr/local/bin/certbot certonly --force-renew --webroot -w /data/www/letsencrypt/htdoc -d ocidemo3.ddns.net --deploy-hook /root/server-config/bin/oci_lb_update_ssl_cert.sh  --dry-run

# test URL 
#http://ocidemo.ddns.net/.well-known/acme-challenge/t.html


