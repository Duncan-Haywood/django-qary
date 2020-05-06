#!/usr/bin/env bash
set -e

export NODE_NAME='web'
if [ -n "$2" ]
then
    export NODE_NAME=$2
fi

echo ''
if [ "$1" == 'prod' ]
then
    export MIDATA_HOST_PATH="$HOME/midata"
    export MIDATA_HOST_PATH_PRIVATE="$MIDATA_HOST_PATH/private"

    if [ "$NODE_NAME" == 'clean' ] ;
    then
        rm -rf "$MIDATA_HOST_PATH_PRIVATE"
    fi

    #volumes required by django (2), elasticsearch (1), and postgres (1)
    mkdir -p "$MIDATA_HOST_PATH_PRIVATE/static_volume"
    mkdir -p "$MIDATA_HOST_PATH_PRIVATE/media_volume"
    mkdir -p "$MIDATA_HOST_PATH_PRIVATE/esdata"
    mkdir -p "$MIDATA_HOST_PATH_PRIVATE/postgres_data"
    mkdir -p "$MIDATA_HOST_PATH/public"

    if [ -f "$MIDATA_HOST_PATH/public/models/nlpia-bot-data"] ;
    then

    fi

    chown -R root:docker "$MIDATA_HOST_PATH"
    chmod -R ugo+rwx "$MIDATA_HOST_PATH"
    chown -R root:docker "$MIDATA_HOST_PATH"
    chmod -R 775 "$MIDATA_HOST_PATH"

    echo '***STOPPING ALL CONTAINERS***'
    docker-compose -f docker-compose.prod.yml down -v --remove-orphans

    echo ''
    echo 'Building and bringing up docker-compose.prod.yml docker images ...'
    docker-compose -f docker-compose.prod.yml up -d --build

    echo 'Migrating DB in PROD containers with exec web python manage.py migrate (without --no-input)'
    docker-compose  -f docker-compose.prod.yml exec --user app web python manage.py migrate

    echo ''
    echo 'Collecting static in PROD containers for the webapp with exec web python manage.py collect static ...'
    docker-compose  -f docker-compose.prod.yml exec --user app web python manage.py collectstatic --no-input  # --clear

    # chown -R root:docker "$MIDATA_HOST_PATH"
    # chmod -R 775 "$MIDATA_HOST_PATH"
    # chmod -R a+w ~/midata/private/media_volume/
elif [ "$1" == 'wiki' ]
then
    echo 'Indexing wikipedia categories and testing Elasticsearch'
    docker-compose  -f docker-compose.prod.yml exec --user app web python index_wikipedia.py
elif [ "$1" == 'logs' ]
then
    echo "Indexing wikipedia categories and testing Elasticsearch"
    docker-compose  -f docker-compose.prod.yml exec logs -f
elif [ "$1" == 'dev' ]
then
    MIDATA_HOST_PATH="$HOME/midata"
    MIDATA_HOST_PATH_PRIVATE="MIDATA_HOST_PATH/private"
    chmod -R 775 "$MIDATA_HOST_PATH"
    mkdir -p "$MIDATA_HOST_PATH"
    mkdir -p "$MIDATA_HOST_PATH_PRIVATE"

    echo '***STOPPING ALL CONTAINERS***'
    docker-compose -f docker-compose.dev.yml down -v --remove-orphans

    echo ''
    echo 'Building development docker image with nginx path=$MIDATA_HOST_PATH ...'
    docker-compose -f docker-compose.dev.yml up -d --build
    echo "Running exec web python manage.py migrate (without --no-input)"
    docker-compose -f docker-compose.dev.yml exec web python manage.py migrate

    echo ""
    echo "Starting development containers for the webapp at http://localhost:8000/ ..."
    docker-compose -f docker-compose.dev.yml exec web python manage.py collectstatic --no-input --clear
elif [ "$1" == 'stop' ]
then
    echo '***STOPPING ALL CONTAINERS***'
    docker-compose -f docker-compose.prod.yml down -v --remove-orphans
    docker-compose -f docker-compose.dev.yml down -v --remove-orphans
elif [ "$1" == 'up' ]
then
    echo ""
    echo "Bringing up docker-compose.PROD.yml docker image named $NODE_NAME ..."
    docker-compose -f docker-compose.prod.yml up -d
elif [ "$1" == 'shell' ]
then
    echo "exec -it on $NODE_NAME then python manage.py shell"
    export GREP_OPTIONS=
    export CONTAINERID=$(docker ps | grep -E '.*django-qary_web' | cut -c -12)
    echo "found node named $NODE_NAME at containerid $CONTAINERID"
    docker exec -it $CONTAINERID /bin/bash
else
    echo "USAGE ./build.sh [prod|wiki|dev|stop|up|shell]"
fi
