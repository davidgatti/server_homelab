#!/bin/bash
# test-dependency-order.sh - Test HomeLab dependency startup order

echo "🔄 Testing HomeLab Dependency Order"
echo "==================================="

echo "📱 Step 1: Stopping all services..."
docker compose down

echo ""
echo "🚀 Step 2: Starting services with dependency order..."
echo "Watch how services start in proper order:"
echo ""

# Start with verbose output to see the order
docker compose up -d --wait

echo ""
echo "✅ Step 3: Final status check..."
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}" | head -10

echo ""
echo "🎯 Dependency Order Test Complete!"
echo ""
echo "Expected Order:"
echo "1. postgres, watchtower (base services)"
echo "2. postgres-backup, pgadmin, postgres-exporter (depend on postgres)"  
echo "3. cadvisor (independent)"
echo "4. prometheus (depends on cadvisor + postgres-exporter)"
echo "5. grafana (depends on prometheus + postgres)"
echo "6. volume-backup (depends on postgres)"
