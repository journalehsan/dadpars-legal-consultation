#!/bin/bash

# Script to fix the domain configuration for dadpars.ir

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Updating domain configuration for dadpars.ir..."

# First, let's check the current logs to see what's happening
echo "Checking current container logs..."
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "docker logs ${CONTAINER_NAME} --tail 30"

# Update the docker-compose.yml with proper configuration
ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop the containers
    docker-compose down

    # Update docker-compose.yml with proper ALLOWED_HOSTS
    cat > docker-compose.yml << 'EOFF'
services:
  db:
    image: postgres:15
    container_name: dadparsir-db
    environment:
      POSTGRES_DB: dadpars_db
      POSTGRES_USER: dadpars_user
      POSTGRES_PASSWORD: dadpars_password_1403
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    restart: unless-stopped
    networks:
      - dadpars_network

  web:
    build: .
    container_name: dadparsir-web
    command: >
      sh -c 'python manage.py makemigrations &&
             python manage.py migrate &&
             python manage.py collectstatic --noinput --clear &&
             gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 dadpars_site.wsgi:application'
    volumes:
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - '8000:8000'
    depends_on:
      - db
    environment:
      - DEBUG=0
      - DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db
      - ALLOWED_HOSTS=localhost,127.0.0.1,37.32.13.22,dadpars.ir,www.dadpars.ir
      - SECRET_KEY=django-insecure-production-key-replace-with-real-key
      - DJANGO_SETTINGS_MODULE=dadpars_site.settings_production
      - USE_TZ=True
      - SECURE_SSL_REDIRECT=False
      - SECURE_PROXY_SSL_HEADER=HTTPS,X-Forwarded-Proto
    restart: unless-stopped
    networks:
      - dadpars_network

volumes:
  postgres_data:
  static_volume:
  media_volume:

networks:
  dadpars_network:
    driver: bridge
EOFF

    # Start containers with new configuration
    docker-compose up -d

    # Wait for containers to initialize
    sleep 15

    # Check container status
    docker ps | grep dadparsir

    # Check if the service is responding on port 8000
    curl -I http://localhost:8000 || echo 'Service not responding on port 8000'
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "Configuration updated!"
echo ""
echo "Now updating the nginx configuration to fix the issue..."

# The nginx config looks correct, but let's update the docker container port mapping
# to ensure nginx can connect to it properly
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "docker stop ${CONTAINER_NAME} && \
     docker rm ${CONTAINER_NAME} && \
     docker run -d --name ${CONTAINER_NAME} \
       --network dadpars_deploy_dadpars_network \
       -p 8000:8000 \
       -e DEBUG=0 \
       -e DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db \
       -e ALLOWED_HOSTS=localhost,127.0.0.1,37.32.13.22,dadpars.ir,www.dadpars.ir \
       -e SECRET_KEY=django-insecure-production-key-replace-with-real-key \
       -e DJANGO_SETTINGS_MODULE=dadpars_site.settings_production \
       -e SECURE_PROXY_SSL_HEADER=HTTPS,X-Forwarded-Proto \
       -v dadpars_deploy_static_volume:/app/staticfiles \
       -v dadpars_deploy_media_volume:/app/media \
       --restart unless-stopped \
       dadpars_deploy-web \
       gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 dadpars_site.wsgi:application"

echo ""
echo "Container recreated with port 8000 mapping!"

# Test the connection
echo ""
echo "Testing connection to the Django application..."
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "sleep 5 && curl -I http://localhost:8000"

echo ""
echo "Configuration complete! Your site should now be accessible at:"
echo "http://dadpars.ir and https://dadpars.ir"
