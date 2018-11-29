#!/bin/bash
#wget -O deploy-django.sh https://raw.githubusercontent.com/freereport/server/master/deploy-django.sh
#chmod +x deploy-django.sh

# create a sudo user as root:
# adduser <username>
# usermod -aG sudo <username>
# logout and login as <username>
# and run it like this
# sudo ./deploy-django.sh <postgres_db_password> <appname> <example.com>
# 

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with a sudo user: as root run the line bellow"
   echo "usermod -aG sudo <username>"
   exit 1
fi

function replace_line_in_txt_file() {
# sed can lick mah ballz
PATH1=$1
FINDLINE=$2
REPLLINE=$3
TEMP=$PATH1".temp"
while read line
do
    if [[ $line = "$FINDLINE"* ]]; then
        echo "${line/$FINDLINE/$REPLLINE}" >> $TEMP
    else
        echo "$line" >> $TEMP
    fi
done < $PATH1
rm $PATH1
mv $TEMP $PATH1
}

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
cat > /home/$SUDO_USER/post.sql << EOF
CREATE DATABASE "$APPNAME";
CREATE USER "$SUDO_USER" WITH PASSWORD '"$PASSWORD"';
ALTER ROLE "$SUDO_USER" SET client_encoding TO 'utf8';
ALTER ROLE "$SUDO_USER" SET default_transaction_isolation TO 'read committed';
ALTER ROLE "$SUDO_USER" SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE "$APPNAME" TO "$SUDO_USER";
EOF

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
FILENAME=/home/$SUDO_USER/$PROJECT/$PROJECT/$PROJECT/settings.py
echo Editing $FILENAME
replace_line_in_txt_file $FILENAME "ALLOWED_HOSTS = []" "ALLOWED_HOSTS=['"$DOMAINNAME"','."$DOMAINNAME"','localhost','"$IP"']"
replace_line_in_txt_file $FILENAME "'ENGINE':[ \t]'django.db.backends.sqlite3'" "'ENGINE':'django.db.backends.postgresql_psycopg2'"
replace_line_in_txt_file $FILENAME "'NAME': os.path.join(BASE_DIR, 'db.sqlite3')" "'NAME':'"$APPNAME"','USER':'"$SUDO_USER"','PASSWORD':'"$PASSWORD"','HOST':'localhost','PORT': ''"
STRING="STATIC_ROOT = os.path.join(BASE_DIR, 'static/')"
echo "$STRING" | sudo tee -a $FILENAME
read a;
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py makemigrations
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py migrate
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py createsuperuser
/home/$SUDO_USER/$PROJECT/$PROJECT/python manage.py collectstatic
read a;
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/$PROJECT

echo Creating /etc/systemd/system/gunicorn.socket
cat > /etc/systemd/system/gunicorn.socket << EOF
[Unit]
Description=gunicorn socket
[Socket]
ListenStream=/run/gunicorn.sock
[Install]
WantedBy=sockets.target
EOF
ls -la /etc/systemd/system/gunicorn.socket
cat /etc/systemd/system/gunicorn.socket

echo Creating /etc/systemd/system/gunicorn.service
cat > /etc/systemd/system/gunicorn.service << EOF
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target
[Service]
User="$SUDO_USER"
Group=www-data
WorkingDirectory=/home/"$SUDO_USER"/"$PROJECT 
ExecStart=/home/"$SUDO_USER"/"$PROJECT"/"$ENV"/bin/gunicorn \ 
          --access-logfile - \ 
          --workers 3 \ 
          --bind unix:/run/gunicorn.sock \ 
          myproject.wsgi:application
[Install]
WantedBy=multi-user.target
EOF
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
