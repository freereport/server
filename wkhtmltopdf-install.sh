#!/bin/bash

# install wkhtmltopdf in ubuntu server
# run this script as root
# go find the latest and put it bellow

LATESTVERSION='https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.xenial_amd64.deb'
# update the variable bellow according to file to be downloaded above
WKFILE='wkhtmltox_0.12.5-1.xenial_amd64.deb'

cd
apt-get install xvfb curl -y
curl -O LATESTVERSION
dpkg -i WKFILE
apt-get -f install
echo 'exec xvfb-run -a -s "-screen 0 640x480x16" wkhtmltopdf "$@"' | sudo tee /usr/local/bin/wkhtmltopdf.sh >/dev/null
chmod a+x /usr/local/bin/wkhtmltopdf.sh

