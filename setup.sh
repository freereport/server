#!/bin/bash
echo "."
sudo ufw enable;
sudo ufw limit ssh;

sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc;

sudo sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/PrintMotd no/PrintMotd yes/g' /etc/ssh/sshd_config;
sudo sed -i -e 's/#Banner/Banner/g' /etc/ssh/sshd_config;

sudo echo 'cat /var/log/auth.log* | grep 'Failed password' | grep sshd | awk '{print $1,$2}' | sort | uniq -c' > ~/howmanyfailed.sh;
sudo chmod +x ~/howmanyfailed.sh;

echo $'set smooth\nset autoindent\nset tabsize 4\nset tabstospaces\nset const' > .nanorc;

sudo echo "sudo apt update && sudo apt upgrade -y && sudo apt autoclean && sudo apt autoremove -y" > up.sh;
sudo chmod +x ~/up.sh;
./up.sh;
sudo apt install nmap netcat tmux htop acpi network-manager ffmpeg tree ranger wifite
echo "nmtiu" > wifi
echo "acpi" > battery
chmod +x wifi
chmod +x battery
echo "Done.";
