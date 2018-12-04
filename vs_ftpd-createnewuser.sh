#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi
clear
echo "."
echo "."
echo "."
echo "."
echo ".      Creating new User for VS_FTPD"
echo "."
echo "."
echo "."
echo ". press Enter to continue..."
echo "Enter user name to be created: "
read newusername
echo "adding user "$newusername
adduser $newusername
mkdir /home/$newusername/ftp
chown nobody:nogroup /home/$newusername/ftp
chmod a-w /home/$newusername/ftp
ls -la /home/$newusername/ftp
mkdir /home/$newusername/ftp/files
chown $newusername:$newusername /home/$newusername/ftp/files
ls -la /home/$newusername/ftp
echo "vsftpd test file" | sudo tee /home/$newusername/ftp/files/test.txt
echo "$newusername" | sudo tee -a /etc/vsftpd.userlist
systemctl restart vsftpd
