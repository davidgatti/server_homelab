# HomeLab Documentation Index

## Overview
This directory contains comprehensive documentation for the HomeLab infrastructure services and testing procedures.

## Documentation Files

### Core Architecture
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Overall system architecture and design principles

### Testing & Verification
- **[TESTING.md](TESTING.md)** - MacVLAN network testing strategies and procedures
- **[BACKUP-VERIFICATION.md](BACKUP-VERIFICATION.md)** - Docker volume backup service verification guide  
- **[POSTGRES-BACKUP-VERIFICATION.md](POSTGRES-BACKUP-VERIFICATION.md)** - PostgreSQL backup service verification guide

## Quick Service Health Checks

### Volume Backup Service
```bash
# Quick daily check
ls -la /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz && docker ps | grep volume-backup
```

### PostgreSQL Backup Service  
```bash
# Quick daily check
TODAY=$(date +%Y%m%d)
docker exec postgres-backup ls /backups/daily/default-${TODAY}.sql.gz && docker ps | grep postgres-backup
```

### MacVLAN Network Connectivity Test
```bash
# Test any service (example: cAdvisor)
docker run --rm --network homelab --ip 192.168.3.100 alpine:latest sh -c "
  apk add --no-cache curl > /dev/null 2>&1
  curl -s http://192.168.3.62:80/metrics | head -5
"
```

## Service Information

### Backup Services
| Service | Schedule | Type | Health Check |
|---------|----------|------|--------------|
| `volume-backup` | 3:00 AM daily | Docker volumes | File existence |
| `postgres-backup` | 2:00 AM daily | PostgreSQL dumps | HTTP endpoint (port 8080) |

### Monitoring Services  
| Service | Port | IP | Purpose |
|---------|------|----|---------| 
| `prometheus` | 80 | 192.168.3.59 | Metrics collection |
| `grafana` | 80 | 192.168.3.60 | Metrics visualization |
| `cadvisor` | 80 | 192.168.3.62 | Container metrics |
| `postgres-exporter` | 9187 | 192.168.3.64 | PostgreSQL metrics |

### Database Services
| Service | Port | IP | Purpose |
|---------|------|----|---------| 
| `postgres` | 5432 | 192.168.3.53 | Main database |
| `pgadmin` | 80 | 192.168.3.58 | Database administration |

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
