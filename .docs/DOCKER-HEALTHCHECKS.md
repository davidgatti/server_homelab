# HomeLab Healthcheck Configuration

This document summarizes all the Docker healthchecks configured for the HomeLab services.

## 📋 Healthcheck Summary

| Service | Type | Test Command | Interval | Timeout | Retries | Start Period |
|---------|------|-------------|----------|---------|---------|--------------|
| **postgres** | Database | `pg_isready -U admin -d default` | 30s | 10s | 3 | 30s |
| **postgres-backup** | HTTP Service | `curl -f http://localhost:8080/` | 5m | 3s | 3 | 30s |
| **volume-backup** | Process Check | `ps aux \| grep '[c]rond\|[s]upervisord'` | 60s | 10s | 3 | 30s |
| **pgadmin** | HTTP Service | `wget http://localhost:80/misc/ping` | 30s | 10s | 3 | 60s |
| **grafana** | HTTP Service | `curl -f http://localhost:3000/api/health` | 30s | 10s | 3 | 60s |
| **prometheus** | HTTP Service | `wget http://localhost:80/-/healthy` | 30s | 10s | 3 | 45s |
| **cadvisor** | HTTP Service | `wget http://localhost:80/healthz` | 30s | 10s | 3 | 30s |
| **postgres-exporter** | HTTP Service | `wget http://localhost:9187/metrics` | 30s | 10s | 3 | 30s |
| **watchtower** | Process Check | `ps aux \| grep '[w]atchtower'` | 60s | 10s | 3 | 30s |

## 🏥 Health Status Colors

- 🟢 **healthy** - Service is functioning normally
- 🟡 **starting** - Service is in grace period (start_period)
- 🔴 **unhealthy** - Service has failed healthchecks multiple times
- ⚪ **none** - No healthcheck configured

## 🔍 Monitoring Commands

### Check All Service Health
```bash
# Overview with health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# More detailed view
docker compose ps
```

### Check Specific Service Health
```bash
# Get health status only
docker inspect <service-name> --format='{{.State.Health.Status}}'

# Get detailed health information
docker inspect <service-name> --format='{{json .State.Health}}' | jq '.'

# View health history/logs
docker inspect <service-name> --format='{{range .State.Health.Log}}{{.Start}}: {{.Output}}{{end}}'
```

### Real-time Health Monitoring
```bash
# Watch all service health changes
watch 'docker ps --format "table {{.Names}}\t{{.Status}}"'

# Monitor specific service
watch 'docker inspect postgres --format="Status: {{.State.Health.Status}} | Failures: {{.State.Health.FailingStreak}}"'
```

## 🔧 Service-Specific Health Details

### Database Services

#### PostgreSQL
- **Test**: Checks if PostgreSQL is ready to accept connections
- **Command**: `pg_isready -U admin -d default`
- **Purpose**: Ensures database is accessible and responsive

#### PostgreSQL Backup
- **Test**: HTTP endpoint on port 8080
- **Command**: `curl -f http://localhost:8080/`
- **Purpose**: Verifies backup service web interface is responding

#### PostgreSQL Exporter
- **Test**: Prometheus metrics endpoint
- **Command**: `wget http://localhost:9187/metrics`
- **Purpose**: Ensures metrics are being exported for Prometheus

### Monitoring Services

#### Prometheus
- **Test**: Built-in health endpoint
- **Command**: `wget http://localhost:80/-/healthy`
- **Purpose**: Verifies Prometheus server is running and healthy

#### Grafana
- **Test**: Built-in API health endpoint
- **Command**: `curl -f http://localhost:3000/api/health`
- **Purpose**: Checks if Grafana web interface and API are responsive

#### cAdvisor
- **Test**: Built-in health endpoint
- **Command**: `wget http://localhost:80/healthz`
- **Purpose**: Verifies container monitoring is functional

### Administration Services

#### pgAdmin
- **Test**: Built-in ping endpoint
- **Command**: `wget http://localhost:80/misc/ping`
- **Purpose**: Ensures web interface is accessible

### Utility Services

#### Watchtower
- **Test**: Process existence check
- **Command**: `ps aux | grep '[w]atchtower'`
- **Purpose**: Verifies the watchtower process is running

#### Volume Backup
- **Test**: Process existence check  
- **Command**: `ps aux | grep '[c]rond|[s]upervisord'`
- **Purpose**: Ensures backup scheduler processes are active

## 🚨 Troubleshooting Unhealthy Services

### Common Issues and Solutions

#### HTTP Service Not Responding
```bash
# Check if service is listening on the expected port
docker exec <service-name> netstat -tlnp

# Test the health endpoint manually
docker exec <service-name> curl -f http://localhost:<port>/health

# Check service logs
docker logs <service-name> --tail 50
```

#### Process Check Failures
```bash
# List all processes in container
docker exec <service-name> ps aux

# Check if expected process is running
docker exec <service-name> pgrep -f <process-name>

# Restart the service
docker compose restart <service-name>
```

#### Database Connection Issues
```bash
# Test PostgreSQL connection manually
docker exec postgres pg_isready -U admin -d default

# Check PostgreSQL logs
docker logs postgres --tail 20

# Verify environment variables
docker exec postgres env | grep POSTGRES
```

## 📊 Health Check Integration

### Service Dependencies
Services configured with `depends_on` will wait for their dependencies to be healthy:

- **pgladmin** waits for **postgres** to be healthy
- **postgres-exporter** waits for **postgres** to be healthy
- **postgres-backup** waits for **postgres** to be healthy

### Automated Monitoring Script
```bash
#!/bin/bash
# health-monitor.sh - Check all service health

services=("postgres" "postgres-backup" "volume-backup" "pgladmin" "grafana" "prometheus" "cadvisor" "postgres-exporter" "watchtower")
unhealthy=()

echo "🏥 HomeLab Health Check Report - $(date)"
echo "============================================"

for service in "${services[@]}"; do
    status=$(docker inspect "$service" --format='{{.State.Health.Status}}' 2>/dev/null)
    case $status in
        "healthy")
            echo "🟢 $service: healthy"
            ;;
        "unhealthy")
            echo "🔴 $service: unhealthy"
            unhealthy+=("$service")
            ;;
        "starting")
            echo "🟡 $service: starting"
            ;;
        *)
            echo "⚪ $service: no healthcheck or not running"
            ;;
    esac
done

if [ ${#unhealthy[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  UNHEALTHY SERVICES DETECTED: ${unhealthy[*]}"
    echo "Run 'docker logs <service-name>' to investigate"
    exit 1
else
    echo ""
    echo "✅ All services are healthy!"
    exit 0
fi
```

## 🔗 Related Documentation

- **[POSTGRES-RESTORE.md](POSTGRES-RESTORE.md)** - Database restoration procedures
- **[BACKUP-VERIFICATION.md](BACKUP-VERIFICATION.md)** - Backup service verification
- **[TESTING.md](TESTING.md)** - Network connectivity testing

---

💡 **Tip**: Use `docker compose ps` for a quick overview of all service health status, or the monitoring script above for detailed reporting.
