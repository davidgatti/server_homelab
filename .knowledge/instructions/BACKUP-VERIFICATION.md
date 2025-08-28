# Docker Volume Backup Service - Verification Guide

## Overview

The `docker-volume-backup` service automatically backs up Docker volumes on a scheduled basis. This guide explains how to verify that the backup service is functioning correctly and troubleshoot common issues.

## Service Configuration

### Container Details
- **Image**: `offen/docker-volume-backup:latest`
- **Container Name**: `volume-backup`
- **Network**: MacVLAN (IP: `${VOLUME_BACKUP_IP}`)
- **Schedule**: Configured via `VOLUME_BACKUP_SCHEDULE` environment variable

### What Gets Backed Up
The service backs up the following volumes:
- `postgres-data` → `/backup/postgres-data` (read-only)
- `postgres-backups` → `/backup/postgres-backups` (read-only)

### Backup Configuration
- **Schedule**: `0 3 * * *` (Daily at 3:00 AM)
- **Filename Format**: `backup-YYYYMMDD-HHMMSS.tar.gz`
- **Retention**: 30 days (configurable via `BACKUP_RETENTION_DAYS`)
- **Storage Location**: `${BACKUP_DIR}/volumes` (default: `/opt/homelab/backups/volumes`)

## Verification Procedures

### 1. Check Service Status

#### Verify Container is Running
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep volume-backup
```
**Expected Output:**
```
volume-backup       Up X minutes               offen/docker-volume-backup:latest
```

#### Check Container Health
```bash
docker inspect volume-backup --format='{{.State.Status}}'
```
**Expected Output:** `running`

### 2. Verify Backup Schedule

#### Check Configured Schedule
```bash
grep VOLUME_BACKUP_SCHEDULE .env
```
**Expected Output:** `VOLUME_BACKUP_SCHEDULE=0 3 * * *`

#### Verify Schedule is Active
```bash
docker logs volume-backup --tail 5
```
**Expected Output Should Include:**
```
level=INFO msg="Successfully scheduled backup from environment with expression 0 3 * * *"
```

### 3. Check Backup Files

#### List Recent Backup Files
```bash
ls -lah /opt/homelab/backups/volumes/ | tail -5
```
**Expected Output Example:**
```
-rw-r--r-- 1 root root 6.5M Aug 23 03:00 backup-20250823-030000.tar.gz
-rw-r--r-- 1 root root 6.5M Aug 24 03:00 backup-20250824-030000.tar.gz
```

#### Check Today's Backup Exists
```bash
ls -la /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz 2>/dev/null && echo "✅ Today's backup exists" || echo "❌ Today's backup missing"
```

#### Verify Backup File Size
```bash
du -h /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz 2>/dev/null
```
**Expected:** Files should be several MB in size (typically 5-10MB for basic PostgreSQL data)

### 4. Verify Backup Contents

#### List Backup Contents
```bash
tar -tzf /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz | head -10
```
**Expected Contents:**
```
/backup
/backup/postgres-backups
/backup/postgres-backups/daily/
/backup/postgres-backups/monthly/
/backup/postgres-data/
```

#### Check for PostgreSQL Data
```bash
tar -tzf /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz | grep -E "(postgres-data|postgres-backups)" | head -5
```

#### Verify Backup Integrity
```bash
tar -tzf /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz > /dev/null 2>&1 && echo "✅ Backup file is valid" || echo "❌ Backup file is corrupted"
```

### 5. Check Backup Logs

#### View Recent Backup Activity
```bash
docker logs volume-backup --since 24h
```

#### Check for Errors
```bash
docker logs volume-backup --since 48h | grep -i error
```
**Expected:** No error messages

#### View Detailed Logs
```bash
docker logs volume-backup --tail 50
```

### 6. Test Backup Process (Manual Trigger)

#### Force Immediate Backup (Optional)
```bash
docker exec volume-backup /bin/sh -c "cd / && /entrypoint.sh"
```

#### Monitor Backup Process
```bash
docker logs volume-backup -f
```

### 7. Network Connectivity Test

#### Test from MacVLAN Container
```bash
docker run --rm --network homelab --ip 192.168.3.103 alpine:latest sh -c "
  echo 'Testing volume-backup connectivity...'
  apk add --no-cache curl > /dev/null 2>&1
  ping -c 3 ${VOLUME_BACKUP_IP} || echo 'Ping test complete'
  echo 'Network test completed'
"
```

## Automated Verification Script

Create this script for regular health checks:

```bash
#!/bin/bash
# backup-health-check.sh

echo "🔍 Docker Volume Backup Health Check"
echo "====================================="

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^volume-backup$"; then
    echo "✅ Container is running"
else
    echo "❌ Container is not running"
    exit 1
fi

# Check if today's backup exists
TODAY=$(date +%Y%m%d)
BACKUP_FILE="/opt/homelab/backups/volumes/backup-${TODAY}-030000.tar.gz"

if [ -f "$BACKUP_FILE" ]; then
    echo "✅ Today's backup exists"
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "📁 Backup size: $SIZE"
    
    # Verify backup integrity
    if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
        echo "✅ Backup file is valid"
    else
        echo "❌ Backup file is corrupted"
        exit 1
    fi
else
    echo "❌ Today's backup is missing"
    echo "ℹ️  This is normal if it's before 3:00 AM"
fi

# Check recent logs for errors
ERROR_COUNT=$(docker logs volume-backup --since 24h 2>&1 | grep -i error | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ No recent errors in logs"
else
    echo "⚠️  Found $ERROR_COUNT error(s) in recent logs"
    docker logs volume-backup --since 24h | grep -i error
fi

# Check backup retention
BACKUP_COUNT=$(ls -1 /opt/homelab/backups/volumes/backup-*.tar.gz 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

if [ "$BACKUP_COUNT" -gt 30 ]; then
    echo "⚠️  More than 30 backups found - check retention policy"
fi

echo "✅ Health check completed"
```

Make it executable and run:
```bash
chmod +x backup-health-check.sh
./backup-health-check.sh
```

## Troubleshooting

### Common Issues

#### Backup Files Not Created
1. **Check container status**: `docker ps | grep volume-backup`
2. **Verify schedule**: `docker logs volume-backup | grep scheduled`
3. **Check permissions**: Ensure `/opt/homelab/backups` is writable
4. **Verify volumes**: `docker inspect volume-backup | grep Mounts -A 10`

#### Backup Files Too Small
1. **Check source volumes**: `docker volume ls | grep postgres`
2. **Verify volume mounts**: Check compose.yaml configuration
3. **Check volume contents**: `docker exec volume-backup ls -la /backup/`

#### Container Keeps Restarting
1. **Check logs**: `docker logs volume-backup`
2. **Verify environment variables**: `docker inspect volume-backup | grep Env -A 20`
3. **Check disk space**: `df -h /opt/homelab/backups`

#### Permission Issues
1. **Check backup directory ownership**: `ls -la /opt/homelab/backups/`
2. **Fix permissions**: `sudo chown -R root:root /opt/homelab/backups`
3. **Verify Docker access**: `ls -la /var/run/docker.sock`

### Log Analysis

#### Successful Backup Log Pattern
```
level=INFO msg="Successfully scheduled backup from environment with expression 0 3 * * *"
level=INFO msg="Finished running backup tasks."
```

#### Error Indicators
- `level=ERROR`
- `failed to`
- `permission denied`
- `no space left`

## Monitoring Integration

### Prometheus Metrics (Future Enhancement)
The backup service can be monitored via:
- File modification time metrics
- Backup file size metrics
- Success/failure counters

### Alerting Recommendations
Set up alerts for:
- Missing daily backups (after 4:00 AM)
- Backup file size anomalies
- Container restart loops
- Disk space issues

## Maintenance

### Regular Tasks
1. **Weekly**: Run health check script
2. **Monthly**: Verify backup restoration process
3. **Quarterly**: Review retention policies
4. **Annually**: Test disaster recovery procedures

### Backup Rotation
The service automatically handles rotation based on `BACKUP_RETENTION_DAYS`.
Verify old files are removed:
```bash
find /opt/homelab/backups/volumes/ -name "backup-*.tar.gz" -mtime +30 -ls
```

## Recovery Procedures

### Restore from Backup
```bash
# Stop services
docker-compose down

# Extract backup
cd /
tar -xzf /opt/homelab/backups/volumes/backup-YYYYMMDD-HHMMSS.tar.gz

# Copy data to volume mount points
# (Specific steps depend on your volume configuration)

# Restart services
docker-compose up -d
```

### Emergency Procedures
1. **Immediate backup**: Use manual trigger command
2. **Copy to external storage**: `rsync -av /opt/homelab/backups/ external_backup_location/`
3. **Service recovery**: `docker-compose restart volume-backup`

---

## Quick Reference

### Daily Verification (30 seconds)
```bash
# Check if today's backup exists and container is running
ls -la /opt/homelab/backups/volumes/backup-$(date +%Y%m%d)-030000.tar.gz && docker ps | grep volume-backup
```

### Weekly Deep Check (2 minutes)
```bash
# Run the health check script
./backup-health-check.sh
```

### Emergency Contact
- Check container logs: `docker logs volume-backup`
- Check disk space: `df -h /opt/homelab/backups`
- Restart service: `docker-compose restart volume-backup`
