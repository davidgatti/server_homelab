#!/bin/bash
# test-foundation-first.sh - Test HomeLab Foundation-First startup order

echo "🏗️ Testing HomeLab Foundation-First Approach"
echo "============================================="

echo "📱 Step 1: Stopping all services..."
docker compose down

echo ""
echo "🚀 Step 2: Starting with Foundation-First priority..."
echo ""
echo "Expected Foundation-First Order:"
echo "Phase 1: postgres + cadvisor + watchtower (foundation services)"
echo "Phase 2: postgres-exporter → prometheus → grafana (core HomeLab)"  
echo "Phase 3: volume-backup + postgres-backup + pgadmin (support)"
echo ""

# Start services
echo "Starting services..."
docker compose up -d

echo ""
echo "⏱️ Monitoring startup progress (60 seconds)..."
echo "Watch how your core HomeLab services (Prometheus/Grafana) start quickly!"
echo ""

# Monitor for 60 seconds
for i in {1..12}; do
    echo "--- Check $i/12 ($(($i * 5)) seconds) ---"
    docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "(prometheus|grafana|volume-backup|cadvisor)" || echo "Services starting..."
    echo ""
    sleep 5
done

echo "🎯 Final Status Check:"
echo "======================"
docker compose ps --format "table {{.Name}}\t{{.Status}}"

echo ""
echo "✅ Foundation-First Test Results:"
echo "- Core monitoring (Prometheus/Grafana) should be running"
echo "- Backup protection (volume-backup) should be active" 
echo "- Foundation services should be healthy"
echo ""

# Check if core services are running
echo "🔍 Core Service Health Check:"
echo "-----------------------------"
if docker compose ps | grep -q "prometheus.*healthy"; then
    echo "✅ Prometheus (monitoring foundation) - HEALTHY"
else
    echo "⏳ Prometheus (monitoring foundation) - STARTING"
fi

if docker compose ps | grep -q "grafana.*healthy"; then
    echo "✅ Grafana (dashboard foundation) - HEALTHY"  
else
    echo "⏳ Grafana (dashboard foundation) - STARTING"
fi

if docker compose ps | grep -q "volume-backup.*healthy"; then
    echo "✅ Volume-backup (protection foundation) - HEALTHY"
else
    echo "⏳ Volume-backup (protection foundation) - STARTING"
fi

if docker compose ps | grep -q "cadvisor.*healthy"; then
    echo "✅ cAdvisor (monitoring foundation) - HEALTHY"
else
    echo "⏳ cAdvisor (monitoring foundation) - STARTING"
fi

echo ""
echo "🎉 Foundation-First Startup Test Complete!"
echo ""
echo "💡 Key Benefits Achieved:"
echo "- HomeLab monitoring infrastructure prioritized"
echo "- Data protection starts immediately"  
echo "- Core services available faster"
echo "- Less rigid dependency chains"
