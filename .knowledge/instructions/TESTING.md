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

## MacVLAN Network Testing Strategy

### Problem
When using MacVLAN networks in Docker Compose, the host machine cannot directly access container IPs because MacVLAN creates isolated Layer 2 network segments. This makes it impossible to test service connectivity from the host using standard tools like `curl` or `wget`.

### Solution: Temporary Test Container Method

Use a temporary container with its own MacVLAN IP to test connectivity between services within the MacVLAN network.

### How It Works

1. **MacVLAN Isolation**: Containers on MacVLAN networks can communicate with each other but are isolated from the host network stack
2. **Container-to-Container Communication**: Services within the same MacVLAN network can reach each other directly
3. **Test Container**: Deploy a temporary container with network tools on the same MacVLAN network to test connectivity

### Implementation

#### Basic Test Container Command
```bash
docker run --rm -it \
  --network homelab \
  --ip 192.168.3.100 \
  --name network-test \
  alpine:latest sh -c "
    echo 'Testing MacVLAN connectivity from container IP 192.168.3.100'
    apk add --no-cache curl
    curl -s --connect-timeout 5 http://TARGET_IP:PORT/endpoint
    echo 'Test complete'
  "
```

#### Example: Testing cAdvisor Service
```bash
docker run --rm --network homelab --ip 192.168.3.101 alpine:latest sh -c "
  echo 'Testing cAdvisor on port 80...'
  apk add --no-cache curl > /dev/null 2>&1
  curl -s --connect-timeout 5 http://192.168.3.62:80/metrics | head -5
  echo 'Success! cAdvisor is responding on port 80 from MacVLAN container!'
"
```

### Key Components

#### Network Configuration
- **Network Name**: `homelab` (as defined in compose.yaml)
- **Test IP Range**: Use available IPs in the subnet (e.g., 192.168.3.100-192.168.3.200)
- **Target IPs**: Service IPs as defined in environment variables

#### Test Container Setup
- **Base Image**: `alpine:latest` (lightweight, fast to pull)
- **Network Tools**: Install `curl`, `wget`, or other tools as needed
- **Cleanup**: Use `--rm` flag for automatic cleanup
- **IP Assignment**: Assign a unique IP not used by services

#### Common Test Scenarios

##### 1. HTTP Service Health Check
```bash
docker run --rm --network homelab --ip 192.168.3.100 alpine:latest sh -c "
  apk add --no-cache curl
  curl -f http://192.168.3.58:80/  # pgAdmin
  echo 'pgAdmin is accessible'
"
```

##### 2. Metrics Endpoint Testing
```bash
docker run --rm --network homelab --ip 192.168.3.100 alpine:latest sh -c "
  apk add --no-cache curl
  curl -s http://192.168.3.59:80/metrics | grep -c '^# '  # Prometheus
  echo 'Prometheus metrics endpoint working'
"
```

##### 3. Database Connectivity
```bash
docker run --rm --network homelab --ip 192.168.3.100 alpine:latest sh -c "
  apk add --no-cache postgresql-client
  pg_isready -h 192.168.3.53 -p 5432
  echo 'PostgreSQL is ready'
"
```

### Available Test IP Ranges

Based on current service allocations (192.168.3.53-192.168.3.64), safe test IPs:
- **192.168.3.100-192.168.3.200**: Available for testing
- **192.168.3.2-192.168.3.52**: Also available if needed

### Best Practices

#### 1. Use Unique IPs
Always assign a unique IP to avoid conflicts with running services.

#### 2. Cleanup After Testing
Use `--rm` flag to automatically remove test containers.

#### 3. Install Tools Quietly
Use `> /dev/null 2>&1` to suppress package installation output for cleaner test results.

#### 4. Set Connection Timeouts
Use `--connect-timeout` to avoid hanging on failed connections.

#### 5. Test Multiple Aspects
- **Connectivity**: Can the service be reached?
- **Functionality**: Does the endpoint return expected data?
- **Performance**: Response time and reliability

### Troubleshooting

#### Container Cannot Join Network
- Verify the MacVLAN network exists: `docker network ls`
- Check if IP is already in use: `docker network inspect homelab`
- Ensure parent interface is correct in compose.yaml

#### Service Not Responding
- Check if target service is running: `docker ps`
- Verify service logs: `docker logs [container_name]`
- Confirm port configuration in compose.yaml

#### Network Isolation Issues
- Ensure both containers are on same MacVLAN network
- Verify subnet configuration matches environment variables
- Check firewall rules if applicable

### Alternative Testing Methods

#### 1. Docker Exec into Running Container
```bash
docker exec -it [container_name] sh
# Then run network commands from within the container
```

#### 2. Service-to-Service Testing
Use one service to test another (e.g., Prometheus testing targets).

#### 3. External Network Access
Test from another machine on the same physical network (192.168.3.x range).

### Integration with CI/CD

This testing method can be integrated into automated testing pipelines:

```bash
#!/bin/bash
# Test all critical services
SERVICES=(
  "192.168.3.58:80"    # pgAdmin
  "192.168.3.59:80"    # Prometheus
  "192.168.3.60:80"    # Grafana
  "192.168.3.62:80"    # cAdvisor
)

for service in "${SERVICES[@]}"; do
  if docker run --rm --network homelab --ip 192.168.3.100 alpine:latest sh -c "
    apk add --no-cache curl > /dev/null 2>&1
    curl -f --connect-timeout 5 http://$service
  "; then
    echo "✅ $service is accessible"
  else
    echo "❌ $service is not accessible"
    exit 1
  fi
done
```

### Summary

This MacVLAN testing strategy provides a reliable way to test service connectivity within isolated container networks. By using temporary test containers with MacVLAN IPs, we can:

- Verify service availability and functionality
- Debug network connectivity issues
- Automate health checks and monitoring
- Validate configuration changes before deployment

The method is lightweight, fast, and doesn't require any permanent infrastructure changes.
