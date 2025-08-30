# HomeLab Testing Guide

## 🚨 MacVLAN Testing (HOST CANNOT REACH MACVLAN)

**CRITICAL REALITY**: Docker host cannot reach MacVLAN containers. This is by design.

### Correct MacVLAN Testing
```bash
# ❌ This will ALWAYS fail (and that's correct)
curl http://192.168.3.x:port  # Host is isolated from MacVLAN

# ✅ Test from network perspective
docker run --rm --network host curlimages/curl:latest \
  curl -f http://192.168.3.x:port/health

# ✅ Test from another container
docker compose exec postgres curl -f http://192.168.3.x:port/health
```

**If the first command fails, that's normal. Use the second/third commands.**

## Testing Patterns

### Service Health Testing
```bash
# Check all services are running
docker compose ps

# Test specific service (use network-aware approach)
docker run --rm --network host curlimages/curl:latest \
  curl -f http://192.168.3.X:PORT/health

# Test from existing service container
docker compose exec postgres curl -f http://192.168.3.X:PORT/health
```

### Network Connectivity Testing
```bash
# Test container has correct IP
docker compose exec service-name ip addr show eth0

# Test service is listening on correct port
docker compose exec service-name netstat -tulpn | grep :PORT

# Test cross-service communication
docker compose exec service-a curl http://192.168.3.X:PORT/endpoint
```
  apk add --no-cache curl
  curl -f http://192.168.3.58:80/  # pgAdmin
### Service Validation Checklist
```bash
# 1. All services started
docker compose ps | grep -v "Exit"

# 2. Services have correct IPs  
docker compose exec service-name ip addr show eth0

# 3. Services are listening on expected ports
docker compose exec service-name netstat -tulpn

# 4. Cross-service communication works
docker compose exec postgres curl http://192.168.3.10:3000/api/health
```

### Troubleshooting Common Issues

**Service won't start**: Check `docker compose logs service-name`  
**Wrong IP assigned**: Verify `compose.yaml` network configuration  
**Can't reach from host**: Use network-aware testing (see above)  
**Service seems down**: Test from another container, not host

### Quick Health Check Script
```bash
#!/bin/bash
# Test core services from network perspective
services=(
  "192.168.3.10:3000"  # Grafana
  "192.168.3.11:9090"  # Prometheus  
  "192.168.3.12:5432"  # PostgreSQL
)

for service in "${services[@]}"; do
  if docker run --rm --network host curlimages/curl:latest \
     curl -f --connect-timeout 5 http://$service; then
    echo "✅ $service OK"
  else
    echo "❌ $service FAILED"
  fi
done
```

This testing approach ensures reliable validation of MacVLAN-networked services while respecting the host isolation design.
