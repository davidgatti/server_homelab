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

# MAC Address generation functions
network_to_mac_id() {
    local network="$1"
    case "$network" in
        "192.168.3") echo "03" ;;
        "192.168.5") echo "05" ;;
        "192.168.7") echo "07" ;;
        *) echo "XX" ;;
    esac
}

generate_mac_address() {
    local ip_last_octet="$1"
    local network_id=$(network_to_mac_id "$DETECTED_NETWORK")
    local hex_octet=$(printf "%02x" "$ip_last_octet")
    echo "02:42:48:4C:$network_id:$hex_octet"
}

show_mac_addresses() {
    info "📍 MAC Addresses for $DETECTED_NETWORK.x network:"
    local network_id=$(network_to_mac_id "$DETECTED_NETWORK")
    local mac_prefix="02:42:48:4C:$network_id"
    echo "   Pattern: $mac_prefix:XX"
    echo "   postgres      ($DETECTED_NETWORK.53): $mac_prefix:35  (53 → 0x35) [homelab-postgres]"
    echo "   watchtower    ($DETECTED_NETWORK.54): $mac_prefix:36  (54 → 0x36) [homelab-watchtower]"
    echo "   alertmanager  ($DETECTED_NETWORK.56): $mac_prefix:38  (56 → 0x38) [homelab-alertmanager]"
    echo "   prometheus    ($DETECTED_NETWORK.59): $mac_prefix:3b  (59 → 0x3B) [homelab-prometheus]"
    echo "   grafana       ($DETECTED_NETWORK.60): $mac_prefix:3c  (60 → 0x3C) [homelab-grafana]"
    echo ""
    info "🔧 Template for compose.yaml (matches IP structure):"
    echo "   IP:       ipv4_address: \${NETWORK_PREFIX:-192.168.5}.53"
    echo "   MAC:      mac_address: \${MAC_NETWORK_PREFIX:-$mac_prefix}:35"
    echo "   Hostname: hostname: homelab-servicename"
    echo ""
    info "💡 Environment Variable:"
    echo "   MAC_NETWORK_PREFIX=$mac_prefix"
    echo ""
    info "🏠 UDM Router Benefits:"
    echo "   • Clear service identification in network dashboard"
    echo "   • Hostname-based device recognition"
    echo "   • HomeLab services easily distinguishable from other devices"
}

# Set environment variables for Docker Compose
set_environment_variables() {
    info "Setting environment variables for $DETECTED_NETWORK.x network..."
    
    # Export network environment variables for docker compose
    export NETWORK_PREFIX="$DETECTED_NETWORK"
    export NETWORK_INTERFACE="$DETECTED_INTERFACE"
    
    # Export MAC network prefix (same structure as IP addresses)
    local network_id=$(network_to_mac_id "$DETECTED_NETWORK")
    export MAC_NETWORK_PREFIX="02:42:48:4C:$network_id"
    
    info "✅ Environment variables set:"
    info "   📍 NETWORK_PREFIX=$NETWORK_PREFIX"
    info "   🔌 NETWORK_INTERFACE=$NETWORK_INTERFACE"
    info "   📋 Service IPs: $NETWORK_PREFIX.53-65"
    info "   🔗 MAC Network Prefix: $MAC_NETWORK_PREFIX"
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
    mac         Show MAC addresses for current network
    hostnames   Show hostnames for UDM router identification
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
    $0 mac             # Show MAC addresses for current network
    $0 hostnames       # Show hostnames for UDM router
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
        mac|macs)
            detect_network
            show_mac_addresses
            ;;
        hostnames|hosts)
            detect_network
            info "🏠 HomeLab Hostnames for UDM Router:"
            echo "   Service hostnames that will appear in your UDM dashboard:"
            echo ""
            
            # Get list of running containers and their configured hostnames using docker inspect only
            docker ps --format "{{.Names}}" | grep -E "(postgres|watchtower|alertmanager|prometheus|grafana|redis|cadvisor|blackbox|pgadmin)" | sort | while read container_name; do
                # Get hostname and IP from docker inspect (more reliable)
                hostname=$(docker inspect "$container_name" --format '{{.Config.Hostname}}' 2>/dev/null || echo "unknown")
                ip_addr=$(docker inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "N/A")
                
                echo "   $container_name → $hostname ($ip_addr)"
            done
            
            echo ""
            info "💡 These hostnames will be visible in your UDM network dashboard"
            info "   making it easy to identify HomeLab services among other devices."
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
