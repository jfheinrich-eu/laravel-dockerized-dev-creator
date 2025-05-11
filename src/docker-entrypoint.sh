#!/bin/bash
set -e

if [ -f /var/www/html/laravel-installation-passed ]
then
	npm install && composer install

	# Generate application key if it doesn't exist
	if [ -z "$(grep '^APP_KEY=' .env | grep -v '=$')" ]; then
	    php artisan key:generate
	fi

	# Run migrations if the database is ready
	if [ "$DB_HOST" != "" ]; then
	    # Wait for the database to be ready
	    until nc -z -v -w30 $DB_HOST 3306; do
	      echo "Waiting for database connection..."
	      # Wait for 5 seconds before check again
	      sleep 5
	    done

	    php artisan migrate --force
	    npm run build
	fi
fi

# Execute the provided command (which is typically php-fpm)
exec "$@"
