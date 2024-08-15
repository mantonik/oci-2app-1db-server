
#!/bin/bash 
# Script will delete all not used SSL certificates.
#
# 2/3/2022 createa script 
# 2/5/2023 update to read each line from config file and then delete unused ssl certificates from it
#
echo "Delete unused SSL certificates"

# Check each LB configured in the  config file
while read -r CFGLINE
do 
  old_IFS=$IFS
  if [ ${CFGLINE:0:1} == "#"  ] ; then    
    continue
  fi
  IFS=':' read -r -a LINE <<< "$CFGLINE"
  echo "LB_OCID LINE[0] " ${LINE[0]}
  LB_OCIID=${LINE[0]}
  
  ACTIVE_CERT=`oci lb load-balancer get --load-balancer-id ${LB_OCIID}| jq -r '.data.listeners' |grep  certificate-name|tr -s " "|cut -d" " -f 3|sed 's/,//g'|sed 's/"//g'`

  #list of all SSL certificates
  oci lb certificate list --load-balancer-id ${LB_OCIID}|grep  certificate-name |grep -v ${ACTIVE_CERT}|cut -d: -f2|tr -s " "|sed 's/,//g'|sed 's/"//g'|sed 's/ //g'|
  while read CERT
  do
    echo "Delete certificat: " ${CERT}
    oci lb certificate delete --load-balancer-id ${LB_OCIID} --certificate-name ${CERT} --force
    sleep 5
  done
  echo "Wait 15s for delete process to complete"
  sleep 15
  echo ""
  echo "List of available certificates in LB"
  oci lb certificate list --load-balancer-id ${LB_OCIID}|grep  certificate-name

  echo ""

  #set back IFS to old value
  IFS=${old_IFS}
done < $HOME/etc/oci_network.cfg 

exit
