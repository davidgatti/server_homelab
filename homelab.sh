#!/bin/bash

# HomeLab Management Script
# This script replaces the old systemd service approach with Docker Compose
# Now includes automatic network detection for research (192.168.5.x) vs lab (192.168.3.x) networks

set -e

COMPOSE_FILE="compose.yaml"
PROJECT_NAME="homelab"

# Network configuration
RESEARCH_NETWORK="192.168.5"
LAB_NETWORK="192.168.3"
DETECTED_NETWORK=""
DETECTED_INTERFACE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if docker and docker-compose are available
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Ensure we're using regular Docker daemon (not rootless)
    docker context use default &> /dev/null
    
    if ! docker compose version &> /dev/null; then
        error "Docker Compose is not available"
        exit 1
    fi
    
    # Verify Docker Compose supports environment variable substitution
    if ! docker compose config --help | grep -q "environment"; then
        warn "Docker Compose may not support environment variable substitution"
    fi
}

# Detect current network and interface
detect_network() {
    info "Detecting network configuration..."
    
    # Get current IP addresses on this system
    local current_ip=$(hostname -I | tr ' ' '\n' | grep -E "^($RESEARCH_NETWORK|$LAB_NETWORK)\." | head -1)
    
    if [[ "$current_ip" =~ ^$RESEARCH_NETWORK\. ]]; then
        DETECTED_NETWORK="$RESEARCH_NETWORK"
        # Get the actual interface for this IP (not loopback)
        DETECTED_INTERFACE=$(ip route get "$current_ip" | grep -oP 'dev \K\w+' | head -1)
        if [ "$DETECTED_INTERFACE" = "lo" ]; then
            # Fallback to default route interface if we got loopback
            DETECTED_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        fi
        info "🔬 Detected RESEARCH network: $DETECTED_NETWORK.x on interface $DETECTED_INTERFACE"
    elif [[ "$current_ip" =~ ^$LAB_NETWORK\. ]]; then
        DETECTED_NETWORK="$LAB_NETWORK"
        # Get the actual interface for this IP (not loopback)
        DETECTED_INTERFACE=$(ip route get "$current_ip" | grep -oP 'dev \K\w+' | head -1)
        if [ "$DETECTED_INTERFACE" = "lo" ]; then
            # Fallback to default route interface if we got loopback
            DETECTED_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        fi
        info "🏠 Detected LAB network: $DETECTED_NETWORK.x on interface $DETECTED_INTERFACE"
    else
        # Fallback: check route table for these networks
        local research_interface=$(ip route | grep "$RESEARCH_NETWORK" | grep -v docker | awk '{print $3}' | head -1 2>/dev/null || echo "")
        local lab_interface=$(ip route | grep "$LAB_NETWORK" | grep -v docker | awk '{print $3}' | head -1 2>/dev/null || echo "")
        
        if [ -n "$research_interface" ]; then
            DETECTED_NETWORK="$RESEARCH_NETWORK"
            DETECTED_INTERFACE="$research_interface"
            warn "No direct IP detected, using research network $RESEARCH_NETWORK.x on $research_interface"
        elif [ -n "$lab_interface" ]; then
            DETECTED_NETWORK="$LAB_NETWORK"
            DETECTED_INTERFACE="$lab_interface"
            warn "No direct IP detected, using lab network $LAB_NETWORK.x on $lab_interface"
        else
            # Ultimate fallback - use default route interface and assume research network
            DETECTED_NETWORK="$RESEARCH_NETWORK"
            DETECTED_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
            warn "⚠️  Network auto-detection failed, defaulting to research network $RESEARCH_NETWORK.x on $DETECTED_INTERFACE"
            warn "   Please verify this is correct for your environment"
        fi
    fi
    
    info "Using network: $DETECTED_NETWORK.0/24 on interface: $DETECTED_INTERFACE"
}

# Set environment variables for Docker Compose
set_environment_variables() {
    info "Setting environment variables for $DETECTED_NETWORK.x network..."
    
    # Export environment variables for docker compose
    export NETWORK_PREFIX="$DETECTED_NETWORK"
    export NETWORK_INTERFACE="$DETECTED_INTERFACE"
    
    info "✅ Environment variables set:"
    info "   📍 NETWORK_PREFIX=$NETWORK_PREFIX"
    info "   🔌 NETWORK_INTERFACE=$NETWORK_INTERFACE"
    info "   📋 Service IPs: $NETWORK_PREFIX.53-64"
}

# Show status of all services
status() {
    log "HomeLab Status:"
    echo "🌐 Current Network: $DETECTED_NETWORK.0/24 on $DETECTED_INTERFACE"
    echo ""
    docker compose ps
    echo
    
    log "Network Information:"
    docker network ls | grep homelab || warn "No homelab networks found"
    echo
    
    log "Volume Information:"
    docker volume ls | grep homelab || warn "No homelab volumes found"
}

# Start all services
start() {
    detect_network
    set_environment_variables
    
    log "Starting HomeLab services on $DETECTED_NETWORK.x network..."
    docker compose up -d
    
    log "Waiting for services to be healthy..."
    sleep 10
    
    status
}

# Stop all services
stop() {
    log "Stopping HomeLab services..."
    docker compose down
    log "All services stopped"
}

# Restart all services
restart() {
    log "Restarting HomeLab services..."
    stop
    sleep 2
    start  # This will auto-detect network and regenerate compose file
}

# Show logs
logs() {
    local service="${1:-}"
    if [ -n "$service" ]; then
        log "Showing logs for service: $service"
        docker compose logs -f "$service"
    else
        log "Showing logs for all services"
        docker compose logs -f
    fi
}

# Backup volumes
backup() {
    local backup_dir="/opt/homelab/backups/$(date +%Y%m%d_%H%M%S)"
    
    log "Creating backup directory: $backup_dir"
    sudo mkdir -p "$backup_dir"
    
    log "Backing up postgres data..."
    docker compose exec postgres pg_dumpall -U admin > "$backup_dir/postgres_dump.sql"
    
    log "Backing up volumes..."
    docker run --rm -v homelab_postgres-data:/data -v "$backup_dir":/backup alpine tar czf /backup/postgres-data.tar.gz -C /data .
    
    log "Backup completed: $backup_dir"
}

# Show help
help() {
    cat << EOF
HomeLab Management Script

Usage: $0 [COMMAND]

Commands:
    start       Start all services (auto-detects network)
    stop        Stop all services  
    restart     Restart all services
    status      Show status of all services and current network
    logs [service]  Show logs (optional: specific service)
    backup      Backup all data
    network     Show current network detection
    help        Show this help message

Network Auto-Detection:
    🔬 Research Network: 192.168.5.x (automatically detected)
    🏠 Lab Network:      192.168.3.x (automatically detected)
    
    The script automatically detects which network you're on and
    exports NETWORK_PREFIX and NETWORK_INTERFACE environment variables
    for Docker Compose to use with native variable substitution.

Examples:
    $0 start           # Auto-detect network and start
    $0 network         # Show detected network info
    $0 logs postgres   # Show postgres logs
    $0 status          # Show services and network info

This script replaces the old approach of:
- Manual docker commands
- systemd service files  
- Individual container management
- Manual network configuration

EOF
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-help}" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            # For status, we need to detect network but don't need to set env vars
            if [ -f "$COMPOSE_FILE" ]; then
                detect_network
                status
            else
                warn "No compose file found. Run '$0 start' first to start services."
            fi
            ;;
        logs)
            logs "$2"
            ;;
        backup)
            backup
            ;;
        network)
            detect_network
            info "🌐 Network Detection Results:"
            info "   Detected Network: $DETECTED_NETWORK.0/24"
            info "   Interface: $DETECTED_INTERFACE"
            info "   Service IP Range: $DETECTED_NETWORK.53-64"
            info "   Environment Variables:"
            info "     NETWORK_PREFIX=$DETECTED_NETWORK"
            info "     NETWORK_INTERFACE=$DETECTED_INTERFACE"
            ;;
        help|--help|-h)
            help
            ;;
        *)
            error "Unknown command: $1"
            help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
