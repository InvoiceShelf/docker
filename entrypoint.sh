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

echo "**** Make sure the /conf folder exists ****"
mkdir -p /conf

if [ -d /data ]
then
    echo "**** Discovered a /data folder. ****"
    [ ! -L /var/www/html/InvoiceShelf/storage ] && \
        echo "**** Moving everything from /var/www/html/InvoiceShelf/storage to the data folder ****"
	cp -rn /var/www/html/InvoiceShelf/storage/* /data && \
	rm -r /var/www/html/InvoiceShelf/storage && \
	ln -s /data /var/www/html/InvoiceShelf/storage
fi

echo "**** make sure all needed directories in storage exist ****"
mkdir -p /var/www/html/InvoiceShelf/storage/{logs,cache}
mkdir -p /var/www/html/InvoiceShelf/storage/framework/{sessions,views,cache}


cd /var/www/html/InvoiceShelf

echo "**** Copy the .env to /conf ****" && \
[ ! -e /conf/.env ] && \
	sed 's|^#DB_DATABASE=$|DB_DATABASE='$DB_DATABASE'|' /var/www/html/InvoiceShelf/.env.example > /conf/.env
[ ! -L /var/www/html/InvoiceShelf/.env ] && \
	ln -s /conf/.env /var/www/html/InvoiceShelf/.env
echo "**** Inject .env values ****" && \
	/inject.sh


APP_KEY=$(grep '^APP_KEY=' /conf/.env | cut -d'=' -f2-)
EXAMPLE_KEY="base64:kgk/4DW1vEVy7aEvet5FPp5un6PIGe/so8H0mvoUtW0="

if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "$EXAMPLE_KEY"  ]
then
  chmod +x artisan && \
	echo "**** Generate the key (to make sure that cookies cannot be decrypted etc) ****" && \
	./artisan key:generate -n --force
fi

echo "**** Create user and use PUID/PGID ****"
PUID=${PUID:-1000}
PGID=${PGID:-1000}
if [ ! "$(id -u "$USER")" -eq "$PUID" ]; then usermod -o -u "$PUID" "$USER" ; fi
if [ ! "$(id -g "$USER")" -eq "$PGID" ]; then groupmod -o -g "$PGID" "$USER" ; fi
echo -e " \tUser UID :\t$(id -u "$USER")"
echo -e " \tUser GID :\t$(id -g "$USER")"
usermod -a -G "$USER" www-data


if [ -n "$SKIP_PERMISSIONS_CHECKS" ] && [ "${SKIP_PERMISSIONS_CHECKS,,}" = "yes" ] ; then
	echo "**** WARNING: Skipping permissions check ****"
else
	echo "**** Set Permissions ****"
  chmod 775 /var/www/html/InvoiceShelf/storage/logs
  chmod 775 /var/www/html/InvoiceShelf/storage/framework
  chmod 775 /var/www/html/InvoiceShelf/storage/cache
  chmod 775 /var/www/html/InvoiceShelf/bootstrap/cache
  # Set ownership of directories, then files and only when required. See InvoiceShelf/InvoiceShelf-Docker#120
  find /conf/.env /var/www/html/InvoiceShelf/storage/ \
    \( ! -user "$USER" -o ! -group "$USER" \) -exec chown "$USER":"$USER" \{\} \;
  # Laravel needs to be able to chmod user.css and custom.js for no good reason
  find /var/www/html/InvoiceShelf/storage/ \
    -type d \( ! -perm -ug+w -o ! -perm -ugo+rX -o ! -perm -g+s \) -exec chmod -R ug+w,ugo+rX,g+s \{\} \;
  find /conf/.env /var/www/html/InvoiceShelf/storage/ \
    \( ! -perm -ug+w -o ! -perm -ugo+rX \) -exec chmod ug+w,ugo+rX \{\} \;
  chown -R www-data:www-data /var/www
  chown -R www-data:www-data /data
fi

# Link the storage
./artisan storage:link

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
