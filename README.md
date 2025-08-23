# Homelab Compose — Fresh-Server Test Harness

A modern, maintainable approach to home lab infrastructure using Docker Compose.

## Overview

This project replaces the old approach of:
- Manual `docker create` commands
- Individual `systemd` service files
- Scattered configuration files
- Manual network setup

With a unified Docker Compose solution that is:
- **Automated**: Single command deployment
- **Stable**: Health checks and restart policies
- **Resilient**: Persistent volumes and proper networking
- **Maintainable**: Environment-based configuration
- **Portable**: Works across different systems

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

### PostgreSQL
- **IP**: 192.168.3.52 (configurable)
- **Port**: 5432
- **Health Checks**: Automatic monitoring
- **Persistence**: Named volume for data
- **Security**: Non-root user, SCRAM-SHA-256 auth

### Grafana
- **IP**: 192.168.3.60 (configurable)
- **Port**: 80
- **Features**: Monitoring dashboard, Prometheus integration
- **Access**: http://192.168.3.60

### Prometheus
- **IP**: 192.168.3.59 (configurable) 
- **Port**: 80
- **Features**: Metrics collection, service discovery
- **Access**: http://192.168.3.59

### PgAdmin
- **IP**: 192.168.3.58 (configurable)
- **Port**: 80
- **Features**: PostgreSQL administration interface
- **Access**: http://192.168.3.58

## Network Architecture

- **Macvlan Network**: `homelab` (192.168.3.0/24)
- **Direct LAN Access**: Each service gets a unique IP on your home network
- **No Port Conflicts**: Services use their native ports (e.g., Grafana on port 80)
- **Router Integration**: Containers appear as separate devices to your router
- **DNS Resolution**: Services accessible by IP from any device on your network

### Service IPs (configurable in .env):
- **PostgreSQL**: 192.168.3.52
- **Grafana**: 192.168.3.60 
- **Prometheus**: 192.168.3.59
- **PgAdmin**: 192.168.3.58
- **Watchtower**: 192.168.3.57

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

## Security Considerations

- Change default passwords in `.env`
- Use strong passwords for production
- Consider firewall rules for exposed ports
- Regular backups with `./homelab.sh backup`
- Keep images updated

## Future Enhancements

- [ ] Add more services (Redis, MongoDB, etc.)
- [ ] Implement automated backups with retention
- [x] Add monitoring with Prometheus/Grafana ✅
- [ ] SSL/TLS termination with Traefik
- [ ] Secret management with Docker secrets
- [ ] CI/CD integration for updates
- [ ] Add Alertmanager for notifications
- [ ] Implement log aggregation with ELK stack