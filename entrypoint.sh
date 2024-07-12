#!/bin/bash

set -e

# Read Last commit hash from .git
# This prevents installing git, and allows display of commit
branch=$(ls /var/www/html/InvoiceShelf/.git/refs/heads)
read -r longhash < /var/www/html/InvoiceShelf/.git/refs/heads/$branch
shorthash=$(echo $longhash |cut -c1-7)
if [ -f /var/www/html/InvoiceShelf/version.md ]; then
  appversion=$(</var/www/html/InvoiceShelf/version.md)
else
  appversion='unknown'
fi
target=$(</var/www/html/InvoiceShelf/docker_target)

echo "
-------------------------------------
InvoiceShelf Version: $appversion ($target)
InvoiceShelf Commit:  $shorthash
https://github.com/InvoiceShelf/InvoiceShelf/commit/$longhash
-------------------------------------"

if [ -n "$STARTUP_DELAY" ]
	then echo "**** Delaying startup ($STARTUP_DELAY seconds)... ****"
	sleep $STARTUP_DELAY
fi

echo "**** Make sure the /conf /data folders exist ****"
[ ! -d /conf ] && mkdir -p /conf
[ ! -d /data ] && mkdir -p /data

echo "**** Link storage ****"
[ ! -L /var/www/html/InvoiceShelf/storage ] && \
	cp -r /var/www/html/InvoiceShelf/storage/* /data && \
	rm -r /var/www/html/InvoiceShelf/storage && \
	ln -s /data /var/www/html/InvoiceShelf/storage

echo "**** Expose storage ****"
[ ! -L /var/www/html/InvoiceShelf/public/storage ] && \
	ln -s /data/app/public /var/www/html/InvoiceShelf/public/storage

cd /var/www/html/InvoiceShelf

if [ "$DB_CONNECTION" = "sqlite" ] || [ -z "$DB_CONNECTION" ]
	then if [ -n "$DB_DATABASE" ]
		then if [ ! -e "$DB_DATABASE" ]
			then echo "**** Specified sqlite database doesn't exist. Creating it ****"
			echo "**** Please make sure your database is on a persistent volume ****"
			touch "$DB_DATABASE"
			chown www-data:www-data "$DB_DATABASE"
		fi
		chown www-data:www-data "$DB_DATABASE"
	else DB_DATABASE="/var/www/html/InvoiceShelf/database/database.sqlite"
		export DB_DATABASE
		if [ ! -L database/database.sqlite ]
			then [ ! -e /conf/database.sqlite ] && \
			echo "**** Copy the default database to /conf ****" && \
			cp database/database.sqlite /conf/database.sqlite
			echo "**** Create the symbolic link for the database ****"
			rm database/database.sqlite
			ln -s /conf/database.sqlite database/database.sqlite
			chown -h www-data:www-data /conf /conf/database.sqlite database/database.sqlite
		fi
	fi
fi

echo "**** Copy the .env to /conf ****" && \
[ ! -e /conf/.env ] && \
	sed 's|^#DB_DATABASE=$|DB_DATABASE='$DB_DATABASE'|' /var/www/html/InvoiceShelf/.env.example > /conf/.env
[ ! -L /var/www/html/InvoiceShelf/.env ] && \
	ln -s /conf/.env /var/www/html/InvoiceShelf/.env
echo "**** Inject .env values ****" && \
	/inject.sh

create_admin_user() {
  if [ "$ADMIN_USER" != '' ]; then
    if [ "$ADMIN_PASSWORD" != '' ]; then
      value=$ADMIN_PASSWORD
    elif [ -e "$ADMIN_PASSWORD_FILE" ] ; then
      value=$(<$ADMIN_PASSWORD_FILE)
    fi
    if [ "$value" != '' ]; then
      echo "**** Creating admin account ****" && \
      php artisan lychee:create_user "$ADMIN_USER" "$value"
    fi
  fi
}

[ ! -e /tmp/first_run ] && \
  echo "**** Setting up artisan permissions ****"
  chmod +x artisan
	echo "**** Generate the key (to make sure that cookies cannot be decrypted etc) ****" && \
	./artisan key:generate -n && \
	echo "**** Migrate the database ****" && \
	./artisan migrate --force && \
	create_admin_user && \
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
touch /data/logs/laravel.log

if [ -n "$SKIP_PERMISSIONS_CHECKS" ] && [ "${SKIP_PERMISSIONS_CHECKS,,}" = "yes" ] ; then
	echo "**** WARNING: Skipping permissions check ****"
else
	echo "**** Set Permissions ****"
	# Set ownership of directories, then files and only when required.
	find /data -type d \( ! -user "$USER" -o ! -group "$USER" \) -exec chown -R "$USER":"$USER" \{\} \;
	find /conf/.env /data \( ! -user "$USER" -o ! -group "$USER" \) -exec chown "$USER":"$USER" \{\} \;
	find /data -type d \( ! -perm -ug+w -o ! -perm -ugo+rX -o ! -perm -g+s \) -exec chmod -R ug+w,ugo+rX,g+s \{\} \;
	find /conf/.env /data \( ! -perm -ug+w -o ! -perm -ugo+rX \) -exec chmod ug+w,ugo+rX \{\} \;
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