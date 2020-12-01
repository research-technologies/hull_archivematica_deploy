#!/bin/bash

# Blob Store

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update

sudo apt-get install blobfuse

ARCHIVEMATICA_UID=$(id -u archivematica)
ARCHIVEMATICA_GID=$(id -g archivematica)

##### using SSD as temporary path for blobfuse will result in 16GB cache allocated to /archive https://github.com/Azure/azure-storage-fuse/issues/161
sudo mkdir /mnt/resource/blobfusetmp -p
sudo chown archivematica:archivematica /mnt/resource/blobfusetmp

##### using rmadisk temporary path allows us to set this to 2T overkill?
# sudo mount -t tmpfs -o size=2T tmpfs /mnt/ramdisk
# sudo mkdir /mnt/ramdisk/blobfusetmp -p
# sudo chown archivematica:archivematica /mnt/ramdisk/blobfusetmp

if [ ! -f "~/fuse_connection.cfg" ]; then
        touch ~/fuse_connection.cfg

	echo "accountName ${blob_account_name}" | tee -a ~/fuse_connection.cfg >/dev/null
	echo "accountKey ${blob_account_key}" | tee -a ~/fuse_connection.cfg >/dev/null
	echo "containerName ${blob_container_name}" | tee -a ~/fuse_connection.cfg >/dev/null

fi


sudo chmod 600 fuse_connection.cfg

sudo mkdir /archive

sudo chown archivematica:archivematica /archive

sudo blobfuse /archive --tmp-path=/mnt/resource/blobfusetmp  --config-file=/home/azureuser/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other

# File Share


sudo apt-get install cifs-utils
sudo mkdir /data
sudo chown archivematica:archivematica /data

if [ ! -d "/etc/smbcredentials" ]; then
  sudo mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/${fileshare_account_name}.cred" ]; then
  sudo bash -c 'echo "username=${fileshare_account_name}" >> /etc/smbcredentials/${fileshare_account_name}.cred'
  sudo bash -c 'echo "password=${fileshare_account_key}" >> /etc/smbcredentials/${fileshare_account_name}.cred'
fi

sudo chmod 600 /etc/smbcredentials/${fileshare_account_name}.cred

sudo bash -c "echo '//${fileshare_account_name}.file.core.windows.net/${fileshare_name} /data cifs nofail,vers=3.0,credentials=/etc/smbcredentials/${fileshare_account_name}.cred,dir_mode=0777,file_mode=0777,serverino,uid=$ARCHIVEMATICA_UID,gid=$ARCHIVEMATICA_GID,forceuid,forcegid' >> /etc/fstab"

sudo mount -a /data
