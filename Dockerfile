FROM debian:bookworm-slim as base

# Set version label
LABEL maintainer="invoiceshelf"

# Environment variables
ENV PUID='1000'
ENV PGID='1000'
ENV USER='invoiceshelf'
ENV PHP_TZ=UTC

# Arguments
# To use the latest InvoiceShelf release instead of master pass `--build-arg TARGET=release` to `docker build`
ARG TARGET=dev
# To install composer development dependencies, pass `--build-arg COMPOSER_NO_DEV=0` to `docker build`
ARG COMPOSER_NO_DEV=1

# Install base dependencies, add user and group, clone the repo and install php libraries
RUN \
    set -ev && \
    apt-get update && \
    apt-get upgrade -qy && \
    apt-get install -qy --no-install-recommends\
    adduser \
    nginx-light \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-sqlite3 \
    php8.2-imagick \
    php8.2-mbstring \
    php8.2-gd \
    php8.2-xml \
    php8.2-zip \
    php8.2-fpm \
    php8.2-redis \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-curl \
    curl \
    git \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    cron \
    composer \
    zip \
    unzip && \
    addgroup --gid "$PGID" "$USER" && \
    adduser --gecos '' --no-create-home --disabled-password --uid "$PUID" --gid "$PGID" "$USER" && \
    cd /var/www/html && \
    if [ "$TARGET" = "release" ] ; then RELEASE_TAG=$(curl -sX GET "https://api.github.com/repos/InvoiceShelf/InvoiceShelf/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]'); fi && \
    if [ ! -z "$RELEASE_TAG" ] ; then RELEASE_TAG="--branch $RELEASE_TAG"; fi && \
    git clone https://github.com/InvoiceShelf/InvoiceShelf.git $RELEASE_TAG --single-branch && \
    mv InvoiceShelf/.git/refs/heads/master InvoiceShelf/master || cp InvoiceShelf/.git/HEAD InvoiceShelf/master && \
    mv InvoiceShelf/.git/HEAD InvoiceShelf/HEAD && \
    rm -r InvoiceShelf/.git/* && \
    mkdir -p InvoiceShelf/.git/refs/heads && \
    mv InvoiceShelf/HEAD InvoiceShelf/.git/HEAD && \
    mv InvoiceShelf/master InvoiceShelf/.git/refs/heads/master && \
    echo "$TARGET" > /var/www/html/InvoiceShelf/docker_target && \
    echo "$RELEASE_TAG" > /var/www/html/InvoiceShelf/version.md && \
    cd /var/www/html/InvoiceShelf && \
    echo "Last release: $(cat version.md)" && \
    composer install --prefer-dist && \
    find . -wholename '*/[Tt]ests/*' -delete && \
    find . -wholename '*/[Tt]est/*' -delete && \
    rm -r storage/framework/cache/data/* 2> /dev/null || true && \
    rm    storage/framework/sessions/* 2> /dev/null || true && \
    rm    storage/framework/views/* 2> /dev/null || true && \
    rm    storage/logs/* 2> /dev/null || true && \
    chown -R www-data:www-data /var/www/html/InvoiceShelf && \
    echo "* * * * * www-data cd /var/www/html/InvoiceShelf && php artisan schedule:run >> /dev/null 2>&1" >> /etc/crontab && \
    apt-get purge -y --autoremove git composer && \
    apt-get clean -qy &&\
    rm -rf /var/lib/apt/lists/*

# Multi-stage build: Build static assets
# This allows us to not include Node within the final container
FROM node:20 as static_builder

RUN mkdir /app

RUN mkdir -p  /app
WORKDIR /app
COPY --from=base /var/www/html/InvoiceShelf /app

RUN npm install
RUN yarn build

# Get the static assets built in the previous step
FROM base
COPY --from=static_builder --chown=www-data:www-data /app/public /var/www/html/InvoiceShelf/public

# Add custom Nginx configuration
COPY default.conf /etc/nginx/nginx.conf

EXPOSE 80
VOLUME /conf /data

WORKDIR /var/www/html/InvoiceShelf

COPY entrypoint.sh inject.sh /

RUN chmod +x /entrypoint.sh && \
    chmod +x /inject.sh && \
    if [ ! -e /run/php ] ; then mkdir /run/php ; fi

HEALTHCHECK CMD curl --fail http://localhost:80/ || exit 1

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "nginx" ]
