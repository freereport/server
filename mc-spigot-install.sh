#!/bin/bash

sudo apt update
sudo apt upgrade -y
echo "..................................................................."
echo "Java 9"
sudo apt install openjdk-9-jre-headless
echo "..................................................................."
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 25565
echo "..................................................................."
sudo adduser minecraft
sudo su - minecraft
echo "..................................................................."
mkdir /home/minecraft/build
cd /home/minecraft/build
wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
java -jar BuildTools.jar
echo "..................................................................."
mkdir ../server
cd ../server
mv ../build/spigot-1.*.jar spigot.jar
echo "..................................................................."
touch /home/minecraft/server/wrapper.sh
echo "#!/bin/bash" | tee -a /home/minecraft/server/wrapper.sh
echo "cd /home/minecraft/server;" | tee -a /home/minecraft/server/wrapper.sh
echo "java -XX:MaxPermSize=1024M -Xms512M -Xmx1536M -jar spigot.jar" | tee -a /home/minecraft/server/wrapper.sh
chmod +x /home/minecraft/server/wrapper.sh
