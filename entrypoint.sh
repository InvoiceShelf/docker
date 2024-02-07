#!/bin/bash

set -e

# Read Last commit hash from .git
# This prevents installing git, and allows display of commit
read -r longhash < /var/www/html/InvoiceShelf/.git/refs/heads/master
shorthash=$(echo $longhash |cut -c1-7)
invoiceshelfversion=$(</var/www/html/InvoiceShelf/version.md)
target=$(</var/www/html/InvoiceShelf/docker_target)

echo "
-------------------------------------
InvoiceShelf Version: $invoiceshelfversion ($target)
InvoiceShelf Commit:  $shorthash
https://github.com/InvoiceShelf/InvoiceShelf/commit/$longhash
-------------------------------------"

if [ -n "$STARTUP_DELAY" ]
	then echo "**** Delaying startup ($STARTUP_DELAY seconds)... ****"
	sleep $STARTUP_DELAY
fi

echo "**** Make sure the /conf /logs folders exist ****"
[ ! -d /conf ]    && mkdir -p /conf
[ ! -d /logs ]    && mkdir -p /logs

echo "**** Create the symbolic link for the /logs folder ****"
[ ! -L /var/www/html/InvoiceShelf/storage/logs ] && \
	touch /var/www/html/InvoiceShelf/storage/logs/empty_file && \
	cp -r /var/www/html/InvoiceShelf/storage/logs/* /logs && \
	rm -r /var/www/html/InvoiceShelf/storage/logs && \
	ln -s /logs /var/www/html/InvoiceShelf/storage/logs

cd /var/www/html/InvoiceShelf

echo "**** Copy the .env to /conf ****" && \
[ ! -e /conf/.env ] && \
	sed 's|^#DB_DATABASE=$|DB_DATABASE='$DB_DATABASE'|' /var/www/html/InvoiceShelf/.env.example > /conf/.env
[ ! -L /var/www/html/InvoiceShelf/.env ] && \
	ln -s /conf/.env /var/www/html/InvoiceShelf/.env
echo "**** Inject .env values ****" && \
	/inject.sh

[ ! -e /tmp/first_run ] && \
  chmod +x artisan
	echo "**** Generate the key (to make sure that cookies cannot be decrypted etc) ****" && \
	./artisan key:generate -n && \
	touch /tmp/first_run

echo "**** Create user and use PUID/PGID ****"
PUID=${PUID:-1000}
PGID=${PGID:-1000}
if [ ! "$(id -u "$USER")" -eq "$PUID" ]; then usermod -o -u "$PUID" "$USER" ; fi
if [ ! "$(id -g "$USER")" -eq "$PGID" ]; then groupmod -o -g "$PGID" "$USER" ; fi
echo -e " \tUser UID :\t$(id -u "$USER")"
echo -e " \tUser GID :\t$(id -g "$USER")"
usermod -a -G "$USER" www-data

echo "**** Make sure Laravel's log exists ****" && \
touch /logs/laravel.log

if [ -n "$SKIP_PERMISSIONS_CHECKS" ] && [ "${SKIP_PERMISSIONS_CHECKS,,}" = "yes" ] ; then
	echo "**** WARNING: Skipping permissions check ****"
else
	echo "**** Set Permissions ****"
  if [ ! -d "/var/www/html/InvoiceShelf/storage/framework" ]
  then
    mkdir -p /var/www/html/InvoiceShelf/storage/framework
  fi
	if [ ! -d "/var/www/html/InvoiceShelf/storage/cache" ]
	then
	  mkdir -p /var/www/html/InvoiceShelf/storage/cache
	fi
	chmod 755 /var/www/html/InvoiceShelf/storage/logs
	chmod 755 /var/www/html/InvoiceShelf/storage/framework
	chmod 755 /var/www/html/InvoiceShelf/storage/cache
	# Set ownership of directories, then files and only when required. See InvoiceShelf/InvoiceShelf-Docker#120
	find /conf/.env  /logs \( ! -user "$USER" -o ! -group "$USER" \) -exec chown "$USER":"$USER" \{\} \;
	# Laravel needs to be able to chmod user.css and custom.js for no good reason
	find /logs/laravel.log \( ! -user "www-data" -o ! -group "$USER" \) -exec chown www-data:"$USER" \{\} \;
	find /logs -type d \( ! -perm -ug+w -o ! -perm -ugo+rX -o ! -perm -g+s \) -exec chmod -R ug+w,ugo+rX,g+s \{\} \;
	find /conf/.env /logs \( ! -perm -ug+w -o ! -perm -ugo+rX \) -exec chmod ug+w,ugo+rX \{\} \;
fi

# Update CA Certificates if we're using armv7 because armv7 is weird (#76)
if [[ $(uname -a) == *"armv7"* ]]; then
  echo "**** Updating CA certificates ****"
  update-ca-certificates -f
fi

echo "**** Start cron daemon ****"
service cron start

echo "**** Setup complete, starting the server. ****"
php-fpm8.2
exec $@
