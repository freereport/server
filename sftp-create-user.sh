#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi

clear
echo " "
echo " "
echo "This script will create a sftp user only"
echo " "
echo " "
echo " "
echo " "
ROOT_DIRECTORY="/var/sftp"
echo "New sftp only username : "
read SFTP_USER
sudo adduser --shell /bin/false $SFTP_USER
sudo usermod -aG sftpuser $SFTP_USER
sudo mkdir $ROOT_DIRECTORY/$SFTP_USER
sudo chown $SFTP_USER:$SFTP_USER $ROOT_DIRECTORY/$SFTP_USER
sudo chmod 700 $ROOT_DIRECTORY/$SFTP_USER
ls -la $ROOT_DIRECTORY
echo "done."
