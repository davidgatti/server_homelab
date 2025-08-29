#!/bin/bash
# homelab-resource-monitor.sh - HomeLab Resource Usage Monitor

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

# Container Resource Usage with Health Status
echo -e "\n📊 Container Resource Usage & Health:"
echo "-------------------------------------"
{
    echo "Container|Container ID|CPU %|CPU Limit|Mem Used|Mem Limit|Mem %|Net In|Net Out|Block Read|Block Write|Health Status"
    docker stats --no-stream --format "{{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | while IFS=$'\t' read -r container_id name cpu_perc mem_usage mem_perc net_io block_io; do
        # Truncate container ID to first 12 characters
        short_id=$(echo "$container_id" | cut -c1-12)
        
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
        
        echo "$name|$short_id|$cpu_perc|$cpu_limit|$mem_used|$mem_limit|$mem_perc|$net_in|$net_out|$block_read|$block_write|$health_status"
    done | sort
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

echo -e "\n💡 Tips:"
echo "--------"
echo "• Use 'docker logs <container>' to check specific service logs"
echo "• Use './homelab.sh status' for overall service health"
