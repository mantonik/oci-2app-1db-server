#!/bin/bash 
#Script will update OCI LB configuration with SSL certificate 
set +x

# 1. get LB OCIID
# 2. Create SSL certificate 
# 3. update SSL certificate for specific listener - domain listener which have a host listener define.
# 4. configuration of the LB is in file /root/etc/oci_network.cfg 
#     entry start from LB_OCIID:
#Script support single LB only

#Reference 
#https://docs.oracle.com/en-us/iaas/tools/oci-cli/2.9.1/oci_cli_docs/cmdref/lb/certificate.html
#
# Sample of comand to generate example of the json input 
# oci lb listener update --generate-param-json-input hostname-names

##########
## Version 
# 2/3/2022 - create script
# - fix while loop
# - fix x variable
# - add call to delete SSL cert script
# 1/16/2023 update with parameters 
#   a. add hostname to LB configuration
# To Do
# update configuration file and add more elements in one single line 
#LB_OCIID:ocid....:DOMAIN:DOMAIN_NAME:LSTENER:LS-NAME:BACKEND:BK-NAME
#######

#export LB_OCIID="ocid1.loadbalancer.oc1.iad.aaaaaaaavl7ihlzsqcun4ojqj2nqk63siudt3c5aodazvhstb3v4cy46xtya"
export CERT_DT=`date +%Y%m%d_%H%M`

DOMAIN=$1

if [ ${DOMAIN}"x" == "x" ]; then 
  echo "enter as parameter domain name"
  echo "----"
  echo "   oci_lb_update_ssl_cert.sh example.com"
  echo "----"  
  exit 0
  fi

#Get LB_OCIID
#  sed 's/^.\{4\}//g
#
# Parse config line and load configuration for each line in config file
#this part make a loop, and LB calls put info functions 
# file format 

#LB_OCIID:lbocid.....:DOMAIN:ocidemo3.ddns.net:LISTENER:LS-https:BACKEND:bk-https:ROUTING-POLICY:RP_LS_HTTPS

LB_OCIID=`cat $HOME/etc/oci_network.cfg|grep LB_OCIID:|sed 's/^.\{9\}//g' `

BACKEND=bk_app
LISTENER=LS_443
BKACKENDPROTOCOL=HTTP
HOSTNAMES=["ocidemo3.ddns.net"]

#ROUTINGPOLICY=RP_LS_443

echo "Update SSL certificate in LB for domain: " ${DOMAIN}

cd /etc/letsencrypt/live/${DOMAIN}

oci lb certificate create --certificate-name  ${DOMAIN}.${CERT_DT} \
--load-balancer-id  ${LB_OCIID} \
--ca-certificate-file cert.pem  \
--private-key-file privkey.pem  \
--public-certificate-file fullchain.pem

#Update LB listener to use new certificate 
#echo "Wait 120s before next step. it will take some time to add certificate to LB configuration"
#sleep 120 # it takes minute or two for create certificate - may need also a query to list current available certificates
echo "Wait for certificate file to be added"
x=0
nr=0
while [ ${x} -lt 100 ]
do
  
  sleep 5
  #Check if certificate was added
  nr=`oci lb certificate list --load-balancer-id ${LB_OCIID}|grep  certificate-name|grep ${DOMAIN}.${CERT_DT}| wc -l `
  if [ ${nr} -gt 0 ]; then 
    break  
  fi
  echo -en "."
  x=$((x + 1))
done

echo ""
echo "Update LB with latest certificate"
oci lb listener update \
--default-backend-set-name ${BACKEND} \
--port 443 \
--protocol ${BKACKENDPROTOCOL} \
--load-balancer-id ${LB_OCIID} \
--listener-name ${LISTENER} \
--ssl-certificate-name  ${DOMAIN}.${CERT_DT} \
--hostname-names file:///root/etc/lb_hostnames.json \
--force
#--routing-policy-name ${ROUTINGPOLICY} \


echo "Wait for certificate file to be active"
x=0
nr=0
while [ ${x} -lt 100 ]
do
  sleep 5
  #Check if certificate was added
  nr=`oci lb load-balancer get --load-balancer-id ${LB_OCIID}| jq -r '.data.listeners' |grep  certificate-name|grep ${DOMAIN}.${CERT_DT}| wc -l`
  if [ ${nr} -gt 0 ]; then 
    echo "Certificate update in Load Balancer"
    break  
  fi
  echo -en "."
  #x=`exp $x + 1`
  x=$((x + 1))
done
echo ""

#Delete not used SSL certificates
oci_lb_delete_not_used_certificates.sh

exit