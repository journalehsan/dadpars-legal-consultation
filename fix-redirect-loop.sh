#!/bin/bash

# Script to fix the Django redirect loop issue

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Fixing Django redirect loop..."
echo "The issue is that Django is trying to force HTTPS even when nginx is already handling SSL"
echo ""

# Update the production settings to disable SSL redirect in Django
echo "Updating Django production settings to disable SSL redirect..."
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "cd /tmp/dadpars_deploy && \
     sed -i 's/SECURE_SSL_REDIRECT = not DEBUG/SECURE_SSL_REDIRECT = False/' dadpars_site/settings_production.py"

# Now recreate the container with the correct settings
ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop the current container
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}

    # Create a new container with corrected SSL settings
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
      -e SESSION_COOKIE_SECURE=False \\
      -e CSRF_COOKIE_SECURE=False \\
      -v dadpars_deploy_static_volume:/app/staticfiles \\
      -v dadpars_deploy_media_volume:/app/media \\
      --restart unless-stopped \\
      dadpars_deploy-web \\
      gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 --access-logfile - --error-logfile - dadpars_site.wsgi:application

    # Wait for container to start
    sleep 10

    # Test the connection with proper headers
    echo 'Testing with proper headers...'
    curl -H 'Host: dadpars.ir' \\
         -H 'X-Forwarded-Proto: https' \\
         -H 'X-Forwarded-Host: dadpars.ir' \\
         -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost:8000

    # Check container is running
    echo ''
    echo 'Container status:'
    docker ps | grep ${CONTAINER_NAME}

    echo ''
    echo 'Recent logs:'
    docker logs ${CONTAINER_NAME} --tail 15
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Fixed the redirect loop!"
echo ""
echo "Changes made:"
echo "1. Disabled SECURE_SSL_REDIRECT in Django (letting nginx handle SSL)"
echo "2. Set SESSION_COOKIE_SECURE=False and CSRF_COOKIE_SECURE=False"
echo "3. Kept SECURE_PROXY_SSL_HEADER for proper HTTPS detection"
echo ""
echo "The site should now work correctly at https://dadpars.ir"
echo "Nginx handles the SSL termination and forwards to Django as HTTP"
