#!/bin/bash

# Dadpars Legal Site Remote Deployment Script
# This script transfers the code to the server and builds Docker image there

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
PROJECT_NAME="dadparsir-web"
OLD_CONTAINER_NAME="dadparsir-web-1"
NEW_CONTAINER_NAME="dadparsir-web"
PORT="4437"
POSTGRES_DB="dadpars_db"
POSTGRES_USER="dadpars_user"
POSTGRES_PASSWORD="dadpars_password_1403"
POSTGRES_CONTAINER="dadparsir-db"

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
        print_error "sshpass is not installed. Installing..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y sshpass
        elif command -v yum &> /dev/null; then
            sudo yum install -y sshpass
        elif command -v brew &> /dev/null; then
            brew install sshpass
        else
            print_error "Please install sshpass manually"
            exit 1
        fi
    fi
    print_success "Dependencies checked"
}

# Create deployment package
create_package() {
    print_status "Creating deployment package..."

    # Create a temporary directory for deployment
    rm -rf dadpars_deploy
    mkdir -p dadpars_deploy

    # Copy necessary files
    cp -r dadpars_site dadpars_deploy/
    cp manage.py dadpars_deploy/
    cp requirements.txt dadpars_deploy/
    cp Dockerfile dadpars_deploy/
    cp static/ -r dadpars_deploy/ 2>/dev/null || true
    cp media/ -r dadpars_deploy/ 2>/dev/null || true

    # Create production Dockerfile
    cat > dadpars_deploy/Dockerfile.prod << EOF
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    postgresql-client \\
    build-essential \\
    libpq-dev \\
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Create static and media directories
RUN mkdir -p /app/staticfiles /app/media

# Collect static files
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "dadpars_site.wsgi:application"]
EOF

    # Create production docker-compose file
    cat > dadpars_deploy/docker-compose.prod.yml << EOF
version: '3.8'

services:
  db:
    image: postgres:15
    container_name: ${POSTGRES_CONTAINER}
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    restart: unless-stopped
    networks:
      - dadpars_network

  web:
    build:
      context: .
      dockerfile: Dockerfile.prod
    container_name: ${NEW_CONTAINER_NAME}
    command: >
      sh -c "python manage.py makemigrations &&
             python manage.py migrate &&
             python manage.py collectstatic --noinput --clear &&
             gunicorn --bind 0.0.0.0:8000 dadpars_site.wsgi:application"
    volumes:
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "${PORT}:8000"
    depends_on:
      - db
    environment:
      - DEBUG=0
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - ALLOWED_HOSTS=localhost,127.0.0.1,${SERVER_IP}
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
EOF

    # Create deployment script on server
    cat > dadpars_deploy/deploy-on-server.sh << EOF
#!/bin/bash
set -e

echo "Deploying Dadpars Site..."

# Stop and remove old containers
echo "Stopping old containers..."
docker stop ${OLD_CONTAINER_NAME} 2>/dev/null || true
docker rm ${OLD_CONTAINER_NAME} 2>/dev/null || true
docker stop ${NEW_CONTAINER_NAME} 2>/dev/null || true
docker rm ${NEW_CONTAINER_NAME} 2>/dev/null || true
docker stop ${POSTGRES_CONTAINER} 2>/dev/null || true
docker rm ${POSTGRES_CONTAINER} 2>/dev/null || true

# Build and start new containers
echo "Building and starting new containers..."
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Clean up
echo "Cleaning up..."
docker image prune -f

# Show status
echo "Deployment status:"
docker ps -a --filter 'name=dadparsir'
docker-compose -f docker-compose.prod.yml ps
EOF

    chmod +x dadpars_deploy/deploy-on-server.sh

    # Create tar package
    tar -czf dadpars_deploy.tar.gz dadpars_deploy/

    print_success "Deployment package created"
}

# Transfer package to server
transfer_package() {
    print_status "Transferring deployment package to server..."

    # Transfer the package
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no dadpars_deploy.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/

    print_success "Package transferred successfully"
}

# Deploy on server
deploy_on_server() {
    print_status "Deploying on server..."

    # SSH commands to execute on server
    ssh_commands="
        # Extract deployment package
        cd /tmp
        rm -rf dadpars_deploy 2>/dev/null
        tar -xzf dadpars_deploy.tar.gz

        # Navigate to deployment directory
        cd dadpars_deploy

        # Run deployment script
        ./deploy-on-server.sh

        # Wait a moment for containers to start
        sleep 10

        # Check if containers are running
        if docker ps | grep -q ${NEW_CONTAINER_NAME}; then
            echo 'Deployment successful!'
        else
            echo 'Deployment might have issues. Checking logs:'
            docker logs ${NEW_CONTAINER_NAME} 2>&1 | tail -20
        fi

        # Cleanup
        cd /tmp
        rm -rf dadpars_deploy dadpars_deploy.tar.gz
    "

    # Execute commands on server
    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Deployment completed on server"
}

# Cleanup local files
cleanup() {
    print_status "Cleaning up local files..."
    rm -rf dadpars_deploy dadpars_deploy.tar.gz
    print_success "Cleanup completed"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."

    # Check if the site is responding
    sleep 5
    if curl -s --max-time 10 http://${SERVER_IP}:${PORT} > /dev/null; then
        print_success "Site is responding correctly on http://${SERVER_IP}:${PORT}"
    else
        print_warning "Site might not be responding. Please check manually at http://${SERVER_IP}:${PORT}"
        print_status "You can also check container logs on the server:"
        echo "  sshpass -p '$SERVER_PASSWORD' ssh ${SERVER_USER}@${SERVER_IP} 'docker logs ${NEW_CONTAINER_NAME}'"
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "Dadpars Legal Site Remote Deployment"
    echo "=================================="
    echo ""

    check_dependencies
    create_package
    transfer_package
    deploy_on_server
    cleanup
    verify_deployment

    echo ""
    print_success "Deployment completed!"
    print_status "Your site should be running at: http://${SERVER_IP}:${PORT}"
    echo ""
    print_status "To check logs on server:"
    echo "  sshpass -p '$SERVER_PASSWORD' ssh ${SERVER_USER}@${SERVER_IP} 'docker logs ${NEW_CONTAINER_NAME}'"
    echo ""
}

# Run main function
main "$@"
