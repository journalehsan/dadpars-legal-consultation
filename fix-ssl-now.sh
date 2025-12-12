#!/bin/bash

# Quick script to immediately renew the expired dadpars.ir certificate

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
DOMAIN="dadpars.ir"

echo "=================================="
echo "Fixing SSL Certificate for ${DOMAIN}"
echo "=================================="
echo ""

# Commands to execute on server
ssh_commands="
    echo 'Immediately renewing SSL certificate for ${DOMAIN}...'
    echo ''

    # Stop nginx
    echo 'Stopping nginx...'
    sudo systemctl stop nginx

    # Force renewal of the certificate
    echo 'Force renewing certificate...'
    sudo certbot certonly \\
        --standalone \\
        --non-interactive \\
        --agree-tos \\
        --email admin@${DOMAIN} \\
        --domains ${DOMAIN},www.${DOMAIN} \\
        --cert-name ${DOMAIN} \\
        --force-renewal \\
        --no-self-upgrade

    echo ''
    echo 'Certificate renewal completed!'

    # Start nginx
    echo 'Starting nginx...'
    sudo systemctl start nginx

    # Wait a moment
    sleep 3

    # Check nginx status
    echo ''
    echo 'Checking nginx status:'
    if systemctl is-active --quiet nginx; then
        echo '✓ nginx is running'
    else
        echo '✗ nginx failed to start'
    fi

    # Check certificate
    echo ''
    echo 'Checking certificate details:'
    if [ -f '/etc/letsencrypt/live/dadpars.ir/fullchain.pem' ]; then
        echo '✓ Certificate file exists'
        EXPIRY=\$(openssl x509 -enddate -noout -in '/etc/letsencrypt/live/dadpars.ir/fullchain.pem' | cut -d= -f2)
        echo "Certificate expires on: \${EXPIRY}"
    else
        echo '✗ Certificate file not found'
    fi

    echo ''
    echo '✅ SSL certificate fix completed!'
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "Certificate renewal process has been initiated."
echo "Please check https://${DOMAIN} to verify the certificate is working."
