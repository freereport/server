#!/bin/bash
clear
echo "."
echo "."
echo "."
echo "."
echo ".      Installing VS_FTPD (and cofiguring)"
echo "."
echo "."
echo "."
echo ". press Enter to continue..."
read
sudo apt update
sudo apt install vsftpd ufw -y
clear
echo "Enter name of FTP user to be created: "
read newusername
echo "enabling and cofiguring UFW"
sudo ufw enable
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 990/tcp
sudo ufw allow 40000:50000/tcp
sudo ufw status
echo "adding user "$newusername
sudo adduser $newusername
sudo mkdir /home/$newusername/ftp
sudo chown nobody:nogroup /home/$newusername/ftp
sudo chmod a-w /home/$newusername/ftp
sudo ls -la /home/$newusername/ftp
sudo mkdir /home/$newusername/ftp/files
sudo chown $newusername:$newusername /home/$newusername/ftp/files
sudo ls -la /home/$newusername/ftp
echo "vsftpd test file" | sudo tee /home/$newusername/ftp/files/test.txt
echo "saving the original config file: mv /etc/vsftpd.conf /etc/vsftpd.conf.orig"
sudo mv /etc/vsftpd.conf /etc/vsftpd.conf.orig
sudo touch /etc/vsftpd.conf
echo "anonymous_enable=NO" | sudo tee -a /etc/vsftpd.conf
echo "local_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "write_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "chroot_local_user=YES" | sudo tee -a /etc/vsftpd.conf
echo "user_sub_token=$USER" | sudo tee -a /etc/vsftpd.conf
echo "local_root=/home/$USER/ftp" | sudo tee -a /etc/vsftpd.conf
echo "pasv_min_port=40000" | sudo tee -a /etc/vsftpd.conf
echo "pasv_max_port=50000" | sudo tee -a /etc/vsftpd.conf
echo "userlist_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" | sudo tee -a /etc/vsftpd.conf
echo "userlist_deny=NO" | sudo tee -a /etc/vsftpd.conf
echo "local_umask=0002" | sudo tee -a /etc/vsftpd.conf
echo "listen=NO" | sudo tee -a /etc/vsftpd.conf
echo "listen_ipv6=YES" | sudo tee -a /etc/vsftpd.conf
echo "dirmessage_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "use_localtime=YES" | sudo tee -a /etc/vsftpd.conf
echo "xferlog_enable=YES" | sudo tee -a /etc/vsftpd.conf
echo "connect_from_port_20=YES" | sudo tee -a /etc/vsftpd.conf
echo "secure_chroot_dir=/var/run/vsftpd/empty" | sudo tee -a /etc/vsftpd.conf
echo "pam_service_name=vsftpd" | sudo tee -a /etc/vsftpd.conf
echo "rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem" | sudo tee -a /etc/vsftpd.conf
echo "rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key" | sudo tee -a /etc/vsftpd.conf
echo "ssl_enable=YES" | sudo tee -a /etc/vsftpd.conf

echo "$newusername" | sudo tee -a /etc/vsftpd.userlist
echo "restarting vsftp server..."
sudo systemctl restart vsftpd
echo "Done."
