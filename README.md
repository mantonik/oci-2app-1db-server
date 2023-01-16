This repository is for OCI 2 app servers and 1 DB server setup 
2 app servers share a /data drive where is a configuration and application file system 
MySQL server is on seprate server

Setup files are needed by root user 
copy this repository to /root folder which will create folder server-config and it will put all required files in that structure 

pull this to each server 

app1
app2
db


Script descriptions

oci_lb_update_ssl_cert.sh
script will update SSL certificate of the LB 
Required configuration file in 
$HOME/etc/oci_network.cfg
( file has to be outside repository as if repo is updated configuration file will be overwrited if it is ipart of repo folder structre)
file format

Future: If file doesn't exit script will ask a questions and add new entry to configuration file


########################
Instalation Process 
########################


...app1
...app2
##########
Cloud Init script when setup a server 
#!/bin/bash 
/bin/dnf -y update

##########
app1
##########
#!/bin/bash
export REPOBRANCH=dev
export REPONAME=oci-2app-1db-server
REPODIR=${HOME}/repository/${REPOBRANCH}
cd ${HOME}
rm -rf ${REPODIR}
mkdir -p ${REPODIR}
cd ${REPODIR}
wget https://github.com/mantonik/${REPONAME}/archive/refs/heads/${REPOBRANCH}.zip
unzip ${REPOBRANCH}.zip
cp -a ${REPONAME}-${REPOBRANCH}/server-config ${HOME}/
cd ${HOME}
ls -l



https://github.com/mantonik/oci-2app-1db-server/archive/refs/heads/main.zip

#sudo ./bin/01.install-server-4app-2db.sh

