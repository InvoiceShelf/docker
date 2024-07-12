

![Supports amd64 Architecture][amd64-shield]  
![Supports arm64/aarch64 Architecture][arm64-shield]  
![Supports armv7 Architecture][armv7-shield]

## Table of Contents
<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->  
- [Intro](#intro)
- [Tags](#tags)
- [Setup](#setup)
	- [Quick Start](#quick-start)
	- [What we recommend](#what-we-recommend)
	- [Run with Docker Compose](#run-with-docker-compose)
		- [Compose Usage](#compose-usage)
		- [Compose Image Tags](#compose-image-tags)
		- [Compose Upgrade](#compose-upgrade)
	- [Run with Docker](#run-with-docker)
		- [Database Prerequisites](#database-prerequisites)
		- [Example with MySQL](#example-with-mysql)

- [Available environment variables and defaults](#available-environment-variables-and-defaults)
- [Advanced configuration](#advanced-configuration)
<!-- /TOC -->  

## Intro

This image features InvoiceShelf, nginx and PHP-FPM. The provided configuration (PHP, nginx...) follows InvoiceShelf's official recommendations and is meant to be used by end-users.

**Important**:  If you are developer, please check the InvoiceShelf main repository and use image within the repository for developing.

## Tags

The following tags are available:

| Docker Tag       | Purpose | Source Branch            | Build Frequency |
|------------------|--|--------------------------|--|
| :latest, :number | Latest stable released version | master (stable release) | On release |
| :nightly, :dev   | Latest stable unreleased version | master (pending release) | Nightly |
| :alpha           | Latest alpha/unstable version | develop (latest code) | Nightly |

As you can see in the above table, all docker tags have different purpose. To summarize:

- If you want to use **concrete version**, use :number (e.g. :2.0.0)
- If you want the latest stable version that is **released**, use :latest
- If you want the latest stable version that is **pending release**, use :nightly or :dev
- If you want the very latest code,  **regardless of stability**, use :alpha

Best of both worlds (stable/unstable) is **invoiceshelf/invoiceshelf:nightly**. This way you have tested changes that aren't yet released but are definitely making their way into the upcoming release.

## Setup

The docker image can be used in different ways. If you are non-advanced user, we highly recommend to run with SQLITE.

### Quick Start

To use the built-in SQLite support, no external dependencies are required. At its simplest:

```bash  
docker run -d \--name=invoiceshelf \
-v ./invoiceshelf/conf:/conf \
-v ./invoiceshelf/data:/data \
-e PHP_TZ=America/New_York \
-e TIMEZONE=America/New_York \
-e APP_NAME=InvoiceShelf \
-e APP_ENV=local \
-e APP_DEBUG=false \
-e APP_URL=http://localhost:90 \
-e SESSION_DOMAIN=localhost \
-e SANCTUM_STATEFUL_DOMAINS=localhost:90 \
-e DB_CONNECTION=sqlite \
-e STARTUP_DELAY= \
-p 90:80 \
invoiceshelf/invoiceshelf
```  

will start InvoiceShelf listening on a port 90 and the data will be persisted in ./invoiceshelf/ directory.

For more runtime options, look below in [Run with Docker Compose](#run-with-docker-compose), [Run with Docker](#run-with-docker) and [Available environment variables and defaults](#available-environment-variables-and-defaults).

### Our recommendation

We recommend to follow [Run with Docker Compose](#run-with-docker-compose) examples to keep it simple.

If you have a massive amounts of data, you can use the MySQL/Postgres variants, otherwise, just use SQLite.

By using SQLite you don't run separate database server and your database is portable with the _database.sqlite_ file.

### Run with Docker Compose

#### Compose Usage

The recommended way to run InvoiceShelf is by utilizing the provided docker-compose.yaml files within this repository. You are free to modify those. The desired workflow is basically as follows:

1. Decide which database you want to use (sqlite, mysql, postgresql).
2.  Copy the compose file. E.g. for sqlite you need to copy  `docker-compose.sqlite.yml` to `docker-compose.yml`
3. Change the environment variables to reflect your desired setup
4. Execute `docker compose up` to run it, and `docker compose down` to shut down

#### Compose Upgrade

To upgrade the image, you should do the following:

1. Shut down your current environment:
   `docker compose down`
2. Pull the latest image version:
   `docker compose pull`
3. Start and rebuild:
   `docker compose up --force-recreate --build -d`
4. Prune/clean up the old/unused images:
   `docker image prune`

#### Compose Image Tags

By default all the provided docker-compose.{db}.yaml files are using the `:nightly` tag.  If you don't want this tag you can switch to different in the desired docker-compose file. For more details refer to the [Tags](#tags) section.

**Note**: After switching to different tag, you need to rebuild by following the [Upgrades](#upgrades) guide above.

### Run with Docker

#### Database Prerequisites

To use this image with MySQL, MariaDB or PostgreSQL you will need a suitable database running externally.

1. Create the db, username, password.
2. Edit the environment variables (db credentials, language...) by :
	* Supplying the environment variables via `docker run` / `docker-compose` **or**
* Creating a `.env` file with the appropriate info and mount it to `/conf/.env` **or**
* Use the InvoiceShelf installer by passing `-e DB_CONNECTION=` on the command line and connecting to the container with your browser

#### Example with MySQL

**Make sure that you link to the container running your database !!**

The example below shows `--net` and `--link` for these purposes. `--net` connects to the name of the network your database is on and `--link` connects to the database container.

```bash  
docker run -d --name=invoiceshelf \
-v ./invoiceshelf/conf:/conf \
-v ./invoiceshelf/data:/data \
-e PHP_TZ=America/New_York \
-e TIMEZONE=America/New_York \
-e APP_NAME=Laravel \
-e APP_ENV=local \
-e APP_DEBUG=true \
-e APP_URL=http://localhost:90 \
-e DB_CONNECTION=mysql \
-e DB_HOST=invoiceshelf_db \
-e DB_PORT=3306 \
-e DB_DATABASE=invoiceshelf \
-e DB_USERNAME=invoiceshelf \
-e DB_PASSWORD=somepass \
-e DB_PASSWORD_FILE="" \
-e CACHE_STORE=file \
-e SESSION_DRIVER=file \
-e SESSION_LIFETIME=120 \
-e SESSION_ENCRYPT=false \
-e SESSION_PATH="/" \
-e SESSION_DOMAIN=localhost \
-e SANCTUM_STATEFUL_DOMAINS=localhost:90 \
-e STARTUP_DELAY=2 \
-p 90:80 \
--net network_name \
--link db_name \
invoiceshelf/invoiceshelf:alpha  
```  

**Warning** : if you use a MySQL database, make sure to use the `mysql_native_password` authentication plugin, either by using the `--default-authentication-plugin` option when starting mysql, or by running a query to enable the authentication plugin for the `invoiceshelf` user, e.g. :

```  
alter user 'invoiceshelf' identified with mysql_native_password by '<your password>';  
```  

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

If you want to  customize PHP the configuration, the first method is to mount a custom `php.ini` to `/etc/php/8.2/fpm/php.ini` when starting the container. However, this method is kind of brutal as it will override all parameters. It will also need to be remapped whenever an image is released with a new version of PHP.

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
