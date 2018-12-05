#!/bin/bash


echo "."
ufw enable;
ufw limit ssh;
timedatectl set-timezone America/New_York
sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc;

sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config;
sed -i -e 's/PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config;
sed -i -e 's/PrintMotd no/PrintMotd yes/g' /etc/ssh/sshd_config;
sed -i -e 's/#Banner/Banner/g' /etc/ssh/sshd_config;
echo "AllowUsers $SUDO_USER" >> /etc/ssh/sshd_config;

cat > ~/failed-ssh.sh << EOF
cat /var/log/auth.log* | grep 'Failed password' | grep sshd | awk '{print (${!1@}),(${!2@})}' | sort | uniq -c
read a
lastb | awk '{if ((${!3@}) ~ /([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}/)a[(${!3@})] = a[(${!3@})]+1} END {for (i in a){print i " : " a[i]}}' | sort -nk 3
EOF
chmod +x ~/failed-ssh.sh;
cat > ~/up.sh << EOF
apt update && apt upgrade -y && apt autoclean && apt autoremove -y
EOF
chmod +x ~/up.sh

echo $'set smooth\nset autoindent\nset tabsize 4\nset tabstospaces\nset const' > ~/.nanorc;

apt install nmap netcat tmux htop tree ranger figlet #acpi network-manager ffmpeg wifite
echo "nmtiu" > ~/wifi && chmod +x ~/wifi;
echo "acpi" > ~/battery && chmod +x ~/battery;
echo "Done.";
