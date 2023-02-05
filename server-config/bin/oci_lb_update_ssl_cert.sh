#!/bin/bash 
#Script will update OCI LB configuration with SSL certificate 
set -x

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
#   b. fix certificate definition
#   c update create certificate
# 2/5/2023 remove input paramaters
# To Do
# update configuration file and add more elements in one single line 
#LB_OCIID:ocid....:DOMAIN:DOMAIN_NAME:LSTENER:LS-NAME:BACKEND:BK-NAME
#######

##########################################
#  FUNCTION
##########################################

function update_oci_lb () {

  echo "Update SSL certificate in LB for domain: " ${DOMAIN}

  cd /etc/letsencrypt/live/${DOMAIN}

  #oci lb certificate create --certificate-name  ${DOMAIN}.${CERT_DT} \
  #--load-balancer-id  ${LB_OCIID} \
  #--ca-certificate-file fullchain.pem \
  #--private-key-file privkey.pem  \
  #--public-certificate-file cert.pem
  # Base on sample from Carlos Santos
  oci lb certificate create --certificate-name  ${DOMAIN}.${CERT_DT} \
  --load-balancer-id  ${LB_OCIID} \
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

} #  end update_oci_lb

#########################################################
# MAIN
#########################################################

export CERT_DT=`date +%Y%m%d_%H%M`

#Get LB_OCIID
#  sed 's/^.\{4\}//g
#
# Parse config line and load configuration for each line in config file
#this part make a loop, and LB calls put info functions 
# file format 


# Requirement
# You need to update a file in root/etc.oci_netowrk.cfg file 
# Entry has to be in format

#LB_OCIID:lbocid.....
#DOMAIN:ocidemo3.ddns.net
#LISTENER:LS-https
#BACKEND:bk-https
#ROUTING-POLICY:RP_LS_HTTPS


#LB_OCIID=`cat $HOME/etc/oci_network.cfg|grep LB_OCIID:|sed 's/^.\{9\}//g' `
#BACKEND=bk_app
#LISTENER=LS_443
#BKACKENDPROTOCOL=HTTP

#echo group need to end with line LB_CFG_END
#LB_OCID:ocid1.loadbalancer.oc1.iad.aaaaaaaaggx4x56erajsyc7pxjoznsykpnof32e5t7npujihmcx4dxf7qtfq
#DOMAIN:ocidemo3.ddns.net
#BACKEND:bk_app
#LISTENER:LS_443
#BKACKENDPROTOCOL:HTTP
#ROUTING-POLICY:
#LB_CFG_END

#
# in this IFS need to be null to make process to read a  line in the script
while IFS= read -r CFGLINE
do 
  old_IFS=$IFS
  echo "Line: " ${CFGLINE}
  IFS=":"
  echo "line first element: CFGLINE[1] " ${CFGLINE[1]}
  echo "Line: {LINE:0:1} " ${CFGLINE:0:1}
  if [ ${CFGLINE:0:1} == "#" ]; then    
    continue
  fi
  echo "First: {LINE:0:8} " ${CFGLINE:0:8}
  if [ ${LINE:0:8} == "LB_OCID:" ]; then
    LB_OCID= ${LINE:10}
    echo "LB_OCID:"${LB_OCID}
    continue
  fi
  
  if [ ${LINE:0:7} == "DOMAIN:" ]; then
    DOMAIN= ${LINE:7}
    echo "DOMAIN:"${DOMAIN}
    continue
  fi
  #set back IFS to old value
  IFS=${old_IFS}
done < $HOME/etc/oci_network.cfg 

#Delete not used SSL certificates
# disable for now.
#$HOME/server-config/bin/oci_lb_delete_not_used_certificates.sh

# version 2/5/2023 1:24
exit