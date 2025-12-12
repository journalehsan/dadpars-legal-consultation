#!/bin/bash

# Script to update SSL certificate for dadpars.ir using certbot
# This script handles stopping nginx, updating certificate, and restarting nginx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
DOMAIN="dadpars.ir"
NGINX_CONFIG="/etc/nginx/conf.d/dadpars.conf"
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
FULLCHAIN="${CERT_PATH}/fullchain.pem"
PRIVKEY="${CERT_PATH}/privkey.pem"

# Functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sshpass is installed
check_dependencies() {
    print_status "Checking dependencies..."
    if ! command -v sshpass &> /dev/null; then
        print_error "sshpass is not installed. Please install it first."
        exit 1
    fi
    print_success "Dependencies checked"
}

# Main execution
main() {
    echo "=================================="
    echo "SSL Certificate Update for ${DOMAIN}"
    echo "=================================="
    echo ""

    check_dependencies

    print_status "Connecting to server to update SSL certificate..."

    # Commands to execute on server
    ssh_commands="
        echo \"Starting SSL certificate update for ${DOMAIN}...\"
        echo \"Current date: \$(date)\"
        echo \"\"

        # Check current certificate
        if [ -f \"${FULLCHAIN}\" ]; then
            echo \"Current certificate details:\"
            openssl x509 -in \"${FULLCHAIN}\" -text -noout | grep -A 2 \"Validity\" || echo \"Could not read certificate details\"
            echo \"\"
        else
            echo \"No existing certificate found at ${FULLCHAIN}\"
            echo \"\"
        fi

        # Check if nginx is running
        echo \"Checking nginx status...\"
        if systemctl is-active --quiet nginx; then
            echo \"✓ nginx is running\"
            NGINX_RUNNING=true
        else
            echo \"✗ nginx is not running\"
            NGINX_RUNNING=false
        fi
        echo \"\"

        # Stop nginx to free port 80
        echo \"Stopping nginx to free port 80 for certbot...\"
        if [ \"\$NGINX_RUNNING\" = true ]; then
            sudo systemctl stop nginx
            echo \"✓ nginx stopped\"
        fi
        echo \"\"

        # Check if port 80 is free
        echo \"Checking if port 80 is free...\"
        if netstat -tuln | grep -q \":80 \" ; then
            echo \"⚠️  Port 80 is still in use:\"
            netstat -tuln | grep \":80 \"
            echo \"\"
            echo \"Trying to kill any process using port 80...\"
            sudo fuser -k 80/tcp 2>/dev/null || echo \"No process found on port 80\"
            sleep 2
        else
            echo \"✓ Port 80 is free\"
        fi
        echo \"\"

        # Backup existing certificates if they exist
        if [ -f \"${FULLCHAIN}\" ]; then
            echo \"Backing up existing certificates...\"
            BACKUP_DIR=\"/etc/letsencrypt/backup/\$(date +%Y%m%d_%H%M%S)\"
            sudo mkdir -p \"\${BACKUP_DIR}\"
            sudo cp \"${FULLCHAIN}\" \"\${BACKUP_DIR}/\"
            sudo cp \"${PRIVKEY}\" \"\${BACKUP_DIR}/\"
            echo \"✓ Certificates backed up to \${BACKUP_DIR}\"
            echo \"\"
        fi

        # Run certbot to renew/reissue certificate
        echo \"Running certbot to update certificate...\"

        # Try to renew first
        echo \"Attempting certificate renewal...\"
        if sudo certbot renew --cert-name ${DOMAIN} --quiet --no-self-upgrade; then
            echo \"✓ Certificate renewed successfully\"
        else
            echo \"Renewal failed, attempting to obtain new certificate...\"

            # Obtain new certificate
            sudo certbot certonly \
                --standalone \
                --non-interactive \
                --agree-tos \
                --email admin@${DOMAIN} \
                --domains ${DOMAIN},www.${DOMAIN} \
                --cert-name ${DOMAIN} \
                --force-renewal || {
                echo \"❌ Failed to obtain certificate\"
                # Restart nginx even if certbot fails
                if [ \"\$NGINX_RUNNING\" = true ]; then
                    echo \"Restarting nginx...\"
                    sudo systemctl start nginx
                fi
                exit 1
            }
            echo \"✓ New certificate obtained successfully\"
        fi
        echo \"\"

        # Verify new certificate
        echo \"Verifying new certificate...\"
        if [ -f \"${FULLCHAIN}\" ]; then
            echo \"New certificate details:\"
            openssl x509 -in \"${FULLCHAIN}\" -text -noout | grep -A 2 \"Validity\"
            echo \"\"

            # Check certificate expiry
            EXPIRY=\$(openssl x509 -enddate -noout -in \"${FULLCHAIN}\" | cut -d= -f2)
            echo \"Certificate expires on: \${EXPIRY}\"
            echo \"\"

            # Check if certificate files exist and have correct permissions
            echo \"Certificate file verification:\"
            ls -la \"${CERT_PATH}/\" || echo \"Could not list certificate directory\"
            echo \"\"
        else
            echo \"❌ Certificate files not found after renewal!\"
        fi

        # Test nginx configuration before starting
        echo \"Testing nginx configuration...\"
        if sudo nginx -t; then
            echo \"✓ nginx configuration is valid\"
        else
            echo \"⚠️  nginx configuration test failed, but will restart anyway\"
        fi
        echo \"\"

        # Start nginx
        echo \"Starting nginx...\"
        sudo systemctl start nginx
        sleep 3

        # Verify nginx is running
        if systemctl is-active --quiet nginx; then
            echo \"✓ nginx is running\"
        else
            echo \"❌ nginx failed to start\"
            echo \"Checking nginx logs:\"
            sudo journalctl -u nginx --no-pager -n 20
            exit 1
        fi
        echo \"\"

        # Test SSL certificate
        echo \"Testing SSL certificate...\"
        echo \"Checking certificate for ${DOMAIN}...\"

        # Use openssl to check certificate
        if echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
            echo \"✓ SSL certificate is working for ${DOMAIN}\"
        else
            echo \"⚠️  Could not verify SSL certificate for ${DOMAIN}\"
        fi

        echo \"\"
        echo \"✅ SSL certificate update completed!\"
        echo \"\"
        echo \"Certificate location:\"
        echo \"  Fullchain: ${FULLCHAIN}\"
        echo \"  Private key: ${PRIVKEY}\"
        echo \"\"
        echo \"Nginx status: \$(systemctl is-active nginx)\"
        echo \"\"
        echo \"You can verify the certificate at:\"
        echo \"  https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN}&hideResults=on\"
    "

    # Execute commands on server
    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    echo ""
    print_success "SSL certificate update completed!"
    echo ""
    echo "The certificate for ${DOMAIN} has been updated successfully."
    echo "Nginx has been restarted and the site should be accessible at:"
    echo "  https://${DOMAIN}"
    echo ""
    print_status "To check certificate details on server:"
    echo "  sshpass -p '$SERVER_PASSWORD' ssh ${SERVER_USER}@${SERVER_IP} 'sudo certbot certificates'"
}

# Run main function
main "$@"
