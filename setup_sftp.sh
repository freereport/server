#!/bin/bash


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi

sudo apt install openssh-server -y

SFTP_USER="sftpuser"
ROOT_DIRECTORY="/var/sftp"
FILE_DIRECTORY="/files"

echo setting up sftpd
echo creating user $SFTP_USER
echo root directory $ROOT_DIRECTORY
echo file directory $ROOT_DIRECTORY$FILE_DIRECTORY
sudo adduser --shell /bin/false $SFTP_USER
sudo mkdir -p $ROOT_DIRECTORY$FILE_DIRECTORY
sudo chown $SFTP_USER:$SFTP_USER $ROOT_DIRECTORY$FILE_DIRECTORY
sudo chown root:root $ROOT_DIRECTORY
sudo chmod 755 $ROOT_DIRECTORY
sudo cat > /etc/ssh/sshd_config << EOF

# This is for sftp users
# create sftp users with 
# sudo adduser --shell /bin/false <username>
# and add <username> bellow

Match User $SFTP_USER
	ForceCommand internal-sftp
	PasswordAuthentication yes
	ChrootDirectory $ROOT_DIRECTORY$FILE_DIRECTORY
	PermitTunnel no
	AllowAgentForwarding no
	AllowTcpForwarding no
	X11Forwarding no


EOF
sudo systemctl restart
echo .
echo done.
