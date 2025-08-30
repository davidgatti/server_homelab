# Homelab Compose

This 

## 🎯 Current Status

**Current Status**: Complete monitoring and alerting infrastructure (13 services)  
**Configuration**: Environment-free single-file deployment with automatic network switching  
**Networks**: Auto-detects research (192.168.5.x) or lab (192.168.3.x) environments  
**Services**: PostgreSQL + Redis + Prometheus stack + AlertManager + Blackbox monitoring + automated backups  
**Last Major Update**: August 28, 2025 - Added Redis with full monitoring integration  
**Documentation**: See `.knowledge/` for architecture guides and `TODO.md` for expansion roadmap  

## Overview

This project replaces the old approach of:
- Manual `docker create` commands
- Individual `systemd` service files
- Scattered configuration files
- Manual network setup

With a unified Docker Compose solution that is:
- **Automated**: Single command deployment with health monitoring and network detection
- **Stable**: Comprehensive health checks and restart policies
- **Resilient**: Persistent volumes, proper networking, and foundation-first dependencies
- **Maintainable**: Environment-free configuration with resource optimization
- **Portable**: Auto-detects network environment (research/lab) with consistent DNS mapping

## Quick Start

### Fresh System Setup (One-time)

**Before running compose for the first time, you need:**

1. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com | sudo bash
   ```

2. **Add your user to docker group**:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in, or run: newgrp docker
   ```

3. **Ensure you're using regular Docker** (not rootless):
   ```bash
   docker context use default
   ```

4. **Network interface auto-detection**:
   - The script automatically detects your default network interface
   - To override, set `NETWORK_INTERFACE=your_interface` in `.env`
   - Check your interface with: `ip route | grep default`

### Project Setup

1. **Clone and setup**:
   ```bash
   git clone <your-repo>
   cd HomeLab
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

2. **Start services**:
   ```bash
   ./homelab.sh start
   ```

3. **Check status**:
   ```bash
   ./homelab.sh status
   ```

## Management Commands

The `homelab.sh` script provides easy management:

```bash
./homelab.sh start      # Start all services
./homelab.sh stop       # Stop all services
./homelab.sh restart    # Restart all services
./homelab.sh status     # Show service status
./homelab.sh logs       # Show all logs
./homelab.sh logs postgres  # Show specific service logs
./homelab.sh backup     # Backup all data
```

## Configuration

All configuration is handled through environment variables in `.env`:

- **Network Settings**: Subnet, gateway, and IP assignments
- **Service Configuration**: Passwords, users, databases
- **Resource Limits**: Memory and CPU constraints
- **Backup Settings**: Retention and storage paths

## Services

### Current Stack (13 Services)

#### **Core Infrastructure**
- **PostgreSQL** (192.168.3.53:5432) - Primary database with automated backups
- **Redis** (192.168.3.63:6379) - High-performance in-memory data store and cache
- **Watchtower** (192.168.3.57) - Automated container updates

#### **Monitoring & Alerting Stack**
- **Prometheus** (192.168.3.59:80) - Metrics collection and alerting engine
- **Grafana** (192.168.3.60:80) - Monitoring dashboards and visualization
- **AlertManager** (192.168.3.61:80) - Alert routing and notification management
- **Blackbox Exporter** (192.168.3.65:80) - External service monitoring and uptime checks

#### **Metrics Exporters**
- **cAdvisor** (192.168.3.62:80) - Container resource metrics
- **postgres-exporter** (192.168.3.64:9187) - PostgreSQL database metrics
- **redis-exporter** (192.168.3.65:9121) - Redis database metrics

#### **Administration & Backup**
- **pgAdmin** (192.168.3.58:80) - PostgreSQL web administration interface
- **postgres-backup** (192.168.3.55:8080) - Automated PostgreSQL backup service
- **volume-backup** (192.168.3.56) - Docker volume backup automation

### Service Features
- **Health Monitoring**: All services include comprehensive health checks
- **Resource Optimization**: CPU/memory limits optimized for Celeron N3350 (5.6GB RAM)
- **Security**: Non-root containers, SCRAM-SHA-256 authentication
- **Persistence**: Named volumes for all data with automated backup strategies
- **Network Access**: Direct LAN IPs via MacVLAN - no port conflicts

### PostgreSQL
## Network Architecture

- **MacVLAN Network**: `homelab` (auto-detected subnet)
- **Dynamic Detection**: Supports 192.168.5.x (research) and 192.168.3.x (lab) networks
- **Direct LAN Access**: Each service gets a unique IP on your home network
- **No Port Conflicts**: Services use their native ports (e.g., Grafana on port 80)
- **Router Integration**: Containers appear as separate devices to your router
- **DNS Resolution**: Services accessible by IP from any device on your network

### Current Service IPs (192.168.3.x subnet):
- **PostgreSQL**: .53:5432 - **Redis**: .63:6379 - **Prometheus**: .59:80 - **Grafana**: .60:80
- **AlertManager**: .61:80 - **pgAdmin**: .58:80 - **cAdvisor**: .62:80
- **postgres-exporter**: .64:9187 - **redis-exporter**: .65:9121 - **Blackbox**: .65:80 - **Watchtower**: .57
- **postgres-backup**: .55:8080 - **volume-backup**: .56

## Migration from Old Setup

### Before (Manual Commands):
```bash
# Create network
docker network create -d macvlan --subnet=192.168.3.0/24 --gateway=192.168.3.1 -o parent=enp1s0 homelab

# Create volume
docker volume create postgres-data

# Create container
docker create --name postgres --network=homelab --ip=192.168.3.12 ...

# Create systemd service
sudo tee /etc/systemd/system/postgres.service > /dev/null <<'EOF'
[Unit]
Description=PostgreSQL Docker Container
...
EOF
```

### Now (Docker Compose):
```bash
./homelab.sh start
```

## Adding New Services

1. **Add to `compose.yaml`**:
   ```yaml
   services:
     postgres:
       # existing config...
     
     redis:
       image: redis:latest
       container_name: redis
       restart: unless-stopped
       networks:
         homelab:
           ipv4_address: 192.168.10.13
       volumes:
         - redis-data:/data
   
   volumes:
     redis-data:
   ```

2. **Update `.env`** with new service variables

3. **Test incrementally**:
   ```bash
   ./homelab.sh restart
   ./homelab.sh status
   ```

## Benefits Over Old Approach

| Old Approach | New Approach |
|-------------|-------------|
| Manual docker commands | Declarative compose file |
| Individual systemd services | Single compose management |
| Scattered configuration | Centralized environment variables |
| Manual network setup | Automatic network management |
| No health monitoring | Built-in health checks |
| Manual backup scripts | Integrated backup commands |
| Hard to reproduce | Version controlled and portable |

## Troubleshooting

### Docker Setup Issues

- **"Permission denied" when creating network**:
  ```bash
  # Check if user is in docker group
  groups $USER | grep docker
  # If not in group, run: sudo usermod -aG docker $USER
  # Then logout/login or run: newgrp docker
  ```

- **"Cannot connect to Docker daemon"**:
  ```bash
  # Check if Docker daemon is running
  sudo systemctl status docker
  # Start if needed: sudo systemctl start docker
  ```

- **"Invalid subinterface vlan name"**:
  ```bash
  # Check your network interface name
  ip route | grep default
  # Use the correct interface in the macvlan command (e.g., eth0, eno1, enp1s0)
  ```

- **VS Code Docker extension not showing containers**:
  ```bash
  # Ensure you're using regular Docker (not rootless)
  docker context use default
  docker context list  # Should show "default" as current
  ```

### Service Issues

- **Check logs**: `./homelab.sh logs [service]`
- **Verify network**: `docker network inspect homelab`
- **Check health**: `docker compose ps`
- **Reset everything**: `./homelab.sh stop && docker system prune -f && ./homelab.sh start`

## 📊 Monitoring & Maintenance

### Resource Monitoring
```bash
# Weekly system health check
./scripts/homelab-resource-monitor.sh

# Network detection and current environment
./homelab.sh network

# Real-time container stats
docker stats

# Service health overview
docker compose ps
```

### Change Tracking
- **Logbook**: `.knowledge/logbook/` contains timestamped records of all major infrastructure changes
- **Documentation**: `.knowledge/instructions/` contains comprehensive guides and architecture details
- **Expansion Planning**: `TODO.md` contains categorized roadmap for future service additions
- **Latest Changes**: Check logbook entries for recent optimizations and system updates

## Security Considerations

- Environment-free configuration eliminates .env security risks
- Strong passwords configured directly in compose.yaml
- Resource limits prevent DoS scenarios
- Regular backups stored at `/opt/homelab/backups/postgres/`
- Health monitoring enables rapid issue detection

## 🔄 Infrastructure Management

### For AI Agents
- **Required Reading**: `.knowledge/instructions/AGENTS.md` and `.knowledge/logbook/README.md`
- **Before Changes**: Check latest logbook entries and run status monitoring
- **After Changes**: Create timestamped logbook entry documenting modifications
- **Architecture Guide**: `.knowledge/instructions/ARCHITECTURE.md` for system understanding

### For Manual Administration
- **Configuration**: Single file `compose.yaml` (no external dependencies)
- **Monitoring**: Foundation-first dependency strategy ensures monitoring always available
- **Resource Management**: Optimized for Intel Celeron systems with 5.6GB RAM

## Future Enhancements

- [ ] Add more services (Redis, MongoDB, etc.)
- [ ] Implement automated backups with retention
- [x] Add monitoring with Prometheus/Grafana ✅
- [ ] SSL/TLS termination with Traefik
- [ ] Secret management with Docker secrets
- [ ] CI/CD integration for updates
- [ ] Add Alertmanager for notifications
- [ ] Implement log aggregation with ELK stack