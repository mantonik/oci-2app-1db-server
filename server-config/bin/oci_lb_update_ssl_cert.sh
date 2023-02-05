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
#   b. fix certificate definition
#   c update create certificate
# 2/5/2023 remove input paramaters
# update script to handle multiple LB configuration base on the input file 

# To Do

# update configuration file and add more elements in one single line 
#LB_OCID:DOMAIN:BACKEND:LISTENER:BKACKENDPROTOCOL:ROUTING-POLICY:LB_HOSTNAME_JSON
# ROUTING-POLICY - is not used at this time 
# LB_HOSTNAME_JSON - just base name of the file, json extension is added 
#######

#Requirement
# update configuration file 
# update hostname.json file 


##########################################
#  FUNCTION
##########################################

function update_oci_lb () {

  echo "Update SSL certificate in LB for domain: " ${DOMAIN}

  cd /etc/letsencrypt/live/${DOMAIN}
  #Update the certificate
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

  LBUPDATESTRING=""
  if  [ "${ROUTINGPOLICY}x"  != "x"  ]; then 
    $LBUPDATESTRING="--routing-policy-name  ${ROUTINGPOLICY}"
  fi

  oci lb listener update \
  --default-backend-set-name ${BACKEND} \
  --port 443 \
  --protocol ${BKACKENDPROTOCOL} \
  --load-balancer-id ${LB_OCIID} \
  --listener-name ${LISTENER} \
  --ssl-certificate-name  ${DOMAIN}.${CERT_DT} \
  --hostname-names file:///root/etc/${LB_HOSTNAME_JSON} \
  $LBUPDATESTRING \
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

# Requirement
# You need to update a file in root/etc.oci_netowrk.cfg file 
# Entry has to be in format

# 
#LB_OCID:DOMAIN:BACKEND:LISTENER:BKACKENDPROTOCOL:ROUTING-POLICY:LB_HOSTNAME_JSON
#ocid1.loadbalancer.oc1.iad.aaaaaaaaggx4x56erajsyc7pxjoznsykpnof32e5t7npujihmcx4dxf7qtfq:ocidemo3.ddns.net:bk_app:LS_443:HTTP::lb_hostnames
#
# in this IFS need to be null to make process to read a  line in the script
while read -r CFGLINE
do 
  old_IFS=$IFS
  if [ ${CFGLINE:0:1} == "#"  ] ; then    
    continue
  fi
  IFS=':' read -r -a LINE <<< "$CFGLINE"
  echo "LB_OCID LINE[0] " ${LINE[0]}
  LB_OCIID=${LINE[0]}
  echo "DOMAIN LINE[1] " ${LINE[1]}
  DOMAIN=${LINE[1]}
  echo "BACKEND LINE[2] " ${LINE[2]}
  BACKEND=${LINE[2]}
  echo "LISTENER LINE[3] " ${LINE[3]}
  LISTENER=${LINE[3]}
  echo "BKACKENDPROTOCOL LINE[4] " ${LINE[4]}
  BKACKENDPROTOCOL=${LINE[4]}
  echo "ROUTING-POLICY LINE[5]  |${LINE[5]}|"
  ROUTINGPOLICY=${LINE[5]}
  echo "LB_HOSTNAME_JSON LINE[6] " ${LINE[6]}
  LB_HOSTNAME_JSON=${LINE[6]}
  
  #execute update of the load balancer
  update_oci_lb

  #set back IFS to old value
  IFS=${old_IFS}
done < $HOME/etc/oci_network.cfg 

#Delete not used SSL certificates
$HOME/server-config/bin/oci_lb_delete_not_used_certificates.sh

# version 2/5/2023 1:24
exit
