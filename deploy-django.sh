#!/bin/bash

# installing django app on ubuntu 18.04

# use sudo ./deploy-django.sh <appname> <example.com> <dbpassword>

APPNAME=$1
DOMAINNAME=$2
PASSWORD=$3
USER=$APPNAME"user"
PROJECT="project-"$APPNAME
ENV="env-"$PROJECT

sudo apt update;
sudo apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl -y;

STRING="CREATE DATABASE "$APPNAME
sudo psql -U postgres -c $STRING;
STRING="CREATE USER "$USER" WITH PASSWORD "$PASSWORD
sudo psql -U postgres -c $STRING;
STRING="ALTER ROLE "$USER" SET client_encoding TO 'utf8'"
sudo psql -U postgres -c $STRING;
STRING="ALTER ROLE '$USER' SET default_transaction_isolation TO 'read committed'"
sudo psql -U postgres -c $STRING;
STRING="ALTER ROLE "$USER" SET timezone TO 'UTC'"
sudo psql -U postgres -c $STRING;
STRING="GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$USER
sudo psql -U postgres -c $STRING;

sudo -H pip3 install --upgrade pip;
sudo -H pip3 install virtualenv;

sudo adduser $USER
su $USER
mkdir ~/$PROJECT
cd ~/$PROJECT
virtualenv $ENV

source ~/$PROJECT/$ENV/bin/activate
pip install django gunicorn psycopg2-binary
django-admin.py startproject $PROJECT ~/$PROJECT
STRING='s/ALLOWED_HOSTS = []/ALLOWED_HOSTS = [ '$DOMAINNAME', "localhost"]/g'
sed -i -e $STRING ~/$PROJECT/$PROJECT/settings.py;
STRING='s/'ENGINE': 'django.db.backends.sqlite3',/'ENGINE': 'django.db.backends.postgresql_psycopg2',/g'
sed -i -e $STRING ~/$PROJECT/$PROJECT/settings.py;
STRING='s/'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),/'NAME': '$APPNAME','USER': '$USER','PASSWORD': '$PASSWORD','HOST': 'localhost','PORT': '',/g'
sed -i -e $STRING ~/$PROJECT/$PROJECT/settings.py;
echo "STATIC_ROOT = os.path.join(BASE_DIR, 'static/')" >> ~/$PROJECT/$PROJECT/settings.py;
~/$PROJECT/./manage.py makemigrations
~/$PROJECT/./manage.py migrate
~/$PROJECT/./manage.py createsuperuser
~/$PROJECT/./manage.py collectstatic

exit

echo "[Unit]" >> gunicorn.socket
echo "Description=gunicorn socket" >> gunicorn.socket
echo "[Socket]" >> gunicorn.socket
echo "ListenStream=/run/gunicorn.sock" >> gunicorn.socket
echo "[Install]" >> gunicorn.socket
echo "WantedBy=sockets.target" >> gunicorn.socket
sudo mv gunicorn.socket /etc/systemd/system/gunicorn.socket
sudo chown root:root /etc/systemd/system/gunicorn.socket

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
sudo chown root:root /etc/systemd/system/gunicorn.service

sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket

echo "server { listen 80;" >> /etc/nginx/sites-available/$PROJECT
echo "    $DOMAINNAME;" >> /etc/nginx/sites-available/$PROJECT
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> /etc/nginx/sites-available/$PROJECT
echo "    location /static/ { root /home/$USER/$PROJECT; }" >> /etc/nginx/sites-available/$PROJECT
echo "    location / { include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }}" >> /etc/nginx/sites-available/$PROJECT

sudo ln -s /etc/nginx/sites-available/$PROJECT /etc/nginx/sites-enabled


#STRING='s///g'
#sed -i -e $STRING ~/$PROJECT/$PROJECT/settings.py;
sudo nginx -t
sudo systemctl restart nginx
sudo ufw allow 'Nginx Full'

