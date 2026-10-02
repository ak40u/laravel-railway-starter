# FrankenPHP is the modern way to serve Laravel in one container: an application
# server with PHP built in, so there is no nginx and php-fpm pair to configure and
# keep in sync.
FROM dunglas/frankenphp:1.12.7-php8.5 AS base

RUN install-php-extensions pdo_pgsql pgsql opcache intl zip gd

WORKDIR /app

# Composer install runs against the manifests alone first, so editing application
# code reuses the cached dependency layer.
COPY composer.json composer.lock ./
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
# The scaffold was created with dev dependencies present, so bootstrap/cache holds
# a package manifest listing providers that a --no-dev install does not have.
# Leaving it in place makes every artisan command fail on a missing class.
RUN rm -f bootstrap/cache/*.php

# --no-scripts matters: package discovery boots the framework, and during a build
# there are no environment variables yet, so it fails on a missing APP_KEY.
RUN composer dump-autoload --optimize --no-dev --no-scripts

RUN chown -R www-data:www-data storage bootstrap/cache

ENV SERVER_NAME=:8080
EXPOSE 8080

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
