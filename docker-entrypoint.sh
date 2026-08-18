#!/bin/sh
set -e

# APP_KEY has no default on purpose. Laravel uses it to encrypt sessions and
# cookies; a template that ships one would hand the same key to every deployment
# made from it.
if [ -z "$APP_KEY" ]; then
  echo "APP_KEY is not set. Generate one with: php artisan key:generate --show" >&2
  exit 1
fi

# Railway keeps the image entrypoint in place and passes the pre-deploy command
# (and any custom start command) to it as arguments. Without this branch those
# arguments are discarded and the web server starts instead: `php artisan migrate`
# would report nothing and never touch the database, while the deployment waits
# for a command that does not exit.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Caching happens here, not in the Dockerfile. `config:cache` freezes the values
# of environment variables into a PHP file - run at build time it would bake in
# whatever existed then, which on this platform is nothing, and your database
# credentials would silently be empty at runtime.
php artisan package:discover --ansi
php artisan config:cache
php artisan route:cache
php artisan view:cache

# FrankenPHP binds the port from SERVER_NAME, which Railway supplies as PORT.
export SERVER_NAME=":${PORT:-8080}"

exec frankenphp run --config /etc/frankenphp/Caddyfile
