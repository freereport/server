#!/bin/bash

# install wkhtmltopdf in ubuntu server
# run this script as root

cd
apt-get install xvfb wkhtmltopdf -y
#apt-get -f install
echo 'exec xvfb-run -a -s "-screen 0 640x480x16" wkhtmltopdf "$@"' | sudo tee /usr/local/bin/wkhtmltopdf.sh >/dev/null
chmod a+x /usr/local/bin/wkhtmltopdf.sh

