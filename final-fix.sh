#!/bin/bash

# Final fix for Django deployment issues

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"

echo "Final fix for Django deployment..."

ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop current container
    docker stop dadparsir-web 2>/dev/null || true
    docker rm dadparsir-web 2>/dev/null || true

    # Update settings.py to include dadpars.ir in ALLOWED_HOSTS
    sed -i \"s/ALLOWED_HOSTS = \\[\\]/ALLOWED_HOSTS = ['localhost', '127.0.0.1', '37.32.13.22', 'dadpars.ir', 'www.dadpars.ir']/\" dadpars_site/settings.py

    # Build the image again with updated settings
    docker-compose build web

    # Run migrations first
    docker run --rm --network dadpars_deploy_dadpars_network \\
      -e DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db \\
      dadpars_deploy-web \\
      python manage.py migrate

    # Start the web container
    docker run -d --name dadparsir-web \\
      --network dadpars_deploy_dadpars_network \\
      -p 8000:8000 \\
      -e DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db \\
      -e SECRET_KEY=django-insecure-production-key-change-me \\
      -v dadpars_deploy_static_volume:/app/staticfiles \\
      -v dadpars_deploy_media_volume:/app/media \\
      --restart unless-stopped \\
      dadpars_deploy-web \\
      gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 dadpars_site.wsgi:application

    # Wait for startup
    sleep 15

    # Collect static files
    docker exec dadparsir-web python manage.py collectstatic --noinput --clear

    # Test the response
    echo 'Testing response with Host header:'
    response=\$(curl -H 'Host: dadpars.ir' -s -o /dev/null -w '%{http_code}' http://localhost:8000)
    echo 'Status:' \$response

    if [ \"\$response\" = '200' ]; then
        echo '✅ SUCCESS! Site is working correctly'
    else
        echo '❌ Still having issues, checking logs...'
        docker logs dadparsir-web --tail 20
    fi
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Final fix completed!"
echo ""
echo "The site should now work at https://dadpars.ir"
echo "If you still see errors, please check:"
echo "1. nginx error logs: sudo tail -f /var/log/nginx/error.log"
echo "2. nginx access logs: sudo tail -f /var/log/nginx/access.log"
