#!/bin/bash
# test-network-switching.sh - Test network detection for both environments

echo "🧪 Testing HomeLab Network Detection"
echo "=================================="

# Show current detection
echo "1. Current Network Detection:"
./homelab.sh network

echo ""
echo "2. Current compose.yaml network configuration:"
if [ -f "compose.yaml" ]; then
    grep -E "subnet:|ipv4_address.*\.5[3-9]|ipv4_address.*\.6[0-4]" compose.yaml | head -5
else
    echo "   No compose.yaml found"
fi

echo ""
echo "3. Environment variable verification:"
echo "   NETWORK_PREFIX: ${NETWORK_PREFIX:-'not set (will default to 192.168.5)'}"
echo "   NETWORK_INTERFACE: ${NETWORK_INTERFACE:-'not set'}"

echo ""
echo "4. Service IP allocation test:"
echo "   Expected IP ranges:"
echo "   📍 Research Network: 192.168.5.53-64"
echo "   📍 Lab Network:      192.168.3.53-64"
echo ""
echo "   Current allocation:"
if [ -f "compose.yaml" ]; then
    grep "ipv4_address:" compose.yaml | sort -V | head -5
    echo "   ... (total $(grep -c ipv4_address compose.yaml) services)"
else
    echo "   No current allocation (compose.yaml not generated)"
fi

echo ""
echo "5. Network interface detection:"
echo "   Default route interface: $(ip route | grep default | awk '{print $5}' | head -1)"
echo "   Available interfaces with IPs:"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1" | head -6

echo ""
echo "6. Ready for network switching test?"
echo "   To test lab network (192.168.3.x):"
echo "   - Move system to lab network"
echo "   - Run: ./homelab.sh restart"
echo "   - Verify: ./homelab.sh network"
echo ""
echo "   Current system appears to be on: $(hostname -I | tr ' ' '\n' | grep -E '^192\.168\.[35]\.' | head -1 || echo 'unknown network')"
