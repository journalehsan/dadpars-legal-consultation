#!/bin/bash

# Dadpars Legal Site Management Script
# Usage: ./manage.sh [setup|start|stop|restart|status]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="Dadpars Legal Site"
VENV_DIR="venv"
MANAGE_SCRIPT="manage.py"
SERVER_HOST="0.0.0.0"
SERVER_PORT="8000"
PID_FILE=".server.pid"

# Function to print colored output
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

# Function to check if virtual environment exists
check_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Virtual environment not found. Please run './manage.sh setup' first."
        exit 1
    fi
}

# Function to activate virtual environment
activate_venv() {
    source "$VENV_DIR/bin/activate"
}

# Function to check if server is running
is_server_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to setup the project
setup_project() {
    print_status "Setting up $PROJECT_NAME..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv "$VENV_DIR"
        print_success "Virtual environment created."
    else
        print_warning "Virtual environment already exists."
    fi
    
    # Activate virtual environment
    activate_venv
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install Django
    print_status "Installing Django..."
    pip install Django
    
    # Install additional dependencies
    print_status "Installing additional dependencies..."
    pip install jdatetime  # For Persian date support
    
    # Run migrations
    print_status "Running database migrations..."
    python "$MANAGE_SCRIPT" makemigrations
    python "$MANAGE_SCRIPT" migrate
    
    # Create superuser if it doesn't exist
    print_status "Creating superuser..."
    echo "from django.contrib.auth.models import User; User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin123')" | python "$MANAGE_SCRIPT" shell
    
    # Collect static files
    print_status "Collecting static files..."
    python "$MANAGE_SCRIPT" collectstatic --noinput --clear
    
    # Create static directories if they don't exist
    mkdir -p static/css static/js static/img media
    
    print_success "Project setup completed!"
    print_status "You can now start the server with: ./manage.sh start"
    print_status "Admin login: username=admin, password=admin123"
}

# Function to start the server
start_server() {
    check_venv
    
    if is_server_running; then
        print_warning "Server is already running (PID: $(cat $PID_FILE))"
        return 0
    fi
    
    print_status "Starting $PROJECT_NAME server..."
    activate_venv
    
    # Start server in background
    nohup python "$MANAGE_SCRIPT" runserver "$SERVER_HOST:$SERVER_PORT" > server.log 2>&1 &
    local pid=$!
    
    # Save PID
    echo $pid > "$PID_FILE"
    
    # Wait a moment to check if server started successfully
    sleep 2
    
    if is_server_running; then
        print_success "Server started successfully!"
        print_status "Server URL: http://localhost:$SERVER_PORT"
        print_status "Admin URL: http://localhost:$SERVER_PORT/admin/"
        print_status "Process ID: $pid"
        print_status "Log file: server.log"
    else
        print_error "Failed to start server. Check server.log for details."
        rm -f "$PID_FILE"
        exit 1
    fi
}

# Function to stop the server
stop_server() {
    if ! is_server_running; then
        print_warning "Server is not running."
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    print_status "Stopping server (PID: $pid)..."
    
    # Kill the process
    kill $pid
    
    # Wait for process to stop
    local count=0
    while ps -p $pid > /dev/null 2>&1 && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    # Force kill if still running
    if ps -p $pid > /dev/null 2>&1; then
        print_warning "Force killing server process..."
        kill -9 $pid
    fi
    
    rm -f "$PID_FILE"
    print_success "Server stopped."
}

# Function to restart the server
restart_server() {
    print_status "Restarting server..."
    stop_server
    sleep 2
    start_server
}

# Function to show server status
show_status() {
    print_status "Checking $PROJECT_NAME status..."
    
    if is_server_running; then
        local pid=$(cat "$PID_FILE")
        print_success "Server is running (PID: $pid)"
        print_status "Server URL: http://localhost:$SERVER_PORT"
        print_status "Admin URL: http://localhost:$SERVER_PORT/admin/"
        
        # Show resource usage
        if command -v ps &> /dev/null; then
            print_status "Resource usage:"
            ps -p $pid -o pid,ppid,cmd,%mem,%cpu --no-headers || true
        fi
    else
        print_warning "Server is not running."
    fi
    
    # Check virtual environment
    if [ -d "$VENV_DIR" ]; then
        print_success "Virtual environment exists."
    else
        print_warning "Virtual environment not found."
    fi
    
    # Check database
    if [ -f "db.sqlite3" ]; then
        print_success "Database file exists."
    else
        print_warning "Database file not found."
    fi
}

# Function to show help
show_help() {
    echo "Dadpars Legal Site Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup    - Setup the project (install dependencies, create database, etc.)"
    echo "  start    - Start the development server"
    echo "  stop     - Stop the development server"
    echo "  restart  - Restart the development server"
    echo "  status   - Show server status"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup     # Initial setup"
    echo "  $0 start     # Start server"
    echo "  $0 status    # Check status"
    echo ""
}

# Main script logic
case "${1:-help}" in
    setup)
        setup_project
        ;;
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac