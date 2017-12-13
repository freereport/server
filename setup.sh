#!/bin/bash
echo "."
sudo ufw enable;
sudo ufw limit ssh;

sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc;

sudo sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/PrintMotd no/PrintMotd yes/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/#Banner/Banner/g' /etc/ssh/sshd_config;

echo 'cat /var/log/auth.log* | grep 'Failed password' | grep sshd | awk '{print $1,$2}' | sort | uniq -c' > ~/howmanyfailed.sh;
chmod +x ~/howmanyfailed.sh;

echo $'set smooth\nset autoindent\nset tabsize 4\nset tabstospaces\nset const' > .nanorc;


sudo echo "sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoclean && sudo apt-get autoremove -y" > up.sh;
sudo chmod +x ~/up.sh;
./up.sh;
echo "Done.";
