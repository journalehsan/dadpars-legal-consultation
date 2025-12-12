#!/bin/bash

# Script to set up automatic SSL certificate renewal via cron

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

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Main execution
main() {
    echo "=================================="
    echo "Setting Up Auto SSL Certificate Renewal"
    echo "=================================="
    echo ""

    print_status "Connecting to server to set up automatic renewal..."

    # Commands to execute on server
    ssh_commands="
        echo \"Setting up automatic SSL certificate renewal...\"
        echo \"\"

        # Create a script for auto renewal
        echo \"Creating renewal script...\"
        sudo tee /usr/local/bin/renew-ssl-dadpars.sh > /dev/null << 'EOF'
#!/bin/bash

# Auto renewal script for dadpars.ir SSL certificate
DOMAIN=\"dadpars.ir\"
LOG_FILE=\"/var/log/ssl-renewal-dadpars.log\"

# Function to log messages
log_message() {
    echo \"\$(date '+%Y-%m-%d %H:%M:%S') - \$1\" >> \"\$LOG_FILE\"
}

log_message \"Starting SSL certificate renewal check for \$DOMAIN\"

# Check if certificate needs renewal (less than 30 days remaining)
if ! certbot renew --cert-name \"\$DOMAIN\" --quiet --non-interactive; then
    log_message \"Certificate renewal failed or needed, attempting manual renewal...\"

    # Stop nginx to free port 80
    systemctl stop nginx
    log_message \"Stopped nginx\"

    # Attempt manual renewal
    if certbot certonly \\
        --standalone \\
        --non-interactive \\
        --agree-tos \\
        --email \"admin@dadpars.ir\" \\
        --domains \"\$DOMAIN,www.\$DOMAIN\" \\
        --cert-name \"\$DOMAIN\" \\
        --force-renewal; then

        log_message \"Certificate renewal successful\"
        RENEWAL_SUCCESS=true
    else
        log_message \"ERROR: Certificate renewal failed\"
        RENEWAL_SUCCESS=false
    fi

    # Start nginx
    systemctl start nginx
    log_message \"Started nginx\"

    # Reload nginx to ensure new certificate is loaded
    if [ \"\$RENEWAL_SUCCESS\" = true ]; then
        systemctl reload nginx
        log_message \"Reloaded nginx with new certificate\"
    fi

    # Check certificate expiry
    if [ -f \"/etc/letsencrypt/live/\$DOMAIN/fullchain.pem\" ]; then
        EXPIRY=\$(openssl x509 -enddate -noout -in \"/etc/letsencrypt/live/\$DOMAIN/fullchain.pem\" | cut -d= -f2)
        log_message \"Certificate expires on: \$EXPIRY\"
    fi
else
    log_message \"Certificate is still valid, no renewal needed\"
fi

log_message \"SSL certificate renewal check completed\"
EOF

        # Make the script executable
        sudo chmod +x /usr/local/bin/renew-ssl-dadpars.sh
        echo \"✓ Created renewal script at /usr/local/bin/renew-ssl-dadpars.sh\"
        echo \"\"

        # Create log file
        sudo touch /var/log/ssl-renewal-dadpars.log
        sudo chmod 644 /var/log/ssl-renewal-dadpars.log
        echo \"✓ Created log file at /var/log/ssl-renewal-dadpars.log\"
        echo \"\"

        # Set up cron job to run twice daily at 3:00 AM and 3:00 PM
        echo \"Setting up cron job for automatic renewal...\"

        # Create a temporary cron file
        (crontab -l 2>/dev/null | grep -v \"renew-ssl-dadpars\"; echo \"0 3,15 * * * /usr/local/bin/renew-ssl-dadpars.sh\") | crontab -

        echo \"✓ Added cron job to check certificates twice daily (3:00 AM and 3:00 PM)\"
        echo \"\"

        # Verify cron job was added
        echo \"Current cron jobs:\"
        crontab -l | grep -E \"(renew-ssl|3,15)\" || echo \"No matching cron jobs found\"
        echo \"\"

        # Show current certificates
        echo \"Current certificates:\"
        sudo certbot certificates
        echo \"\"

        echo \"✅ Automatic SSL renewal setup completed!\"
        echo \"\"
        echo \"The certificate will be automatically checked and renewed if needed.\"
        echo \"Renewal log: /var/log/ssl-renewal-dadpars.log\"
    "

    # Execute commands on server
    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    echo ""
    print_success "Auto-renewal setup completed!"
    echo ""
    print_status "Cron job has been configured to:"
    echo "  - Check certificates twice daily (3:00 AM and 3:00 PM)"
    echo "  - Automatically renew if within 30 days of expiry"
    echo "  - Stop/start nginx as needed"
    echo "  - Log all activities to /var/log/ssl-renewal-dadpars.log"
    echo ""
    print_warning "Note: The first script 'update-ssl-cert.sh' is for manual renewal"
    print_warning "The auto-renewal will run automatically and doesn't need manual intervention"
}

# Run main function
main "$@"
