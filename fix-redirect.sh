#!/bin/bash

# Script to fix the Django redirect issue

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Fixing Django redirect and SSL configuration..."

ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop the container
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}

    # Create a new container with proper configuration
    docker run -d --name ${CONTAINER_NAME} \\
      --network dadpars_deploy_dadpars_network \\
      -p 8000:8000 \\
      -e DEBUG=0 \\
      -e DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db \\
      -e ALLOWED_HOSTS=localhost,127.0.0.1,37.32.13.22,dadpars.ir,www.dadpars.ir \\
      -e SECRET_KEY=django-insecure-production-key-replace-with-real-key \\
      -e DJANGO_SETTINGS_MODULE=dadpars_site.settings_production \\
      -e SECURE_SSL_REDIRECT=False \\
      -e SECURE_PROXY_SSL_HEADER=HTTPS,X-Forwarded-Proto \\
      -e USE_X_FORWARDED_HOST=True \\
      -v dadpars_deploy_static_volume:/app/staticfiles \\
      -v dadpars_deploy_media_volume:/app/media \\
      --restart unless-stopped \\
      dadpars_deploy-web \\
      gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 --access-logfile - --error-logfile - dadpars_site.wsgi:application

    # Wait for the container to start
    sleep 10

    # Check if it's responding correctly
    echo 'Checking container status...'
    docker ps | grep ${CONTAINER_NAME}

    # Test HTTP request with proper headers
    echo 'Testing with HTTP headers...'
    curl -H 'Host: dadpars.ir' \\
         -H 'X-Forwarded-Proto: https' \\
         -H 'X-Forwarded-Host: dadpars.ir' \\
         -I http://localhost:8000

    # Show logs
    echo 'Recent logs:'
    docker logs ${CONTAINER_NAME} --tail 10
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Configuration updated!"
echo ""
echo "The site should now work correctly with nginx."
echo "Please try accessing http://dadpars.ir or https://dadpars.ir"
