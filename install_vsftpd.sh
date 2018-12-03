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
echo ".      Installing VS_FTPD"
echo "."
echo "."
echo "."
echo ". press Enter to continue..."
read
apt update && apt install vsftpd ufw -y
clear
ufw enable
ufw allow 22/tcp
ufw allow 20/tcp
ufw allow 21/tcp
ufw allow 990/tcp
ufw allow 40000:50000/tcp
ufw status
echo "Enter name of FTP user to be created: "
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
mv /etc/vsftpd.conf /etc/vsftpd.conf.original
cat > /etc/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
user_sub_token=(${!USER@})
local_root=/home/(${!USER@})/ftp
pasv_min_port=40000
pasv_max_port=50000
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
local_umask=0002
listen=NO
listen_ipv6=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=NO
force_local_logins_ssl=NO
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
debug_ssl=YES
EOF
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem
echo "$newusername" | sudo tee -a /etc/vsftpd.userlist
systemctl restart vsftpd
systemctl enable vsftpd
