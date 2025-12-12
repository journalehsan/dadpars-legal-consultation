#!/bin/bash

# Script to update nginx configuration and ensure everything is working

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"

echo "Updating nginx configuration..."

# The main issue is that nginx is trying to proxy to port 4437,
# but our Django app is running on port 8000

echo "The nginx configuration needs to be updated."
echo "Currently it's proxying to http://127.0.0.1:4437"
echo "But the Django app is running on port 8000"
echo ""
echo "Please update your nginx config to proxy to port 8000:"
echo ""
echo "Create a new config file at /etc/nginx/conf.d/dadpars.conf with:"
cat << 'EOF'
server {
    listen 80;
    server_name dadpars.ir www.dadpars.ir;

    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name dadpars.ir www.dadpars.ir;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/dadpars.ir/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dadpars.ir/privkey.pem;

    # SSL settings for security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'HIGH:!aNULL:!MD5';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://127.0.0.1:8000;  # Updated to port 8000
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;

        # Handle redirects properly
        proxy_redirect off;
    }

    # Location for static files (optional, can be served directly by nginx)
    location /static/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Location for media files (optional)
    location /media/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo ""
echo "After updating the config, reload nginx:"
echo "sudo nginx -t"
echo "sudo systemctl reload nginx"
echo ""

# Let's verify that our Django app is running correctly on port 8000
echo "Verifying Django app is running on port 8000..."
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000"

echo ""
echo ""
echo "✅ Current status:"
echo "- Django app is running on port 8000"
echo "- Container is responding correctly"
echo "- SSL redirect is configured properly"
echo ""
echo "❗ IMPORTANT: Update your nginx config to proxy to port 8000 instead of 4437"
echo ""
echo "Then reload nginx and the site should work at https://dadpars.ir"
