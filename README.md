![Supports amd64 Architecture][amd64-shield]
![Supports arm64/aarch64 Architecture][arm64-shield]
![Supports armv7 Architecture][armv7-shield]

## Table of Contents
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->
- [Image content](#image-content)
- [Setup](#setup)
	- [Quick Start](#quick-start)
	- [Prerequisites](#prerequisites)
	- [Run with Docker](#run-with-docker)
	- [Run with Docker Compose](#run-with-docker-compose)
- [Available environment variables and defaults](#available-environment-variables-and-defaults)
- [Advanced configuration](#advanced-configuration)
<!-- /TOC -->

## Image Content

This image features InvoiceShelf, nginx and PHP-FPM. The provided configuration (PHP, nginx...) follows InvoiceShelf's official recommendations.

The following tags are available :

* `latest`: Latest InvoiceShelf release
* `v[NUMBER]`: Stable version tag for a InvoiceShelf release
* `nightly` (also `dev`): Current master branch tag (InvoiceShelf operates on a stable master, so this should usually be safe)
* `devtools`: As above, but includes development dependencies
* `testing`: Tag for testing new branches and pull requests. Designed for internal use by InvoiceShelf.

## Setup

### Quick Start

To use the built-in SQLite support, no external dependencies are required. At its simplest, `docker run -p 80 InvoiceShelf/invoiceshelf:dev` will start InvoiceShelf listening on a random port on the local host.

For more runtime options, look below in [Run with Docker](#run-with-docker) and [Available environment variables and defaults](#available-environment-variables-and-defaults).

### Prerequisites

To use this image with MySQL, MariaDB or PostgreSQL you will need a suitable database running externally. This may be through a Docker image, possibly in your `docker-compose.yml`.

1.  Create the db, username, password.
2.  Edit the environment variables (db credentials, language...) by :
    *  Supplying the environment variables via `docker run` / `docker-compose` **or**
    *  Creating a `.env` file with the appropriate info and mount it to `/conf/.env` **or**
    *  Use the InvoiceShelf installer by passing `-e DB_CONNECTION=` on the command line and connecting to the container with your browser

### Run with Docker

**Make sure that you link to the container running your database !!**  

The example below shows `--net` and `--link` for these purposes. `--net` connects to the name of the network your database is on and `--link` connects to the database container.

```bash
docker run -d \
--name=invoiceshelf \
-v /host_path/invoiceshelf/conf:/conf \
-v /host_path/invoiceshelf/uploads:/uploads \
-v /host_path/invoiceshelf/sym:/sym \
-e PUID=1000 \
-e PGID=1000 \
-e PHP_TZ=America/New_York \
-e TIMEZONE=America/New_York \
-e DB_CONNECTION=mysql \
-e DB_HOST=mariadb \
-e DB_PORT=3306 \
-e DB_DATABASE=invoiceshelf \
-e DB_USERNAME=user \
-e DB_PASSWORD=password \
-p 90:80 \
--net network_name \
--link db_name \
InvoiceShelf/invoiceshelf
```

**Warning** : if you use a MySQL database, make sure to use the `mysql_native_password` authentication plugin, either by using the `--default-authentication-plugin` option when starting mysql, or by running a query to enable the authentication plugin for the `invoiceshelf` user, e.g. :

```
alter user 'invoiceshelf' identified with mysql_native_password by '<your password>';
```

### Run with Docker Compose

To run with `docker-compose` follow the steps:

1. Copy the `docker-compose.yml.example` to `docker-compose.yml`
2. Change the environment variables in the [provided example](./docker-compose.yml.example) to reflect your database credentials.

Note that in order to avoid writing credentials directly into the file, you can create a `db_secrets.env` and use the `env_file` directive (see the [docs](https://docs.docker.com/compose/environment-variables/#the-env_file-configuration-option)).

### Docker secrets

As an alternative to passing sensitive information via environment variables, _FILE may be appended to some of the environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in /run/secrets/<secret_name> files.

If both the original variable and the _FILE (e.g. both DB_PASSWORD and DB_PASSWORD_FILE) are set, the original variable will be used.

The following _FILE variables are supported:

* DB_PASSWORD_FILE
* REDIS_PASSWORD_FILE 
* MAIL_PASSWORD_FILE
* ADMIN_PASSWORD_FILE

## Available environment variables and defaults

If you do not provide environment variables or `.env` file, the [example .env file](https://github.com/InvoiceShelf/InvoiceShelf/blob/master/.env.example) will be used with some values already set by default.

Some variables are specific to Docker, and the default values are :

* `PUID=1000`
* `PGID=1000`
* `USER=invoiceshelf`
* `PHP_TZ=UTC`
* `STARTUP_DELAY=0`

Additionally, if `SKIP_PERMISSIONS_CHECKS` is set to "yes", the entrypoint script will not check or set the permissions of files and directories on startup. Users are strongly advised **against** using this option, and efforts have been made to keep the checks as fast as possible. Nonetheless, it may be suitable for some advanced use cases.

## Advanced configuration

Note that nginx will accept by default images up to 100MB (`client_max_body_size 100M`) and that PHP parameters are overridden according to the [recommendations of the InvoiceShelf FAQ](https://InvoiceShelf.github.io/docs/faq.html#i-cant-upload-large-photos).

You may still want to further customize PHP configuration. The first method is to mount a custom `php.ini` to `/etc/php/8.2/fpm/php.ini` when starting the container. However, this method is kind of brutal as it will override all parameters. It will also need to be remapped whenever an image is released with a new version of PHP.

Instead, we recommend to use the `PHP_VALUE` directive of PHP-FPM to override specific parameters. To do so, you will need to mount a custom `nginx.conf` in your container :

1. Take the [default.conf](./default.conf) file as a base
2. Find the line starting by `fastcgi_param PHP_VALUE [...]`
3. Add a new line and set your new parameter
4. Add or change any other parameters (e.g. `client_max_body_size`)
5. Mount your new file to `/etc/nginx/nginx.conf`

If you need to add (not change) nginx directives, files mounted in `/etc/nginx/conf.d/` will be included in the `http` context.

[arm64-shield]: https://img.shields.io/badge/arm64-yes-success.svg?style=flat
[amd64-shield]: https://img.shields.io/badge/amd64-yes-success.svg?style=flat
[armv7-shield]: https://img.shields.io/badge/armv7-yes-success.svg?style=flat
