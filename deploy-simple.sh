#!/bin/bash

# Dadpars Legal Site Simple Deployment Script
# This script syncs files to the server and deploys using Docker on the server

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
OLD_CONTAINER_ID="b02d10e228cf"
OLD_CONTAINER_NAME="dadparsir-web-1"
NEW_CONTAINER_NAME="dadparsir-web"
PORT="4437"
POSTGRES_DB="dadpars_db"
POSTGRES_USER="dadpars_user"
POSTGRES_PASSWORD="dadpars_password_1403"
POSTGRES_CONTAINER="dadparsir-db"
REMOTE_DIR="/tmp/dadpars_deploy"

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

# Check dependencies
check_dependencies() {
    print_status "Checking dependencies..."

    # Check for sshpass
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

# Prepare server and stop old containers
prepare_server() {
    print_status "Preparing server and stopping old containers..."

    # SSH commands to prepare server
    ssh_commands="
        # Create deployment directory
        mkdir -p $REMOTE_DIR
        cd $REMOTE_DIR

        # Stop and remove old containers
        echo 'Stopping old containers...'
        docker stop $OLD_CONTAINER_ID 2>/dev/null || true
        docker rm $OLD_CONTAINER_ID 2>/dev/null || true
        docker stop $OLD_CONTAINER_NAME 2>/dev/null || true
        docker rm $OLD_CONTAINER_NAME 2>/dev/null || true
        docker stop $NEW_CONTAINER_NAME 2>/dev/null || true
        docker rm $NEW_CONTAINER_NAME 2>/dev/null || true
        docker stop $POSTGRES_CONTAINER 2>/dev/null || true
        docker rm $POSTGRES_CONTAINER 2>/dev/null || true

        # Remove old volumes if they exist
        docker volume rm dadpars_deploy_postgres_data 2>/dev/null || true

        echo 'Old containers stopped and removed'
    "

    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Server prepared"
}

# Sync files to server
sync_files() {
    print_status "Syncing files to server..."

    # Create Dockerfile on the fly
    cat > Dockerfile.deploy << EOF
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

    # Transfer files using sshpass
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no \
        -r dadpars_site \
        manage.py \
        requirements.txt \
        Dockerfile.deploy \
        static/ \
        ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/

    # Rename Dockerfile on server
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
        "mv ${REMOTE_DIR}/Dockerfile.deploy ${REMOTE_DIR}/Dockerfile"

    print_success "Files synced to server"
}

# Deploy on server
deploy_on_server() {
    print_status "Deploying application on server..."

    # Create and run deployment script on server
    ssh_commands="
        cd $REMOTE_DIR

        # Create docker-compose.yml
        cat > docker-compose.yml << 'EOFF'
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
    build: .
    container_name: ${NEW_CONTAINER_NAME}
    command: sh -c 'python manage.py makemigrations && python manage.py migrate && python manage.py collectstatic --noinput --clear && gunicorn --bind 0.0.0.0:8000 dadpars_site.wsgi:application'
    volumes:
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - '${PORT}:8000'
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
EOFF

        # Build and start containers
        echo 'Building Docker image...'
        docker-compose build

        echo 'Starting containers...'
        docker-compose up -d

        # Wait for containers to start
        sleep 15

        # Check status
        echo 'Checking container status...'
        docker ps | grep dadparsir

        # Show logs if there's an issue
        if ! docker ps | grep -q ${NEW_CONTAINER_NAME}; then
            echo 'Container is not running. Showing logs:'
            docker logs ${NEW_CONTAINER_NAME}
        fi

        # Clean up old images
        docker image prune -f
    "

    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Deployment completed on server"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."

    # Check if the site is responding
    if curl -s --max-time 10 http://${SERVER_IP}:${PORT} > /dev/null; then
        print_success "Site is responding correctly on http://${SERVER_IP}:${PORT}"
    else
        print_warning "Site might not be responding. Please check manually at http://${SERVER_IP}:${PORT}"
    fi

    # Show container status
    print_status "Container status on server:"
    ssh_status_cmd="docker ps -a --filter 'name=dadparsir'"
    echo "$ssh_status_cmd" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash
}

# Cleanup
cleanup() {
    print_status "Cleaning up local files..."
    rm -f Dockerfile.deploy
    print_success "Cleanup completed"
}

# Main execution
main() {
    echo "=================================="
    echo "Dadpars Legal Site Simple Deployment"
    echo "=================================="
    echo ""

    check_dependencies
    prepare_server
    sync_files
    deploy_on_server
    verify_deployment
    cleanup

    echo ""
    print_success "Deployment completed!"
    print_status "Your site should be running at: http://${SERVER_IP}:${PORT}"
    echo ""
    print_status "To check logs on server:"
    echo "  sshpass -p '$SERVER_PASSWORD' ssh ${SERVER_USER}@${SERVER_IP} 'docker logs ${NEW_CONTAINER_NAME}'"
    echo ""
    print_status "To access container shell on server:"
    echo "  sshpass -p '$SERVER_PASSWORD' ssh ${SERVER_USER}@${SERVER_IP} 'docker exec -it ${NEW_CONTAINER_NAME} bash'"
    echo ""
}

# Run main function
main "$@"
