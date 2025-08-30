#!/bin/bash
# homelab-resource-monitor.sh - HomeLab Resource Usage Monitor with Complete Service Tracking

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to convert bytes to human readable format
bytes_to_human() {
    local bytes=$1
    if [[ $bytes =~ ^[0-9]+$ ]]; then
        echo "$bytes" | numfmt --to=iec-i --suffix=B
    else
        echo "$bytes"
    fi
}

# Function to get expected services from compose.yaml
get_expected_services() {
    if [ ! -f "compose.yaml" ]; then
        echo "ERROR: compose.yaml not found!" >&2
        return 1
    fi
    
    # Extract only service names from compose.yaml (under 'services:' section)
    # Look for lines that start with two spaces and a service name, but only under services section
    awk '
    /^services:/ { in_services=1; next }
    /^[a-zA-Z]/ && in_services { in_services=0 }
    in_services && /^  [a-zA-Z0-9_-]+:/ { 
        gsub(/^  /, ""); 
        gsub(/:.*/, ""); 
        print 
    }
    ' compose.yaml | sort
}

echo "🏠 HomeLab Resource Monitor - $(date)"
echo "======================================"

# System Overview
echo -e "\n💻 System Resources:"
echo "-------------------"
TOTAL_MEM=$(free -h | awk 'NR==2{print $2}')
AVAIL_MEM=$(free -h | awk 'NR==2{print $7}')
USED_MEM=$(free -h | awk 'NR==2{print $3}')
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')

echo "Total Memory: $TOTAL_MEM"
echo "Used Memory: $USED_MEM"
echo "Available Memory: $AVAIL_MEM"
echo "CPU Cores: $CPU_CORES"
echo "Load Average:$LOAD_AVG"

# Get expected services from compose.yaml
EXPECTED_SERVICES=$(get_expected_services)
if [ $? -ne 0 ]; then
    echo "Failed to read expected services from compose.yaml"
    exit 1
fi

# Count expected vs running services
EXPECTED_COUNT=$(echo "$EXPECTED_SERVICES" | wc -l)
RUNNING_COUNT=$(docker ps --format "{{.Names}}" | wc -l)

echo -e "\n📈 Service Overview:"
echo "-------------------"
echo "Expected Services: $EXPECTED_COUNT"
echo "Running Services: $RUNNING_COUNT"
if [ "$RUNNING_COUNT" -eq "$EXPECTED_COUNT" ]; then
    echo -e "Status: ${GREEN}🟢 All services running${NC}"
else
    echo -e "Status: ${RED}🔴 $(($EXPECTED_COUNT - $RUNNING_COUNT)) service(s) missing${NC}"
fi

# Container Resource Usage with Health Status - NOW INCLUDES ALL EXPECTED SERVICES
echo -e "\n📊 Complete Service Status & Resource Usage:"
echo "--------------------------------------------"

# Create arrays for running containers and all expected services
RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" | sort)

{
    echo "Service|Container ID|Status|Hostname|IP Address|MAC Address|CPU %|CPU Limit|Mem Used|Mem Limit|Mem %|Net In|Net Out|Block Read|Block Write|Docker Health|Resource Status"
    
    # Process all expected services
    echo "$EXPECTED_SERVICES" | while read -r service; do
        # Check if this service is running
        if echo "$RUNNING_CONTAINERS" | grep -q "^$service$"; then
            # Service is running - get its stats
            docker stats --no-stream --format "{{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" "$service" 2>/dev/null | while IFS=$'\t' read -r container_id name cpu_perc mem_usage mem_perc net_io block_io; do
                # Truncate container ID to first 12 characters
                short_id=$(echo "$container_id" | cut -c1-12)
                
                # Get hostname from Docker inspect
                hostname=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].Config.Hostname // "N/A"' 2>/dev/null || echo "N/A")
                
                # Get IP and MAC address from Docker inspect
                ip_address=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks.homelab.IPAddress // "N/A"' 2>/dev/null || echo "N/A")
                mac_address=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks.homelab.MacAddress // "N/A"' 2>/dev/null || echo "N/A")
                
                # Get Docker health check status
                docker_health=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].State.Health.Status // "none"' 2>/dev/null || echo "none")
                case "$docker_health" in
                    "healthy") docker_health_display="🟢 Healthy" ;;
                    "unhealthy") docker_health_display="🔴 Unhealthy" ;;
                    "starting") docker_health_display="🟡 Starting" ;;
                    "none") docker_health_display="⚪ No Check" ;;
                    *) docker_health_display="❓ Unknown" ;;
                esac
                
                # If homelab network not found, try first available network
                if [ "$ip_address" = "N/A" ] || [ "$ip_address" = "null" ]; then
                    ip_address=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries | .[0].value.IPAddress // "N/A"' 2>/dev/null || echo "N/A")
                fi
                if [ "$mac_address" = "N/A" ] || [ "$mac_address" = "null" ]; then
                    mac_address=$(docker inspect "$container_id" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries | .[0].value.MacAddress // "N/A"' 2>/dev/null || echo "N/A")
                fi
                
                # Split memory usage (used / limit)
                mem_used=$(echo "$mem_usage" | cut -d'/' -f1 | xargs)
                mem_limit=$(echo "$mem_usage" | cut -d'/' -f2 | xargs)
                
                # Get CPU limit from compose.yaml
                cpu_limit=$(docker compose config 2>/dev/null | grep -A 20 "^  $name:" | grep -A 10 "limits:" | grep "cpus:" | head -1 | awk '{print $2}' | tr -d "'" | tr -d '"' || echo "No limit")
                [ "$cpu_limit" = "" ] && cpu_limit="No limit"
                
                # Split network I/O (input / output)
                net_in=$(echo "$net_io" | cut -d'/' -f1 | xargs)
                net_out=$(echo "$net_io" | cut -d'/' -f2 | xargs)
                
                # Split block I/O (read / write)
                block_read=$(echo "$block_io" | cut -d'/' -f1 | xargs)
                block_write=$(echo "$block_io" | cut -d'/' -f2 | xargs)
                
                # Calculate health status
                mem_value=$(echo "$mem_perc" | sed 's/%//')
                cpu_value=$(echo "$cpu_perc" | sed 's/%//')
                
                # Determine health status
                health_status="🟢 OK"
                if (( $(echo "$mem_value > 85" | bc -l 2>/dev/null || echo "0") )); then
                    health_status="🔴 CRITICAL"
                elif (( $(echo "$mem_value > 70" | bc -l 2>/dev/null || echo "0") )); then
                    health_status="🟡 WATCH"
                elif (( $(echo "$cpu_value > 80" | bc -l 2>/dev/null || echo "0") )); then
                    health_status="🟡 HIGH CPU"
                fi
                
                echo "$name|$short_id|🟢 RUNNING|$hostname|$ip_address|$mac_address|$cpu_perc|$cpu_limit|$mem_used|$mem_limit|$mem_perc|$net_in|$net_out|$block_read|$block_write|$docker_health_display|$health_status"
            done
        else
            # Service is missing
            echo "$service|N/A|🔴 MISSING|N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|🔴 NOT RUNNING"
        fi
    done
} | column -t -s '|'

# Resource Warnings
echo -e "\n⚠️  Resource Analysis:"
echo "---------------------"

# Check memory pressure
USED_MEM=$(free | awk 'NR==2{printf "%.1f", $3/1024/1024}')
if (( $(echo "$USED_MEM > 4.0" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🔴 HIGH MEMORY USAGE: ${USED_MEM}GB used - Consider stopping non-essential services"
elif (( $(echo "$USED_MEM > 3.0" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🟡 MODERATE MEMORY USAGE: ${USED_MEM}GB used - Monitor closely"
else
    echo -e "🟢 GOOD MEMORY USAGE: ${USED_MEM}GB used - Healthy levels"
fi

# Check load average  
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
LOAD_THRESHOLD=$(echo "$CPU_CORES * 0.8" | bc -l 2>/dev/null || echo "1.6")
if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🔴 HIGH CPU LOAD: $LOAD_1MIN (threshold: $LOAD_THRESHOLD)"
else
    echo -e "🟢 GOOD CPU LOAD: $LOAD_1MIN (threshold: $LOAD_THRESHOLD)"
fi

# Missing services analysis
echo -e "\n🔍 Missing Services Analysis:"
echo "-----------------------------"
MISSING_SERVICES=$(echo "$EXPECTED_SERVICES" | while read -r service; do
    if ! docker ps --format "{{.Names}}" | grep -q "^$service$"; then
        echo "$service"
    fi
done)

if [ -z "$MISSING_SERVICES" ]; then
    echo -e "🟢 All expected services are running!"
else
    echo -e "🔴 Missing services detected:"
    echo "$MISSING_SERVICES" | while read -r missing; do
        echo "   • $missing"
    done
    echo ""
    echo -e "💡 To start missing services: ${BLUE}./homelab.sh start${NC}"
    echo -e "💡 To check specific service: ${BLUE}docker logs $missing${NC}"
fi

echo -e "\n📋 Service Summary:"
echo "-------------------"
echo "Expected: $EXPECTED_COUNT services"
echo "Running:  $RUNNING_COUNT services"
echo "Missing:  $(echo "$MISSING_SERVICES" | grep -c . 2>/dev/null || echo "0") services"

echo -e "\n💡 Tips:"
echo "--------"
echo "• Use 'docker logs <container>' to check specific service logs"
echo "• Use './homelab.sh status' for overall service health"
echo "• Use './homelab.sh restart' to restart all services"
echo "• Use './homelab.sh reset --force' for complete reset (DANGER: wipes all data)"
