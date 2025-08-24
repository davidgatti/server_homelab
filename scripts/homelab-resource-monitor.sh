#!/bin/bash
# homelab-resource-monitor.sh - HomeLab Resource Usage Monitor

echo "🏠 HomeLab Resource Monitor - $(date)"
echo "======================================"

# System Overview
echo "💻 System Resources:"
echo "-------------------"
TOTAL_MEM=$(free -h | awk 'NR==2{printf "%.1fGB", $2/1024/1024/1024}')
AVAIL_MEM=$(free -h | awk 'NR==2{printf "%.1fGB", $7/1024/1024/1024}')
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')

echo "Total Memory: $TOTAL_MEM"
echo "Available Memory: $AVAIL_MEM"
echo "CPU Cores: $CPU_CORES (Intel Celeron N3350 @ 1.10GHz)"
echo "Load Average:$LOAD_AVG"

# Container Resource Usage
echo -e "\n📊 Container Resource Usage:"
echo "-----------------------------"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

# Resource Allocation Summary
echo -e "\n📋 HomeLab-Optimized Resource Allocation:"
echo "----------------------------------------"
echo "Service          | Memory Limit | CPU Limit | Purpose"
echo "-----------------|--------------|-----------|------------------"
echo "postgres         | 800M         | 0.8 cores | Database (priority)"
echo "prometheus       | 500M         | 0.6 cores | Metrics storage" 
echo "grafana          | 400M         | 0.4 cores | Dashboard"
echo "pgadmin          | 300M         | 0.25 cores| Admin interface"
echo "volume-backup    | 256M         | 0.3 cores | Backup service"
echo "cadvisor         | 200M         | 0.2 cores | Container monitoring"
echo "watchtower       | 128M         | 0.1 cores | Update service"
echo "postgres-exporter| 100M         | 0.1 cores | DB metrics"
echo ""
echo "Total Limits: ~2.7GB Memory | ~2.85 CPU cores"
echo "System Capacity: 5.6GB Memory | 2 CPU cores"
echo "Safety Margin: 2.9GB Memory | Oversubscribed CPU (normal for HomeLab)"

# Resource Warnings
echo -e "\n⚠️  Resource Analysis:"
echo "---------------------"

# Check memory pressure
USED_MEM=$(free | awk 'NR==2{printf "%.0f", $3/1024/1024}')
if [ $USED_MEM -gt 4000 ]; then
    echo "🔴 HIGH MEMORY USAGE: ${USED_MEM}MB used - Consider stopping non-essential services"
elif [ $USED_MEM -gt 3000 ]; then
    echo "🟡 MODERATE MEMORY USAGE: ${USED_MEM}MB used - Monitor closely"
else
    echo "🟢 GOOD MEMORY USAGE: ${USED_MEM}MB used - Healthy levels"
fi

# Check load average  
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
LOAD_THRESHOLD=$(echo "$CPU_CORES * 0.8" | bc -l)
if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
    echo "🔴 HIGH CPU LOAD: $LOAD_1MIN (threshold: $LOAD_THRESHOLD)"
else
    echo "🟢 GOOD CPU LOAD: $LOAD_1MIN (threshold: $LOAD_THRESHOLD)"
fi

# Check for containers hitting limits
echo -e "\n🔍 Container Health Check:"
echo "-------------------------"
docker stats --no-stream --format "{{.Container}} {{.MemPerc}}" | while read container mem_percent; do
    if [ ! -z "$mem_percent" ]; then
        mem_value=$(echo $mem_percent | sed 's/%//')
        if (( $(echo "$mem_value > 85" | bc -l) )); then
            echo "🔴 $container using $mem_percent of memory limit - CRITICAL"
        elif (( $(echo "$mem_value > 70" | bc -l) )); then
            echo "🟡 $container using $mem_percent of memory limit - WATCH"
        else
            echo "🟢 $container using $mem_percent of memory limit - OK"
        fi
    fi
done

echo -e "\n💡 HomeLab Optimization Tips:"
echo "-----------------------------"
echo "• These limits are optimized for a 5.6GB Celeron system"
echo "• CPU oversubscription is normal (containers rarely use full allocation)"
echo "• Database gets highest priority (800M + 0.8 cores)"
echo "• Monitoring stack gets second priority (Prometheus/Grafana)"
echo "• Background services are heavily limited to preserve resources"
echo "• Monitor during peak usage and adjust limits if needed"

echo -e "\n🎯 Next Steps:"
echo "-------------"
echo "• Run this script weekly to monitor trends"
echo "• If services hit limits frequently, consider:"
echo "  - Increasing limits for critical services"
echo "  - Decreasing limits for underutilized services"
echo "  - Adding more RAM or upgrading CPU if budget allows"
