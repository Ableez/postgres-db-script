#!/usr/bin/env bash
# Use this script to start a docker container for a local development database

# TO RUN ON WINDOWS:
# 1. Install WSL (Windows Subsystem for Linux) - https://learn.microsoft.com/en-us/windows/wsl/install
# 2. Install Docker Desktop for Windows - https://docs.docker.com/docker-for-windows/install/
# 3. Open WSL - `wsl`
# 4. Run this script - `./start-database.sh`

# On Linux and macOS you can run this script directly - `./start-database.sh`

set -euo pipefail  # Exit on error, undefined var, and pipe failures

# Default values
DEFAULT_DB_CONTAINER_PREFIX="_postgres"
DEFAULT_DB_PORT="5432"
DEFAULT_DB_USER="postgres" 

# Function to get the server ip address
get_ip_address() {
    local ip
    ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    if [ -z "$ip" ]; then
        # Fallback method if first method fails
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "$ip"
}

#!/usr/bin/env bash
# Use this script to start a docker container for a local development database

set -euo pipefail

# Default values
DEFAULT_DB_CONTAINER_PREFIX="dev-postgres"
DEFAULT_DB_PORT="5432"
DEFAULT_DB_USER="postgres"

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo
    echo "Commands:"
    echo "  start          Start a new database container (default if no command given)"
    echo "  stop           Stop a running database container"
    echo "  restart        Restart a database container"
    echo "  remove         Remove a database container"
    echo "  list           List all database containers"
    echo "  status         Show status of all database containers"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -n, --name     Database name (default: test)"
    echo "  -p, --port     Port number (default: 5432)"
    echo "  -f, --force    Force the operation without confirmation"
    echo "  -a, --all      Apply operation to all containers (with stop/remove commands)"
    echo
    echo "Examples:"
    echo "  $0                          # Interactive mode to start a new database"
    echo "  $0 start -n mydb -p 5432    # Start a new database named 'mydb' on port 5432"
    echo "  $0 stop -n mydb             # Stop the database named 'mydb'"
    echo "  $0 stop --all               # Stop all database containers"
    echo "  $0 list                     # List all database containers"
    echo "  $0 status                   # Show detailed status of all containers"
}

# Function to get the server ip address
get_ip_address() {
    local ip
    ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
    if [ -z "$ip" ]; then
        # Fallback method if first method fails
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "$ip"
}

# Function to list all database containers
list_containers() {
    echo "Database Containers:"
    echo "-------------------"
    docker ps -a --filter "name=${DEFAULT_DB_CONTAINER_PREFIX}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show detailed status
show_status() {
    echo "Database Containers Status:"
    echo "-------------------------"
    docker ps -a --filter "name=${DEFAULT_DB_CONTAINER_PREFIX}" --format "ID\t{{.ID}}\nNAME\t{{.Names}}\nSTATUS\t{{.Status}}\nPORTS\t{{.Ports}}\n"
}

# Function to stop containers
stop_container() {
    local container_name=$1
    local force=$2
    
    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to stop $container_name? [y/N]: " -r REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            return
        fi
    fi
    
    if docker stop "$container_name"; then
        echo "Container $container_name stopped successfully"
    else
        echo "Failed to stop container $container_name"
        return 1
    fi
}

# Function to remove containers
remove_container() {
    local container_name=$1
    local force=$2
    
    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to remove $container_name? This will delete all data! [y/N]: " -r REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            return
        fi
    fi
    
    if docker rm -f "$container_name"; then
        echo "Container $container_name removed successfully"
        # Remove data directory
        local data_dir="$HOME/docker_postgres_data/${container_name}"
        if [ -d "$data_dir" ]; then
            rm -rf "$data_dir"
            echo "Data directory $data_dir removed"
        fi
    else
        echo "Failed to remove container $container_name"
        return 1
    fi
}

# Parse command line arguments
COMMAND="start"
DB_NAME=""
DB_PORT=""
FORCE="false"
ALL="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|remove|list|status)
            COMMAND="$1"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--name)
            DB_NAME="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE="true"
            shift
            ;;
        -a|--all)
            ALL="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    list)
        list_containers
        exit 0
        ;;
    status)
        show_status
        exit 0
        ;;
    stop)
        if [ "$ALL" = "true" ]; then
            echo "Stopping all database containers..."
            docker ps -q --filter "name=${DEFAULT_DB_CONTAINER_PREFIX}" | while read -r container; do
                stop_container "$(docker inspect -f '{{.Name}}' "$container" | cut -c 2-)" "$FORCE"
            done
        else
            if [ -z "$DB_NAME" ]; then
                read -p "Enter database name to stop: " DB_NAME
            fi
            stop_container "${DEFAULT_DB_CONTAINER_PREFIX}-${DB_NAME}" "$FORCE"
        fi
        exit 0
        ;;
    remove)
        if [ "$ALL" = "true" ]; then
            echo "Removing all database containers..."
            docker ps -a -q --filter "name=${DEFAULT_DB_CONTAINER_PREFIX}" | while read -r container; do
                remove_container "$(docker inspect -f '{{.Name}}' "$container" | cut -c 2-)" "$FORCE"
            done
        else
            if [ -z "$DB_NAME" ]; then
                read -p "Enter database name to remove: " DB_NAME
            fi
            remove_container "${DEFAULT_DB_CONTAINER_PREFIX}-${DB_NAME}" "$FORCE"
        fi
        exit 0
        ;;
    restart)
        if [ -z "$DB_NAME" ]; then
            read -p "Enter database name to restart: " DB_NAME
        fi
        container_name="${DEFAULT_DB_CONTAINER_PREFIX}-${DB_NAME}"
        if docker restart "$container_name"; then
            echo "Container $container_name restarted successfully"
        else
            echo "Failed to restart container $container_name"
            exit 1
        fi
        exit 0
        ;;
    start)
        # Rest of your existing start logic here
        # [Previous start container code remains the same...]
        ;;
esac

# Function to check if user is in docker group
check_docker_permissions() {
    if ! groups | grep -q "docker"; then
        echo "Error: Current user is not in the docker group."
        echo "To fix this, run these commands:"
        echo "  sudo groupadd docker          # Create the docker group if it doesn't exist"
        echo "  sudo usermod -aG docker \$USER  # Add your user to the docker group"
        echo "  newgrp docker                 # Activate the changes to groups"
        echo "Or run this script with sudo"
        return 1
    fi
    return 0
}

# Function to validate database name
validate_db_name() {
    local db_name=$1
    if ! [[ $db_name =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        echo "Error: Database name must start with a letter and contain only letters, numbers, underscores, or hyphens"
        return 1
    fi
    return 0
}

# Function to check if port is available
check_port_available() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 1
        fi
    else
        if nc -z localhost "$port" 2>/dev/null; then
            return 1
        fi
    fi
    return 0
}

# Function to generate secure password
generate_secure_password() {
    openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16
}

# Check for docker installation and daemon
if ! [ -x "$(command -v docker)" ]; then
    echo "Error: Docker is not installed. Please install docker and try again."
    echo "Docker install guide: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check Docker permissions
if ! docker info > /dev/null 2>&1; then
    if [ "$EUID" -ne 0 ]; then
        if ! check_docker_permissions; then
            echo "Error: Docker daemon is not accessible. Either:"
            echo "1. Add your user to the docker group (recommended)"
            echo "2. Run this script with sudo"
            exit 1
        fi
    fi
    echo "Error: Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

# Check if data directory is writable
DATA_DIR="$HOME/docker_postgres_data"
if ! mkdir -p "$DATA_DIR" 2>/dev/null; then
    echo "Error: Cannot create data directory at $DATA_DIR"
    echo "Please check your permissions or specify a different location"
    exit 1
fi

# Prompt for database name
while true; do
    read -p "Enter database name (default: test): " DB_NAME
    DB_NAME=${DB_NAME:-test}
    if validate_db_name "$DB_NAME"; then
        break
    fi
done

# Create unique container name based on database name
DB_CONTAINER_NAME="${DB_NAME}${DEFAULT_DB_CONTAINER_PREFIX}"

# Check if a container with this name already exists
if [ "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "Warning: Database container '$DB_CONTAINER_NAME' is already running"
    read -p "Would you like to (s)top it, (r)estart it, or (q)uit? [s/r/q]: " -r REPLY
    case $REPLY in
        s|S) 
            docker stop "$DB_CONTAINER_NAME" || {
                echo "Error: Failed to stop container. Try using sudo or check docker permissions."
                exit 1
            }
            echo "Container stopped"
            exit 0
            ;;
        r|R)
            docker restart "$DB_CONTAINER_NAME" || {
                echo "Error: Failed to restart container. Try using sudo or check docker permissions."
                exit 1
            }
            echo "Container restarted"
            exit 0
            ;;
        *)
            echo "Operation cancelled"
            exit 0
            ;;
    esac
fi

# Check for existing stopped container
if [ "$(docker ps -q -a -f name=$DB_CONTAINER_NAME)" ]; then
    read -p "Found existing container '$DB_CONTAINER_NAME'. Would you like to (s)tart it, (r)emove it and create new, or (q)uit? [s/r/q]: " -r REPLY
    case $REPLY in
        s|S)
            docker start "$DB_CONTAINER_NAME" || {
                echo "Error: Failed to start container. Try using sudo or check docker permissions."
                exit 1
            }
            echo "Existing container started"
            exit 0
            ;;
        r|R)
            docker rm "$DB_CONTAINER_NAME" || {
                echo "Error: Failed to remove container. Try using sudo or check docker permissions."
                exit 1
            }
            echo "Removed existing container"
            ;;
        *)
            echo "Operation cancelled"
            exit 0
            ;;
    esac
fi

# Port selection
while true; do
    read -p "Enter desired port (default: $DEFAULT_DB_PORT): " DB_PORT
    DB_PORT=${DB_PORT:-$DEFAULT_DB_PORT}
    if ! [[ "$DB_PORT" =~ ^[0-9]+$ ]] || [ "$DB_PORT" -lt 1024 ] || [ "$DB_PORT" -gt 65535 ]; then
        echo "Error: Please enter a valid port number (1024-65535)"
        continue
    fi
    if ! check_port_available "$DB_PORT"; then
        echo "Error: Port $DB_PORT is already in use"
        continue
    fi
    break
done

# Generate secure password
DB_PASSWORD=$(generate_secure_password)

# Create specific data directory for this database
DB_DATA_DIR="$DATA_DIR/${DB_CONTAINER_NAME}"
if ! mkdir -p "$DB_DATA_DIR" 2>/dev/null; then
    echo "Error: Cannot create database-specific data directory at $DB_DATA_DIR"
    echo "Please check your permissions or specify a different location"
    exit 1
fi

# Ensure proper permissions on data directory
chmod 700 "$DB_DATA_DIR" || {
    echo "Warning: Could not set secure permissions on data directory"
    echo "Please ensure $DB_DATA_DIR has appropriate permissions"
}

IPADDRESS=$(get_ip_address)

# Start container with proper configuration
if docker run -d \
    --name "$DB_CONTAINER_NAME" \
    -e POSTGRES_USER="$DEFAULT_DB_USER" \
    -e POSTGRES_PASSWORD="$DB_PASSWORD" \
    -e POSTGRES_DB="$DB_NAME" \
    -e POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8" \
    -v "$DB_DATA_DIR":/var/lib/postgresql/data \
    --restart unless-stopped \
    -p "$DB_PORT":5432 \
    docker.io/postgres:15-alpine; then
    
    echo "Database container '$DB_CONTAINER_NAME' successfully created"
    echo
    echo "Connection Information:"
    echo "----------------------"
    echo "Container Name: $DB_CONTAINER_NAME"
    echo "Database Name: $DB_NAME"
    echo "Port: $DB_PORT"
    echo "Username: $DEFAULT_DB_USER"
    echo "Password: $DB_PASSWORD"
    echo
    echo "Connection URL:"
    echo "postgresql://$DEFAULT_DB_USER:$DB_PASSWORD@$IPADDRESS:$DB_PORT/$DB_NAME"
    echo
    echo "Data Directory: $DB_DATA_DIR"
    echo
    echo "To stop the container: docker stop $DB_CONTAINER_NAME"
    echo "To start the container: docker start $DB_CONTAINER_NAME"
    echo "To remove the container: docker rm $DB_CONTAINER_NAME"
else
    echo "Error: Failed to create database container. Common issues:"
    echo "1. Insufficient permissions (try running with sudo)"
    echo "2. Docker daemon not running"
    echo "3. Insufficient disk space"
    echo "4. Port conflicts"
    exit 1
fi
