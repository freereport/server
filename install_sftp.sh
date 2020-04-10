#!/bin/bash


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi

#sudo apt install openssh-server -y
clear
echo " "
echo " "
echo "Creating Group sftpuser"
echo " "
echo " "
echo " "
sudo groupadd sftpuser
echo " "
echo " "
echo root directory /var/sftp
sudo mkdir /var/sftp
sudo chown root:root /var/sftp
sudo chmod 755 /var/sftp
ls -la /var/sftp

echo creating /var/sftp/public
sudo mkdir /var/sftp/public
sudo chown nobody:sftpuser /var/sftp/public
sudo chmod -R 2775 /var/sftp/public
ls -la /var/sftp

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sudo cat >> /etc/ssh/sshd_config << EOF

# This is for sftp users
# create sftp users with 
# sudo adduser --shell /bin/false <username>
# and add <username> bellow

Match Group sftpuser
	ForceCommand internal-sftp
	PasswordAuthentication yes
	ChrootDirectory /var/sftp
	PermitTunnel no
	AllowAgentForwarding no
	AllowTcpForwarding no
	X11Forwarding no

EOF
sudo systemctl restart ssh

echo "Create New sftp only username : "
read SFTP_USER
sudo adduser --shell /bin/false $SFTP_USER
sudo usermod -aG sftpuser $SFTP_USER
sudo mkdir /var/sftp/$SFTP_USER
sudo chown $SFTP_USER:$SFTP_USER /var/sftp/$SFTP_USER
sudo chmod 700 /var/sftp/$SFTP_USER

echo .
echo done.
