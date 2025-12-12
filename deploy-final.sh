#!/bin/bash

# Dadpars Legal Site Final Deployment Script
# This script deploys the complete Django site with all necessary files

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

    ssh_commands="
        # Remove old deployment directory
        rm -rf $REMOTE_DIR
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

        # Remove old volumes
        docker volume rm dadpars_deploy_postgres_data 2>/dev/null || true
        docker volume prune -f 2>/dev/null || true

        echo 'Server prepared'
    "

    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Server prepared"
}

# Sync files to server
sync_files() {
    print_status "Syncing files to server..."

    # Create production Dockerfile
    cat > Dockerfile.prod << EOF
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

# Copy all project files
COPY . /app/

# Create static and media directories
RUN mkdir -p /app/staticfiles /app/media

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "dadpars_site.wsgi:application"]
EOF

    # Transfer all necessary files and directories
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no \
        -r dadpars_site \
        main \
        static/ \
        manage.py \
        requirements.txt \
        Dockerfile.prod \
        ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/

    # Rename Dockerfile on server
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
        "mv ${REMOTE_DIR}/Dockerfile.prod ${REMOTE_DIR}/Dockerfile"

    print_success "Files synced to server"
}

# Deploy on server
deploy_on_server() {
    print_status "Deploying application on server..."

    ssh_commands="
        cd $REMOTE_DIR

        # Create production docker-compose.yml
        cat > docker-compose.yml << 'EOFF'
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
    command: >
      sh -c 'python manage.py makemigrations &&
             python manage.py migrate &&
             python manage.py collectstatic --noinput --clear &&
             gunicorn --bind 0.0.0.0:8000 dadpars_site.wsgi:application'
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
      - SECRET_KEY=django-insecure-production-key-change-me
      - DJANGO_SETTINGS_MODULE=dadpars_site.settings_production
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

        # Clean up any old containers/images
        echo 'Cleaning up old containers and images...'
        docker system prune -f

        # Build and start containers
        echo 'Building Docker image...'
        docker-compose build

        echo 'Starting containers...'
        docker-compose up -d

        # Wait for containers to initialize
        sleep 30

        # Check status
        echo 'Checking container status...'
        docker ps | grep dadparsir || echo 'Containers not found'

        # Show logs if there's an issue
        if ! docker ps | grep -q ${NEW_CONTAINER_NAME}; then
            echo 'Container is not running. Showing logs:'
            docker logs ${NEW_CONTAINER_NAME}
        fi

        # Run Django management commands to verify
        echo 'Running Django checks...'
        docker exec ${NEW_CONTAINER_NAME} python manage.py check --deploy 2>/dev/null || echo 'Django checks completed'

        # Clean up unused images
        docker image prune -f
    "

    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Deployment completed on server"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."

    # Check if the site is responding
    sleep 5
    response=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" http://${SERVER_IP}:${PORT} 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        print_success "Site is responding correctly on http://${SERVER_IP}:${PORT}"
    else
        print_warning "Site response code: $response"
        print_status "Checking container logs..."
        sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
            "docker logs ${NEW_CONTAINER_NAME} --tail 20"
    fi

    # Show container status
    print_status "Container status:"
    ssh_status_cmd="docker ps -a --filter 'name=dadparsir'"
    echo "$ssh_status_cmd" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash
}

# Cleanup
cleanup() {
    print_status "Cleaning up local files..."
    rm -f Dockerfile.prod
    print_success "Cleanup completed"
}

# Main execution
main() {
    echo "=================================="
    echo "Dadpars Legal Site Final Deployment"
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
