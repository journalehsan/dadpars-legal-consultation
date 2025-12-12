#!/bin/bash

# Script to restart the Django site with proper configuration

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
NEW_CONTAINER_NAME="dadparsir-web"
POSTGRES_CONTAINER="dadparsir-db"
PORT="4437"

# Generate a new secret key
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

echo "Restarting site with new SECRET_KEY..."

ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop containers
    docker-compose down

    # Update docker-compose.yml with new secret key
    sed -i \"s/SECRET_KEY=django-insecure-production-key-change-me/SECRET_KEY=${SECRET_KEY}/\" docker-compose.yml

    # Also update ALLOWED_HOSTS to include the server IP
    sed -i \"s/ALLOWED_HOSTS=localhost,127.0.0.1,${SERVER_IP}/ALLOWED_HOSTS=localhost,127.0.0.1,${SERVER_IP},0.0.0.0/\" docker-compose.yml

    # Start containers again
    docker-compose up -d

    # Wait for startup
    sleep 10

    # Check status
    docker ps | grep dadparsir
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo "Site restarted with new configuration!"
echo "Testing site access..."

# Test site access
sleep 5
if curl -s --max-time 5 http://${SERVER_IP}:${PORT} > /dev/null; then
    echo "✓ Site is accessible at http://${SERVER_IP}:${PORT}"
else
    echo "✗ Site is not responding. Checking logs..."
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker logs ${NEW_CONTAINER_NAME} --tail 20"
fi
