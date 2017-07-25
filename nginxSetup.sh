#!/bin/bash


htmlRoot='/var/www/'
logRoot='/var/log/'
sitesAvailable='/etc/nginx/sites-available/'
sitesEnabled='/etc/nginx/sites-enabled/'
domain='example.com'
log='/tmp/nginxSetup.log'

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "You need to run this as root, please use sudo."
    exit
fi

abort()
{
    echo >&2 '
######################
### SCRIPT ABORTED ###
######################
'
    echo "An error occurred. Check /tmp/nginxSetupInteractive.log for details" >&2
    exit 1
}

trap 'abort' 0

set -e

exec 1> >(tee -a $log)
exec 2>&1

if [ "$(ls /usr/sbin | grep nginx)" = "nginx" ]; then
        exit 0
fi

apt-get install -y nginx

update-rc.d nginx defaults

echo 'server {
    server_name example.com www.example.com;
    access_log /var/log/example.com.access.log;

    listen 3200;

    root /var/www/example.com/html;

location / {

        proxy_set_header X-Real-localhost  $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $host;
        proxy_pass http://localhost:3400;

         }
}' > $sitesAvailable$domain

echo "<H1>YOU JUST GOT 404'D</H1>" > /usr/share/nginx/html/custom_404.html
ln -sf $sitesAvailable$domain $sitesEnabled$domain
echo "server {
    listen 80 default_server;
    error_page 404 /custom_404.html;
    location = / {
    return 404;
    }
    location = /custom_404.html {
    root /usr/share/nginx/html;
}
}" > /etc/nginx/sites-available/default
service nginx reload

trap : 0

echo -e >&2 "
\033[1m############################\033[0m
\033[1m## $domain is setup!  ##\033[0m
\033[1m############################\033[0m
"
