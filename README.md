
![Supports amd64 Architecture][amd64-shield]  ![Supports arm64/aarch64 Architecture][arm64-shield]  ![Supports armv7 Architecture][armv7-shield]

## Introduction

This image features InvoiceShelf, nginx and PHP-FPM. The provided configuration (PHP, nginx...) follows InvoiceShelf's official recommendations and is meant to be used by end-users.

**Important**: If you are a developer, please check the InvoiceShelf main repository and use the docker/development image for development.

## How tags work

The following tags are available:

| Docker Tag       | Purpose | Source Branch            | Build Frequency |
|------------------|--|--------------------------|--|
| :latest, :number | Latest stable released version | master (stable release) | On release |
| :nightly         | Latest stable unreleased version | master (pending release) | Nightly |
| :alpha           | Latest alpha/unstable version | develop (latest code) | Nightly |

As you can see in the above table, all docker tags have different purpose. To summarize:

- If you want to use **concrete version**, use :number (e.g. :2.0.0)
- If you want the latest stable version that is **released**, use :latest
- If you want the latest stable version that is **pending release**, use :nightly or :dev
- If you want the very latest code,  **regardless of stability**, use :alpha

The best of both worlds (stable/unstable) is **invoiceshelf/invoiceshelf:nightly**. This way you have tested changes that aren't yet released but are definitely making their way into the upcoming release.

## Run with Docker Compose (Recommended)

### 1. Docker-compose Usage

The recommended way to run InvoiceShelf is by using the provided docker-compose.yaml files within this repository.

If you like a small footprint and no external dependencies, you can use the `docker-compose.sqlite.yml` file. By using SQLite you don't run a database server, and your database is easily portable with the _database.sqlite_ file.

The desired workflow is basically as follows:

1. Decide which database you want to use (sqlite, mysql, postgresql).
2. Copy the docker-compose file. E.g., for SQLite you need to copy  `docker-compose.sqlite.yml` to `docker-compose.yml`
3. Change the environment variables to reflect your desired setup
4. Execute `docker compose up` to run it, and `docker compose down` to shut down

### 2. Docker-compose Upgrade

Once a new version of InvoiceShelf is released, we also release a new Docker image.

To pull the latest version, you need to spin down, pull, rebuild and spin up again.

1. Shut down your current environment:
   `docker compose down`
2. Pull the latest image version:
   `docker compose pull`
3. Start and rebuild:
   `docker compose up --force-recreate --build -d`
4. Prune/clean up the old/unused images:
   `docker image prune`

### 3. Docker-compose Image Tags

By default, all the provided docker-compose.{db}.yaml files are using the `:nightly` tag. The :nightly tag is updated every night with the latest stable code from the `master` branch.

For more details see: [How tags work](#how-tags-work) section.

## Run with Docker

To use the built-in SQLite, no external dependencies are required. At its simplest:

```bash  
docker run -d \
    --name=invoiceshelf \
    -v ./invoiceshelf/storage:/var/www/html/storage \
    -e APP_NAME=InvoiceShelf \
    -e APP_ENV=production \
    -e APP_DEBUG=false \
    -e APP_URL=http://localhost:8090 \
    -e DB_CONNECTION=sqlite \
    -e DB_DATABASE=/var/www/html/database/database.sqlite \
    -e CACHE_STORE=file \
    -e SESSION_DRIVER=file \
    -e SESSION_LIFETIME=240 \
    -e SESSION_DOMAIN=localhost \
    -e SANCTUM_STATEFUL_DOMAINS=localhost:8090 \
    -p 8090:8080 \
    invoiceshelf/invoiceshelf:nightly
```

This will start the InvoiceShelf instance on port 8090. The data will be persisted in ./invoiceshelf/storage for the `storage` directory and `./invoiceshelf/database` for the SQLite database.

## Advanced configuration

InvoiceShelf images are built on top of the `serversideup/php` image. 

For more advanced configuration, please refer to the [serversideup/php](https://github.com/serversideup/docker-php) repository.

[arm64-shield]: https://img.shields.io/badge/arm64-yes-success.svg?style=flat
[amd64-shield]: https://img.shields.io/badge/amd64-yes-success.svg?style=flat
[armv7-shield]: https://img.shields.io/badge/armv7-yes-success.svg?style=flat
