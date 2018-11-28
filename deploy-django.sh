#!/bin/bash
#wget -O deploy-django.sh https://raw.githubusercontent.com/freereport/server/master/deploy-django.sh
#chmod +x deploy-django.sh

# create a sudo user and run it like this
# sudo ./deploy-django.sh <postgres_db_password> <appname> <example.com>
# 

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi

PASSWORD=$1
APPNAME=$2
DOMAINNAME=$3
IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
PROJECT="project_"$APPNAME

echo installing django app on ubuntu 18.04
apt update && sudo apt upgrade -y;
apt install python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl tree -y;

echo " "
echo project name $PROJECT
echo user $SUDO_USER - app name $APPNAME
echo domain name $DOMAINNAME - external ip address $IP
echo $PASSWORD
echo " "

cd /home/$SUDO_USER
echo "CREATE DATABASE "$APPNAME";" > /home/$SUDO_USER/post.sql
echo "CREATE USER "$SUDO_USER" WITH PASSWORD '"$PASSWORD"';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET client_encoding TO 'utf8';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET default_transaction_isolation TO 'read committed';" >> /home/$SUDO_USER/post.sql
echo "ALTER ROLE "$SUDO_USER" SET timezone TO 'UTC';" >> /home/$SUDO_USER/post.sql
echo "GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$SUDO_USER";" >> /home/$SUDO_USER/post.sql

sudo -u postgres psql postgres -f /home/$SUDO_USER/post.sql
rm /home/$SUDO_USER/post.sql
systemctl start postgresql
systemctl enable postgresql

echo Upgrading pip Installing virtualenv
pip3 install --upgrade pip
pip3 install virtualenv

mkdir /home/$SUDO_USER/$PROJECT
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT
cd /home/$SUDO_USER/$PROJECT
echo creating env_$PROJECT
virtualenv env_$PROJECT
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT
pwd
ls -la
source /home/$SUDO_USER/$PROJECT/env_$PROJECT/bin/activate
pip -V
pip install django gunicorn psycopg2-binary
echo Creating django project $PROJECT
django-admin.py startproject $PROJECT
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT
pwd
ls -la

echo Editing setting.py
FILENAME=/home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT/settings.py
echo $FILENAME
STRINGTOFIND="ALLOWED_HOSTS[ \t]=[ \t]["
STRINGTOREPL="ALLOWED_HOSTS=['"$DOMAINNAME
STRINGTOREPL+="','."$DOMAINNAME
STRINGTOREPL+="','localhost','"$IP
STRINGTOREPL+="'"
echo "$STRINGTOFIND replacing with $STRINGTOREPL"
sed -i -e "s|$STRINGTOFIND|$STRINGREPL|g" $FILENAME

STRINGTOFIND="'ENGINE':[ \t]'django.db.backends.sqlite3'"
STRINGTOREPL="'ENGINE':'django.db.backends.postgresql_psycopg2'"
echo "$STRINGTOFIND replacing with $STRINGTOREPL"
sed -i -e "s|$STRINGTOFIND|$STRINGREPL|g" "$FILENAME"

STRINGTOFIND="'NAME':[ \t]os.path.join(BASE_DIR,[ \t]'db.sqlite3')
STRINGTOREPL="'NAME':'"$APPNAME
STRINGTOREPL+="','USER':'"$SUDO_USER
STRINGTOREPL+="','PASSWORD':'"$PASSWORD
STRINGTOREPL+="','HOST':'localhost','PORT': ''"
echo "$STRINGTOFIND replacing with $STRINGTOREPL"
sed -i -e "s|$STRINGTOFIND|$STRINGREPL|g" "$FILENAME"

echo "STATIC_ROOT=os.path.join(BASE_DIR,'static/')" >> $FILENAME
read a;
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py makemigrations
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py migrate
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py createsuperuser
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py collectstatic
read a;
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT

GUNICORNSOCKET=/etc/systemd/system/gunicorn.socket
echo Creating $GUNICORNSOCKET
echo "[Unit]" > $GUNICORNSOCKET
echo "Description=gunicorn socket" >> $GUNICORNSOCKET
echo "[Socket]" >> $GUNICORNSOCKET
echo "ListenStream=/run/gunicorn.sock" >> $GUNICORNSOCKET
echo "[Install]" >> $GUNICORNSOCKET
echo "WantedBy=sockets.target" >> $GUNICORNSOCKET
ls -la /etc/systemd/system/gunicorn.socket
cat /etc/systemd/system/gunicorn.socket
read a;

GUNICORNSERVICE=/etc/systemd/system/gunicorn.service
echo Creating $GUNICORNSERVICE
echo "[Unit]" > $GUNICORNSERVICE
echo "Description=gunicorn daemon" >> $GUNICORNSERVICE
echo "Requires=gunicorn.socket" >> $GUNICORNSERVICE
echo "After=network.target" >> $GUNICORNSERVICE
echo "[Service]" >> $GUNICORNSERVICE
echo "User="$SUDO_USER >> $GUNICORNSERVICE
echo "Group=www-data" >> $GUNICORNSERVICE
echo "WorkingDirectory=/home/"$SUDO_USER"/"$PROJECT >> $GUNICORNSERVICE
echo "ExecStart=/home/"$SUDO_USER/$PROJECT"/"$ENV"/bin/gunicorn \ " >> $GUNICORNSERVICE
echo "          --access-logfile - \ " >> $GUNICORNSERVICE
echo "          --workers 3 \ " >> $GUNICORNSERVICE
echo "          --bind unix:/run/gunicorn.sock \ " >> $GUNICORNSERVICE
echo "          myproject.wsgi:application" >> $GUNICORNSERVICE
echo "[Install]" >> $GUNICORNSERVICE
echo "WantedBy=multi-user.target" >> $GUNICORNSERVICE
ls -la /etc/systemd/system/gunicorn.service
cat /etc/systemd/system/gunicorn.service
read a;

systemctl start gunicorn.socket
systemctl enable gunicorn.socket
systemctl status gunicorn.socket
systemctl status gunicorn
read a;

NGINXAVALIABLESITES=/etc/nginx/sites-available/$PROJECT
echo Creating $NGINXAVALIABLESITES
echo "server { listen 80;" >> $NGINXAVALIABLESITES
echo "    $DOMAINNAME;" >> $NGINXAVALIABLESITES
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> $NGINXAVALIABLESITES
echo "    location /static/ { root /home/$SUDO_USER/$PROJECT; }" >> $NGINXAVALIABLESITES
echo "    location / { include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }}" >> $NGINXAVALIABLESITES
ls -la $NGINXAVALIABLESITES
cat $NGINXAVALIABLESITES
read a;

ln -s $NGINXAVALIABLESITES /etc/nginx/sites-enabled

nginx -t
systemctl restart nginx
ufw allow 'Nginx Full'
echo " "
echo ok, now go to $DOMAINNAME
