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
- **IP**: 192.168.10.12 (configurable)
- **Port**: 5432
- **Health Checks**: Automatic monitoring
- **Persistence**: Named volume for data
- **Security**: Non-root user, SCRAM-SHA-256 auth

## Network Architecture

- **Custom Bridge Network**: `homelab` (192.168.10.0/24)
- **Static IP Assignment**: Each service gets a predictable IP
- **DNS Resolution**: Services can communicate by name
- **Port Exposure**: External access when needed

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

- **Check logs**: `./homelab.sh logs [service]`
- **Verify network**: `docker network inspect homelab_homelab`
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
- [ ] Add monitoring with Prometheus/Grafana
- [ ] SSL/TLS termination with Traefik
- [ ] Secret management with Docker secrets
- [ ] CI/CD integration for updates