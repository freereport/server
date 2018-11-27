#!/bin/bash

echo installing django app on ubuntu 18.04

# use sudo ./deploy-django.sh <appname> <example.com> <dbpassword>

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

APPNAME=$1
DOMAINNAME=$2
PASSWORD=$3
PROJECT="project_"$APPNAME
echo " "
echo $PROJECT
echo $APPNAME
echo $DOMAINNAME
echo $PASSWORD
echo " "
sudo apt update && sudo apt upgrade -y;
sudo apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl tree -y;

STRING="CREATE DATABASE "$APPNAME
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
STRING="CREATE USER "$USER" WITH PASSWORD "$PASSWORD
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
STRING="ALTER ROLE "$USER" SET client_encoding TO 'utf8'"
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
STRING="ALTER ROLE '$USER' SET default_transaction_isolation TO 'read committed'"
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
STRING="ALTER ROLE "$USER" SET timezone TO 'UTC'"
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
STRING="GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$USER
echo $STRING
sudo psql -U postgres -c $STRING;
read a;
echo Upgrading pip
sudo -H pip3 install --upgrade pip;
read a;
echo Installing virtualenv
sudo -H pip3 install virtualenv;
read a;

mkdir /home/$USER/$PROJECT
cd /home/$USER/$PROJECT
whoami
pwd
ls -la
read a;
echo creating env_$PROJECT
/home/$USER/$PROJECT virtualenv env_$PROJECT
read a;
tree
read a;
echo activating virtual enviroment...
source /home/$USER/$PROJECT/$ENV/bin/activate
read a;
echo Installing django gunicorn psycopg2-binary
pip install django gunicorn psycopg2-binary
read a;
echo Creating django project $PROJECT
django-admin.py startproject $PROJECT /home/$USER/$PROJECT/
read a;
echo Editing setting.py
STRING='s/ALLOWED_HOSTS = []/ALLOWED_HOSTS = [ '$DOMAINNAME', "localhost"]/g'
sed -i -e $STRING /home/$USER/$PROJECT/$PROJECT/settings.py;

STRING='s/'ENGINE': 'django.db.backends.sqlite3',/'ENGINE': 'django.db.backends.postgresql_psycopg2',/g'
sed -i -e $STRING /home/$USER/$PROJECT/$PROJECT/settings.py;

STRING='s/'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),/'NAME': '$APPNAME','USER': '$USER','PASSWORD': '$PASSWORD','HOST': 'localhost','PORT': '',/g'
sed -i -e $STRING /home/$USER/$PROJECT/$PROJECT/settings.py;

echo "STATIC_ROOT = os.path.join(BASE_DIR, 'static/')" >> /home/$USER/$PROJECT/$PROJECT/settings.py;
read a;
/home/$USER/$PROJECT/$PROJECT/python manage.py makemigrations
/home/$USER/$PROJECT/$PROJECT/python manage.py migrate
/home/$USER/$PROJECT/$PROJECT/python manage.py createsuperuser
/home/$USER/$PROJECT/$PROJECT/python manage.py collectstatic
read a;
#sudo chown -R $USER:$USER /home/$USER/$PROJECT
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
echo "User="$USER >> gunicorn.service
echo "Group=www-data" >> gunicorn.service
echo "WorkingDirectory=/home/"$USER"/"$PROJECT >> gunicorn.service
echo "ExecStart=/home/"$USER/$PROJECT"/"$ENV"/bin/gunicorn \ " >> gunicorn.service
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

echo 
echo "server { listen 80;" >> /etc/nginx/sites-available/$PROJECT
echo "    $DOMAINNAME;" >> /etc/nginx/sites-available/$PROJECT
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> /etc/nginx/sites-available/$PROJECT
echo "    location /static/ { root /home/$USER/$PROJECT; }" >> /etc/nginx/sites-available/$PROJECT
echo "    location / { include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }}" >> /etc/nginx/sites-available/$PROJECT

sudo ln -s /etc/nginx/sites-available/$PROJECT /etc/nginx/sites-enabled

sudo nginx -t
sudo systemctl restart nginx
sudo ufw allow 'Nginx Full'
echo " "
echo ok, now go to $DOMAINNAME
