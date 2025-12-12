#!/bin/bash

# Simple SSL certificate renewal script for dadpars.ir
# Can be run via cron for automatic renewal

set -e

# Configuration
DOMAIN="dadpars.ir"
EMAIL="admin@dadpars.ir"

echo "$(date): Starting SSL certificate renewal check for $DOMAIN"

# Check if certificate needs renewal
if ! certbot renew --cert-name "$DOMAIN" --quiet --non-interactive; then
    echo "$(date): Certificate renewal failed, attempting manual renewal..."

    # Stop nginx to free port 80
    systemctl stop nginx

    # Attempt manual renewal
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --domains "$DOMAIN,www.$DOMAIN" \
        --cert-name "$DOMAIN" \
        --force-renewal

    # Start nginx
    systemctl start nginx

    echo "$(date): Certificate renewal completed"
else
    echo "$(date): Certificate is still valid, no renewal needed"
fi

# Reload nginx to ensure new certificate is loaded
systemctl reload nginx

echo "$(date): SSL certificate renewal check completed"
