#!/bin/bash 
# 
# 1/8/2022 add delete local repository before pulling from repo
# v 1.2 delete full repository folder before uploading new files
# v 1.3 rsync_server
# v 1.6 add restart services
# 1.7 - enable rsync and restart
#Script will sync from repository to local 
version=1.1

export REPOBRANCH=dev
export REPODIR=${HOME}/repository/${REPOBRANCH}
export REPONAME=oci-2app-1db-server
export https_proxy=http://10.10.1.11:3128;
export http_proxy=http://10.10.1.11:3128;

# Delete repo folder
rm -rf ${REPODIR}
mkdir -p ${REPODIR}
cd ${REPODIR}
# upload repo file
wget https://github.com/mantonik/${REPONAME}/archive/refs/heads/${REPOBRANCH}.zip
unzip ${REPOBRANCH}.zip
# echo copy to home
cp -a ${REPONAME}-${REPOBRANCH}/server-config ${HOME}/
cd ${HOME}
ls -l

#echo "-----------------------"
#echo "Execute Rsync Server"
#sudo $HOME/bin/rsync_server.sh

#echo "-----------------------"
echo "Execute Restart Server"
sudo $HOME/bin/restart_services.sh now

echo "---------------------------------------"
echo "Version update_repository : ${version}"
echo "---------------------------------------"

