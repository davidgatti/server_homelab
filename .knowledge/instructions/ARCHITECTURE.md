# HomeLab Architecture & Implementation Guide

## Project Philosophy

This HomeLab project demonstrates **modern infrastructure best practices** using Docker Compose with a **security-first, automation-focused approach**. The core principle is achieving maximum functionality while maintaining proper security layers and minimal manual intervention.

### Key Principles

1. **Security Layered Architecture**: Docker daemon handles privileges, containers run as non-root
2. **Direct LAN Integration**: Each service gets unique IP via macvlan networking
3. **Zero Manual Configuration**: Automated detection and setup
4. **Declarative Infrastructure**: Everything defined in version-controlled files
5. **Production-Ready Monitoring**: Built-in observability stack

## Architecture Overview

### Network Architecture: macvlan Direct LAN Access

```
┌─────────────────────────────────────────────────────────┐
│                    Home Network                         │
│                   192.168.3.0/24                       │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────┴────────┐
              │    Router      │
              │  192.168.3.1   │
              └───────┬────────┘
                      │
              ┌───────┴────────┐
              │  Docker Host   │
              │  192.168.3.51  │  ← Server
              └───────┬────────┘
                      │
              ┌───────┴────────┐
              │ macvlan bridge │
              │   (homelab)    │
              └───────┬────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────┴───┐   ┌────┴───┐   ┌────┴───┐
   │Grafana │   │Postgres│   │Prometheus│
   │ .3.60  │   │ .3.53  │   │ .3.59  │
   │(port80)│   │(5432)  │   │(port80)│
   └────────┘   └────────┘   └────────┘
```

**Benefits:**
- No port conflicts - each service uses native ports
- Direct access from any network device (no port forwarding)
- Services appear as separate devices to router
- Clean URLs: http://grafana.home, http://prometheus.home

### Security Architecture: Layered Privilege Model

```
┌─────────────────────────────────────────────────────────┐
│                System Level (Root)                     │
│  ┌─────────────────────────────────────────────────┐    │
│  │           Docker Daemon                         │    │
│  │  • Creates macvlan interfaces                   │    │
│  │  • Manages privileged operations                │    │
│  │  • Handles network namespaces                   │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────┘
                      │ docker group membership
┌─────────────────────┴───────────────────────────────────┐
│              User Level (Non-Root)                     │
│  ┌─────────────────────────────────────────────────┐    │
│  │           Docker Client                         │    │
│  │  • Sends commands to daemon                     │    │
│  │  • Manages compose orchestration                │    │
│  │  • No direct system privileges                  │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────┘
                      │ container creation
┌─────────────────────┴───────────────────────────────────┐
│            Container Level (Application)               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐  │
│  │   PostgreSQL    │ │    Grafana      │ │   Apps    │  │
│  │ (postgres user) │ │  (root for :80) │ │(app users)│  │
│  │   uid=999       │ │    uid=0        │ │ uid=1000+ │  │
│  └─────────────────┘ └─────────────────┘ └───────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Security Benefits:**
- **Minimal Attack Surface**: Only necessary containers run as root
- **Principle of Least Privilege**: Each layer has minimal required permissions
- **Network Isolation**: Containers can't access host network stack
- **User Separation**: Application compromises don't affect host system

## Implementation Details

### Docker Context Management

The project uses **regular Docker** (not rootless) for macvlan capabilities:

```bash
# Ensure correct Docker context
docker context use default

# Verify regular daemon (not rootless)
docker version  # Should NOT show "rootlesskit"
```

### Network Creation Strategy

**Compose-Managed macvlan** (preferred approach):

```yaml
networks:
  homelab:
    name: homelab  # Override default "project_network" naming
    driver: macvlan
    driver_opts:
      parent: ${NETWORK_INTERFACE:-eno1}  # Auto-detected or manual
    ipam:
      config:
        - subnet: 192.168.3.0/24
          gateway: 192.168.3.1
```

**Benefits over manual creation:**
- Version controlled network configuration
- Automatic interface detection
- Portable across different systems
- Single command deployment

### Service Configuration Patterns

#### Standard Non-Root Service
```yaml
postgres:
  image: postgres:latest
  container_name: postgres
  # No user override - runs as postgres (uid=999)
  networks:
    homelab:
      ipv4_address: 192.168.3.53
  volumes:
    - postgres-data:/var/lib/postgresql/data
  environment:
    - POSTGRES_USER=${POSTGRES_USER}
  # Result: Secure, isolated, direct LAN access
```

#### Privileged Service (Only When Required)
```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  user: "0"  # Required for port 80 binding
  networks:
    homelab:
      ipv4_address: 192.168.3.60
  volumes:
    - ./configs/grafana/grafana.ini:/etc/grafana/grafana.ini:ro
  # Result: Root privileges only where absolutely necessary
```

### Configuration Management

**External Configuration Files** (recommended pattern):

```
configs/
├── grafana/
│   └── grafana.ini       # Custom Grafana config
├── prometheus/
│   └── prometheus.yml    # Service discovery config
└── nginx/
    └── nginx.conf        # Future reverse proxy
```

**Benefits:**
- Configuration changes without rebuilding images
- Version-controlled settings
- Environment-specific overrides
- Easy troubleshooting and debugging

### Monitoring Stack Implementation

**Prometheus Service Discovery**:
```yaml
# Auto-discovers Docker containers
docker_sd_configs:
  - host: unix:///var/run/docker.sock
    refresh_interval: 5s
    filters:
      - name: label
        values: ["prometheus.scrape=true"]
```

**Container Labeling Pattern**:
```yaml
labels:
  - "prometheus.scrape=true"      # Enable monitoring
  - "prometheus.port=8080"        # Service port
  - "prometheus.job=servicename"  # Job classification
  - "prometheus.path=/metrics"    # Metrics endpoint
```

## Automation & Tooling

### Auto-Detection Features

**Network Interface Detection**:
```bash
# Automatic detection
interface=$(ip route | grep default | awk '{print $5}' | head -1)
export NETWORK_INTERFACE="$interface"
```

**Environment Variable Pattern**:
```yaml
parent: ${NETWORK_INTERFACE:-eno1}  # Auto-detected with fallback
```

### Management Script (homelab.sh)

**Core Functions**:
- `check_dependencies()`: Verify Docker setup
- `detect_network_interface()`: Auto-detect or use .env
- `start()`, `stop()`, `restart()`: Service lifecycle
- `status()`: Health and network information
- `logs()`: Centralized log access
- `backup()`: Data protection

**Usage Pattern**:
```bash
./homelab.sh start    # Auto-detects everything, starts stack
./homelab.sh status   # Shows services, network, volumes
./homelab.sh logs prometheus  # Service-specific logs
```

## Extension Patterns

### Adding New Services

**Step 1: Define Service**
```yaml
redis:
  image: redis:latest
  container_name: redis
  restart: unless-stopped
  networks:
    homelab:
      ipv4_address: 192.168.3.XX  # Next available IP
  volumes:
    - redis-data:/data
  labels:
    - "prometheus.scrape=true"
    - "prometheus.port=6379"
    - "prometheus.job=redis"
```

**Step 2: Add Volume**
```yaml
volumes:
  redis-data:
    driver: local
```

**Step 3: Update Environment**
```bash
# .env
REDIS_IP=192.168.3.XX
REDIS_MEMORY_LIMIT=256M
```

### Configuration Patterns

**For services needing custom config:**
```yaml
# 1. Create config directory
configs/service-name/

# 2. Mount configuration
volumes:
  - ./configs/service-name/config.yml:/app/config.yml:ro

# 3. Version control settings
git add configs/service-name/
```

### Monitoring Integration

**For new services with metrics:**
```yaml
labels:
  - "prometheus.scrape=true"
  - "prometheus.port=PORT"
  - "prometheus.path=/metrics"  # or /health, /stats
  - "prometheus.job=service-name"
```

**For services without native metrics:**
```yaml
# Add exporter sidecar
service-exporter:
  image: appropriate/exporter:latest
  networks:
    homelab:
      ipv4_address: 192.168.3.YY
  labels:
    - "prometheus.scrape=true"
```

## Fresh System Deployment

### Prerequisites
1. **Docker Installation**: `curl -fsSL https://get.docker.com | sudo bash`
2. **User Permissions**: `sudo usermod -aG docker $USER` (then logout/login)
3. **Docker Context**: `docker context use default`

### Deployment Process
```bash
# 1. Clone and configure
git clone <repo>
cd HomeLab
cp .env.example .env  # Edit as needed

# 2. Start infrastructure
./homelab.sh start

# 3. Verify deployment
./homelab.sh status
```

**Result**: Fully functional homelab with monitoring, direct LAN access, and secure container isolation.

## Troubleshooting Guides

### Network Issues
```bash
# Interface detection
ip route | grep default

# Network verification
docker network inspect homelab

# Container connectivity
docker exec service-name ping 192.168.3.1
```

### Security Issues
```bash
# Check container users
docker exec service-name id

# Verify Docker context
docker context list

# Check daemon mode
docker version | grep -i rootless
```

### Monitoring Issues
```bash
# Prometheus targets
curl http://192.168.3.59/targets

# Service discovery
docker logs prometheus | grep discovery

# Container labels
docker inspect service-name | jq '.[0].Config.Labels'
```

## Future Extensions

### Planned Enhancements
- **SSL/TLS Termination**: Traefik reverse proxy with automatic certificates
- **Log Aggregation**: ELK stack for centralized logging  
- **Alerting**: Alertmanager integration with notifications
- **Backup Automation**: Automated offsite backup with retention
- **Secret Management**: Docker secrets or external vault integration

### Scaling Patterns
- **Multi-Host**: Docker Swarm mode for cluster deployment
- **Load Balancing**: HAProxy for high-availability services
- **Storage**: Distributed storage with GlusterFS or Ceph
- **CI/CD**: GitLab or Jenkins for automated deployments

## Agent Context Summary

**For AI Agents working on this project:**

1. **Core Architecture**: macvlan networking with layered security model
2. **Security Principle**: Minimal privileges - most containers run as non-root
3. **Network Pattern**: Direct LAN IPs (192.168.3.x) for each service
4. **Configuration Strategy**: External config files in `configs/` directory
5. **Automation Goal**: Zero manual configuration, auto-detection preferred
6. **Monitoring Approach**: Prometheus service discovery with container labels
7. **Management Tool**: `homelab.sh` script for all operations
8. **Extension Pattern**: Add services to compose.yaml with proper labeling
9. **Deployment Model**: Single command startup after initial Docker setup
10. **Troubleshooting**: Use `./homelab.sh status/logs` for diagnostics

**Key Files:**
- `compose.yaml`: Service definitions with macvlan networking
- `homelab.sh`: Management script with auto-detection
- `configs/*/`: Service-specific configuration files
- `.env`: Environment variables and overrides
- `README.md`: User documentation
- `ARCHITECTURE.md`: This comprehensive guide

This architecture enables secure, scalable, and maintainable homelab infrastructure with enterprise-grade monitoring and automation capabilities.
