# HomeLab Documentation Index

## Overview
This directory contains comprehensive documentation for the HomeLab infrastructure services and testing procedures.

## Documentation Files

### Core Architecture & Strategy
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system architecture, security model, and service health monitoring
- **[DEPENDENCY-STRATEGY.md](DEPENDENCY-STRATEGY.md)** - Foundation-first dependency strategy and startup sequencing
- **[AGENTS.md](AGENTS.md)** - Development guidelines and required reading for AI agents

### Testing & Verification
- **[TESTING.md](TESTING.md)** - MacVLAN network testing strategies and procedures
- **[BACKUP-VERIFICATION.md](BACKUP-VERIFICATION.md)** - Docker volume backup service verification guide  
- **[POSTGRES-BACKUP-VERIFICATION.md](POSTGRES-BACKUP-VERIFICATION.md)** - PostgreSQL backup service verification guide
- **[POSTGRES-RESTORE.md](POSTGRES-RESTORE.md)** - PostgreSQL backup restoration guide

## Quick Reference

### Daily Health Checks
```bash
# Overall system status
./homelab.sh status

# Service health overview
docker compose ps --format 'table {{.Name}}\t{{.Status}}'

# Resource monitoring (weekly)
./scripts/homelab-resource-monitor.sh
```

### Service Information

#### Current Stack (12 Services)
| Service | IP | Port | Purpose | Health Check |
|---------|----|----|---------|--------------|
| `postgres` | 192.168.3.53 | 5432 | Primary database | pg_isready |
| `prometheus` | 192.168.3.59 | 80 | Metrics collection | /-/healthy |
| `grafana` | 192.168.3.60 | 80 | Monitoring dashboards | /api/health |
| `alertmanager` | 192.168.3.61 | 80 | Alert management | /-/healthy |
| `cadvisor` | 192.168.3.62 | 80 | Container metrics | /healthz |
| `postgres-exporter` | 192.168.3.64 | 9187 | PostgreSQL metrics | /metrics |
| `blackbox-exporter` | 192.168.3.65 | 80 | External monitoring | /metrics |
| `pgadmin` | 192.168.3.58 | 80 | Database administration | /misc/ping |
| `postgres-backup` | 192.168.3.55 | 8080 | PostgreSQL backups | HTTP endpoint |
| `volume-backup` | 192.168.3.56 | - | Volume backups | Process check |
| `watchtower` | 192.168.3.57 | - | Container updates | Process check |

### Backup Services
| Service | Schedule | Type | Health Check |
|---------|----------|------|--------------|
| `volume-backup` | 3:00 AM daily | Docker volumes | File existence |
| `postgres-backup` | 2:00 AM daily | PostgreSQL dumps | HTTP endpoint (port 8080) |

## Network Configuration
- **Subnet**: 192.168.3.0/24
- **Gateway**: 192.168.3.1  
- **Type**: MacVLAN (isolated from host)
- **Testing IPs**: 192.168.3.100-200 (available for test containers)

## Documentation Standards

### File Naming
- Use `UPPERCASE-WITH-HYPHENS.md` for documentation files
- Include service name in verification guides
- Use descriptive, searchable names

### Content Structure
1. **Overview** - Service purpose and configuration
2. **Verification Procedures** - Step-by-step checks
3. **Automated Scripts** - Ready-to-use health check scripts  
4. **Troubleshooting** - Common issues and solutions
5. **Quick Reference** - Emergency commands and daily checks

### MacVLAN Testing Pattern
All service connectivity testing should use the established pattern:
```bash
docker run --rm --network homelab --ip 192.168.3.XXX alpine:latest sh -c "
  apk add --no-cache curl > /dev/null 2>&1
  # Test commands here
"
```

## Maintenance Schedule

### Daily (Automated)
- Volume backups at 3:00 AM
- PostgreSQL backups at 2:00 AM  
- Container updates via Watchtower at 4:00 AM

### Weekly (Manual)
- Run health check scripts
- Review backup file sizes and integrity
- Check service logs for errors

### Monthly (Manual)  
- Test backup restoration procedures
- Review retention policies
- Update documentation as needed

## Emergency Procedures

### Quick Service Restart
```bash
# Restart specific service
docker-compose restart <service_name>

# Restart all services  
docker-compose restart

# Full system restart
docker-compose down && docker-compose up -d
```

### Backup Recovery
1. Locate backup files in respective documentation
2. Stop dependent services
3. Restore from backup using documented procedures
4. Restart services and verify functionality

### Health Check Failures
1. Check service logs: `docker logs <service_name>`
2. Verify network connectivity using MacVLAN tests  
3. Check resource usage: `docker stats`
4. Review configuration files for errors

---

*Last updated: August 24, 2025*
