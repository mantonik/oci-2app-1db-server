#bin/bash
 # this script will update server using o

# Update kerner 
/sbin/uptrack-upgrade -y
 
# update packages
 yum clean all
/bin/yum -y update

