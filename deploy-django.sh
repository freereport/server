#!/bin/bash

# create a sudo user and run it like this
# use sudo ./deploy-django.sh <dbpassword> <appname> <example.com>
# this will use the enviroment var $LOGNAME

echo installing django app on ubuntu 18.04

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

PASSWORD=$1
APPNAME=$2
DOMAINNAME=$3
IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
if [ -z "$DOMAINNAME" ]; then
   $DOMAINNAME=$IP
fi
PROJECT="project_"$APPNAME

echo " "
echo $PROJECT
echo $LOGNAME
echo $APPNAME
echo $DOMAINNAME
echo $IP
echo $PASSWORD
echo " "
sudo apt update && sudo apt upgrade -y;
sudo apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl tree -y;

echo "CREATE DATABASE "$APPNAME";" >> post.sql
echo "CREATE USER "$USER1" WITH PASSWORD '"$PASSWORD"';" >> post.sql
echo "ALTER ROLE "$USER1" SET client_encoding TO 'utf8';" >> post.sql
echo "ALTER ROLE "$USER1" SET default_transaction_isolation TO 'read committed';" >> post.sql
echo "ALTER ROLE "$USER1" SET timezone TO 'UTC';" >> post.sql
echo "GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$USER1";" >> post.sql

echo running SQL script
cat post.sql
sudo -u postgres psql postgres -f post.sql
rm post.sql
read a;


echo Upgrading pip
sudo -H pip3 install --upgrade pip;
read a;
echo Installing virtualenv
sudo -H pip3 install virtualenv;
read a;

mkdir /home/$USER1/$PROJECT
cd /home/$USER1/$PROJECT
pwd
tree
ls -la
read a;
echo creating env_$PROJECT
/home/$USER1/$PROJECT virtualenv env_$PROJECT
read a;
tree
read a;
echo activating virtual enviroment...
source /home/$USER1/$PROJECT/$ENV/bin/activate
read a;
echo Installing django gunicorn psycopg2-binary
pip install django gunicorn psycopg2-binary
read a;
echo Creating django project $PROJECT
django-admin.py startproject $PROJECT
read a;
echo Editing setting.py
STRING='s/ALLOWED_HOSTS = []/ALLOWED_HOSTS = [ '$DOMAINNAME', "localhost"]/g'
sed -i -e $STRING /home/$USER1/$PROJECT/$PROJECT/settings.py;

STRING='s/'ENGINE': 'django.db.backends.sqlite3',/'ENGINE': 'django.db.backends.postgresql_psycopg2',/g'
sed -i -e $STRING /home/$USER1/$PROJECT/$PROJECT/settings.py;

STRING='s/'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),/'NAME': '$APPNAME','USER': '$USER1','PASSWORD': '$PASSWORD','HOST': 'localhost','PORT': '',/g'
sed -i -e $STRING /home/$USER1/$PROJECT/$PROJECT/settings.py;

echo "STATIC_ROOT = os.path.join(BASE_DIR, 'static/')" >> /home/$USER1/$PROJECT/$PROJECT/settings.py;
read a;
/home/$USER1/$PROJECT/$PROJECT/python manage.py makemigrations
/home/$USER1/$PROJECT/$PROJECT/python manage.py migrate
/home/$USER1/$PROJECT/$PROJECT/python manage.py createsuperuser
/home/$USER1/$PROJECT/$PROJECT/python manage.py collectstatic
read a;
sudo chown -R $USER1:$USER1 /home/$USER1/$PROJECT
echo Creating gunicorn.socket
echo "[Unit]" >> gunicorn.socket
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
echo "[Unit]" >> gunicorn.service
echo "Description=gunicorn daemon" >> gunicorn.service
echo "Requires=gunicorn.socket" >> gunicorn.service
echo "After=network.target" >> gunicorn.service
echo "[Service]" >> gunicorn.service
echo "User="$USER1 >> gunicorn.service
echo "Group=www-data" >> gunicorn.service
echo "WorkingDirectory=/home/"$USER1"/"$PROJECT >> gunicorn.service
echo "ExecStart=/home/"$USER1/$PROJECT"/"$ENV"/bin/gunicorn \ " >> gunicorn.service
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
echo "server { listen 80;" >> /home/$USER1/$PROJECT/$PROJECT/$PROJECT
echo "    $DOMAINNAME;" >> /home/$USER1/$PROJECT/$PROJECT/$PROJECT
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> /home/$USER1/$PROJECT/$PROJECT/$PROJECT
echo "    location /static/ { root /home/$USER1/$PROJECT; }" >> /home/$USER1/$PROJECT/$PROJECT/$PROJECT
echo "    location / { include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }}" >> /home/$USER1/$PROJECT/$PROJECT/$PROJECT
sudo mv /home/$USER1/$PROJECT/$PROJECT/$PROJECT /etc/nginx/sites-available/$PROJECT
ls -la /etc/nginx/sites-available/$PROJECT
sudo cat /etc/nginx/sites-available/$PROJECT
read a;
sudo ln -s /etc/nginx/sites-available/$PROJECT /etc/nginx/sites-enabled

sudo nginx -t
sudo systemctl restart nginx
sudo ufw allow 'Nginx Full'
echo " "
echo ok, now go to $DOMAINNAME
