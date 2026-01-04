#!/bin/bash
# Quick shell access to the test container

CONTAINER="dotfiles-test"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "Container not running. Starting..."
    cd "$(dirname "$0")"
    docker compose up -d
    sleep 2
fi

echo "Opening shell as testuser..."
docker exec -it -u testuser $CONTAINER /bin/bash
