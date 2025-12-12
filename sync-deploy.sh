#!/bin/bash

# Dadpars Legal Site Deployment Script
# This script deploys the Django site to the server using Docker

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
DOCKER_IMAGE="dadparsir-site:latest"
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

# Build Docker image locally
build_image() {
    print_status "Building Docker image..."

    # Check if we can connect to Docker Hub
    if ! docker pull alpine:latest > /dev/null 2>&1; then
        print_warning "Cannot connect to Docker Hub. Using alternative method..."

        # Create a simple Dockerfile that doesn't require external images
        cat > Dockerfile.local << EOF
# Use existing Python image if available
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y postgresql-client build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Create static and media directories
RUN mkdir -p /app/staticfiles /app/media

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "dadpars_site.wsgi:application"]
EOF

        # Try to build with local Dockerfile
        if docker build -f Dockerfile.local -t $DOCKER_IMAGE .; then
            print_success "Docker image built successfully with local Dockerfile"
        else
            print_error "Failed to build Docker image locally"
            print_status "Trying alternative approach..."

            # Check if we have any Python images locally
            if docker images | grep -q python; then
                PYTHON_IMAGE=$(docker images | grep python | head -n1 | awk '{print $1":"$2}')
                print_status "Using existing Python image: $PYTHON_IMAGE"

                # Update Dockerfile to use existing image
                sed -i "1s/.*/FROM $PYTHON_IMAGE/" Dockerfile

                # Build again
                if docker build -t $DOCKER_IMAGE .; then
                    print_success "Docker image built successfully with existing image"
                else
                    print_error "Failed to build Docker image. Please check your Docker configuration."
                    exit 1
                fi
            else
                print_error "No Python images found locally. Please check your internet connection or Docker configuration."
                exit 1
            fi
        fi
    else
        # Normal build process
        docker build -t $DOCKER_IMAGE .
        print_success "Docker image built successfully"
    fi
}

# Save Docker image to tar file
save_image() {
    print_status "Saving Docker image..."
    docker save $DOCKER_IMAGE -o dadparsir-site.tar
    print_success "Docker image saved"
}

# Transfer files to server
transfer_files() {
    print_status "Transferring files to server..."

    # Transfer Docker image
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no dadparsir-site.tar ${SERVER_USER}@${SERVER_IP}:/tmp/

    # Transfer docker-compose file for production
    cat > docker-compose.prod.yml << EOF
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
    image: ${DOCKER_IMAGE}
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

    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no docker-compose.prod.yml ${SERVER_USER}@${SERVER_IP}:/tmp/

    print_success "Files transferred successfully"
}

# Deploy on server
deploy_to_server() {
    print_status "Deploying to server..."

    # SSH commands to execute on server
    ssh_commands="
        # Stop and remove old container
        echo 'Stopping old container...'
        docker stop ${OLD_CONTAINER_NAME} 2>/dev/null || true
        docker rm ${OLD_CONTAINER_NAME} 2>/dev/null || true
        docker stop ${NEW_CONTAINER_NAME} 2>/dev/null || true
        docker rm ${NEW_CONTAINER_NAME} 2>/dev/null || true

        # Load new Docker image
        echo 'Loading new Docker image...'
        docker load -i /tmp/dadparsir-site.tar

        # Stop and remove old database container if exists
        docker stop ${POSTGRES_CONTAINER} 2>/dev/null || true
        docker rm ${POSTGRES_CONTAINER} 2>/dev/null || true

        # Deploy with docker-compose
        echo 'Starting new containers...'
        cd /tmp
        docker-compose -f docker-compose.prod.yml up -d

        # Clean up old images and containers
        echo 'Cleaning up...'
        docker image prune -f

        # Show status
        echo 'Deployment status:'
        docker ps -a --filter 'name=dadparsir'
    "

    # Execute commands on server
    echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

    print_success "Deployment completed successfully"
}

# Cleanup local files
cleanup() {
    print_status "Cleaning up local files..."
    rm -f dadparsir-site.tar
    rm -f docker-compose.prod.yml
    print_success "Cleanup completed"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    sleep 10  # Wait for services to start

    # Check if the site is responding
    if curl -s -o /dev/null -w "%{http_code}" http://${SERVER_IP}:${PORT} | grep -q "200"; then
        print_success "Site is responding correctly on http://${SERVER_IP}:${PORT}"
    else
        print_warning "Site might not be responding. Please check manually at http://${SERVER_IP}:${PORT}"
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "Dadpars Legal Site Deployment"
    echo "=================================="
    echo ""

    check_dependencies
    build_image
    save_image
    transfer_files
    deploy_to_server
    cleanup
    verify_deployment

    echo ""
    print_success "Deployment completed successfully!"
    print_status "Your site is now running at: http://${SERVER_IP}:${PORT}"
    echo ""
}

# Run main function
main "$@"
