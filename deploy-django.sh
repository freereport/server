#!/bin/bash

# create a sudo user and run it like this
# use sudo ./deploy-django.sh <postgres_db_password> <appname> <example.com>
# 

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo" 
   exit 1
fi

PASSWORD=$1
APPNAME=$2
DOMAINNAME=$3
IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
PROJECT="project_"$APPNAME

echo installing django app on ubuntu 18.04
echo " "
echo project name $PROJECT
echo user $SUDO_USER
echo app name $APPNAME
echo domain name $DOMAINNAME
echo external ip address $IP
echo $PASSWORD
echo " "
sudo apt update && sudo apt upgrade -y;
sudo apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl tree -y;

cd /home/$SUDO_USER
echo "CREATE DATABASE "$APPNAME";" > /home/$SUDO_USER/post.sql
echo "CREATE USER "$SUDO_USER" WITH PASSWORD '"$PASSWORD"';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET client_encoding TO 'utf8';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET default_transaction_isolation TO 'read committed';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET timezone TO 'UTC';" >> /home/$SUDO_USER/post.sql
echo "GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$SUDO_USER";" >> /home/$SUDO_USER/post.sql

cat /home/$SUDO_USER/post.sql
sudo -u postgres psql postgres -f /home/$SUDO_USER/post.sql
rm /home/$SUDO_USER/post.sql

echo Upgrading pip
sudo -H pip3 install --upgrade pip;
echo Installing virtualenv
sudo -H pip3 install virtualenv;
mkdir /home/$SUDO_USER/$PROJECT
cd /home/$SUDO_USER/$PROJECT
echo creating env_$PROJECT
virtualenv env_$PROJECT
ls -la
read a;
echo activating virtual enviroment...
source /home/$SUDO_USER/$PROJECT/env_$PROJECT/bin/activate
echo Installing django gunicorn psycopg2-binary
pip install django gunicorn psycopg2-binary
echo Creating django project $PROJECT
django-admin.py startproject $PROJECT
sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT
ls -la
read a;
echo Editing setting.py
STRING='s/ALLOWED_HOSTS = []/ALLOWED_HOSTS = [ "'
STRING+=$DOMAINNAME'", "localhost", "'
STRING+=$IP'"]/g'
sed -i -e $STRING /home/$SUDO_USER/$PROJECT/$PROJECT/settings.py;

STRING="s/'ENGINE': 'django.db.backends.sqlite3',/'ENGINE': 'django.db.backends.postgresql_psycopg2',/g"
sed -i -e $STRING /home/$SUDO_USER/$PROJECT/$PROJECT/settings.py;

STRING="s/'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),/'NAME': '"$APPNAME
STRING+="','USER': '"$SUDO_USER
STRING+="','PASSWORD': '"$PASSWORD
STRING+="','HOST': 'localhost','PORT': '',/g"
sed -i -e $STRING /home/$SUDO_USER/$PROJECT/$PROJECT/settings.py;

echo "STATIC_ROOT = os.path.join(BASE_DIR, 'static/')" >> /home/$SUDO_USER/$PROJECT/$PROJECT/settings.py;
read a;
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py makemigrations
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py migrate
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py createsuperuser
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py collectstatic
read a;
sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT
echo Creating gunicorn.socket
echo "[Unit]" > gunicorn.socket
echo "Description=gunicorn socket" >> gunicorn.socket
echo "[Socket]" >> gunicorn.socket
echo "ListenStream=/run/gunicorn.sock" >> gunicorn.socket
echo "[Install]" >> gunicorn.socket
echo "WantedBy=sockets.target" >> gunicorn.socket

sudo mv gunicorn.socket /etc/systemd/system/gunicorn.socket
rm gunicorn.socket
sudo chown root:root /etc/systemd/system/gunicorn.socket
ls -la /etc/systemd/system/gunicorn.socket
sudo cat /etc/systemd/system/gunicorn.socket
read a;
echo Creating gunicorn.service
echo "[Unit]" > gunicorn.service
echo "Description=gunicorn daemon" >> gunicorn.service
echo "Requires=gunicorn.socket" >> gunicorn.service
echo "After=network.target" >> gunicorn.service
echo "[Service]" >> gunicorn.service
echo "User="$SUDO_USER >> gunicorn.service
echo "Group=www-data" >> gunicorn.service
echo "WorkingDirectory=/home/"$SUDO_USER"/"$PROJECT >> gunicorn.service
echo "ExecStart=/home/"$SUDO_USER/$PROJECT"/"$ENV"/bin/gunicorn \ " >> gunicorn.service
echo "          --access-logfile - \ " >> gunicorn.service
echo "          --workers 3 \ " >> gunicorn.service
echo "          --bind unix:/run/gunicorn.sock \ " >> gunicorn.service
echo "          myproject.wsgi:application" >> gunicorn.service
echo "[Install]" >> gunicorn.service
echo "WantedBy=multi-user.target" >> gunicorn.service

sudo mv gunicorn.service /etc/systemd/system/gunicorn.service
rm gunicorn.service
sudo chown root:root /etc/systemd/system/gunicorn.service
ls -la /etc/systemd/system/gunicorn.service
sudo cat /etc/systemd/system/gunicorn.service
read a;

sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl status gunicorn.socket
sudo systemctl status gunicorn
read a;

echo Creating /etc/nginx/sites-available/$PROJECT
echo "server { listen 80;" >> /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT
echo "    $DOMAINNAME;" >> /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT
echo "    location /static/ { root /home/$SUDO_USER/$PROJECT; }" >> /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT
echo "    location / { include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }}" >> /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT
sudo mv /home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT /etc/nginx/sites-available/$PROJECT
ls -la /etc/nginx/sites-available/$PROJECT
sudo cat /etc/nginx/sites-available/$PROJECT
read a;
sudo ln -s /etc/nginx/sites-available/$PROJECT /etc/nginx/sites-enabled

sudo nginx -t
sudo systemctl restart nginx
sudo ufw allow 'Nginx Full'
echo " "
echo ok, now go to $DOMAINNAME
