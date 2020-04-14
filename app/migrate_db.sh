#!/bin/sh

if [ "$DATABASE" = "postgres" ]
then
    echo "Waiting for postgres..."

    while ! nc -z $SQL_HOST $SQL_PORT; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

echo "Running migrate_db.sh ..."
ls -hal /home/app/web/staticfiles/admin/js

python manage.py flush --no-input
python manage.py migrate upload
python manage.py collectstatic --no-input --clear

exec "$@"
