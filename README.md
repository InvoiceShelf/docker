# InvoiceShelf Docker

![Supports amd64 Architecture][amd64-shield]
![Supports arm64/aarch64 Architecture][arm64-shield]

Run InvoiceShelf in production with the official image, nginx, and PHP-FPM.
The supplied Compose examples follow InvoiceShelf's recommended production
configuration.

> This image is for operators and end users. If you are developing InvoiceShelf,
> use the main [InvoiceShelf repository](https://github.com/InvoiceShelf/InvoiceShelf)
> and its development Docker environment instead.

## Choose an image tag

Images are published on release. Choose the tag that matches the release stream
you intend to run:

- `:latest` — newest stable release, currently the v2 line.
- `:2` / `:3` — newest stable release of a major version, once that major is stable.
- `:2.4` / `:2.4.0` — newest stable patch of a minor version, or an exact version.
- `:beta` — latest beta for the current stable line; not for production.
- `:next` — newer-major prerelease; not for production.
- `:3.0.0-beta.1` … — a pinned prerelease.

- Use `:latest` for the supported stable release, or pin a major (`:2`) or
  exact version (`:2.4.0`) when you need tighter upgrade control.
- Use `:beta` only to test an upcoming release in the stable major line. Use
  `:next` to test the next major before it is stable.
- `:latest` moves to a new major only after that major is released as stable.
  A regular `docker compose pull` will not silently turn a stable 2.x
  installation into an unreleased 3.x installation.

`:nightly` is transitional only. It currently points to the stable image so
existing installations can migrate safely, but it will stop updating. Change it
to `:latest`; `:nightly` is not a nightly build stream. See the
[Docker upgrade guide](upgrade-guide.md) for migration details.

## Run with Docker Compose

Use one of the included Compose files. SQLite has the smallest footprint and no
separate database service; MySQL/MariaDB and PostgreSQL are available when you
need an external database service.

1. Choose `docker-compose.sqlite.yml`, `docker-compose.mysql.yml`, or
   `docker-compose.pgsql.yml`.
2. Copy it to `docker-compose.yml` in a directory for this installation.
3. Review and set the environment values, especially URLs, database credentials,
   and passwords.
4. Start it with `docker compose up -d`.

The provided files use `invoiceshelf/invoiceshelf:latest`. Change the image tag
before first start if you prefer a pinned major or exact version.

### Upgrade a Compose installation

Docker images are already built; do not add `--build` when upgrading. From the
directory containing your Compose file, pull the selected image and recreate the
application with it:

```bash
docker compose pull
docker compose up -d
```

Your named volumes retain application data. You can remove unused image layers
later with `docker image prune` if desired.

The in-app updater is disabled in Docker. Update Docker installations through
the image tag and Compose commands above, rather than from the InvoiceShelf user
interface.

## Run with Docker

To use the built-in SQLite, no external dependencies are required. At its simplest:

```bash
docker run -d \
    --name=invoiceshelf \
    -v ./invoiceshelf/storage:/var/www/html/storage \
    -v ./invoiceshelf/modules:/var/www/html/Modules \
    -e APP_NAME=InvoiceShelf \
    -e APP_ENV=production \
    -e APP_DEBUG=false \
    -e APP_URL=http://localhost:8090 \
    -e DB_CONNECTION=sqlite \
    -e DB_DATABASE=/var/www/html/storage/app/database.sqlite \
    -e CACHE_STORE=file \
    -e SESSION_DRIVER=file \
    -e SESSION_LIFETIME=240 \
    -e SESSION_DOMAIN=localhost \
    -e SANCTUM_STATEFUL_DOMAINS=localhost:8090 \
    -p 8090:8080 \
    invoiceshelf/invoiceshelf:latest
```

This starts InvoiceShelf on port 8090. The mounted `./invoiceshelf/storage`
directory persists the application storage and SQLite database at
`storage/app/database.sqlite`.

## Advanced configuration

InvoiceShelf images are built on top of the `serversideup/php` image. This
preserves the image's standard PHP, nginx, and PHP-FPM architecture while
allowing its supported runtime configuration.

For advanced configuration, refer to the
[serversideup/php documentation](https://github.com/serversideup/docker-php).

[arm64-shield]: https://img.shields.io/badge/arm64-yes-success.svg?style=flat
[amd64-shield]: https://img.shields.io/badge/amd64-yes-success.svg?style=flat
