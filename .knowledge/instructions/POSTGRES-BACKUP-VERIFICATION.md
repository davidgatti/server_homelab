# PostgreSQL Backup Service - Verification Guide

## Overview

The `postgres-backup` service automatically creates compressed SQL dumps of PostgreSQL databases on a scheduled basis. This guide explains how to verify that the PostgreSQL backup service is functioning correctly and troubleshoot common issues.

## Service Configuration

### Container Details
- **Image**: `prodrigestivill/postgres-backup-local`
- **Container Name**: `postgres-backup`
- **Network**: MacVLAN (IP: `${POSTGRES_BACKUP_IP}`)
- **Schedule**: Configured via `POSTGRES_BACKUP_SCHEDULE` environment variable
- **Health Check Port**: 8080

### Backup Configuration
- **Schedule**: `0 2 * * *` (Daily at 2:00 AM)
- **Database**: `${POSTGRES_DB}` (default: `default`)
- **Compression**: gzip (`.sql.gz` files)
- **Backup Options**: `${POSTGRES_BACKUP_OPTS}` (default: `-Z6 --schema-only --blobs`)
- **Storage Location**: `/backups` volume (mapped to `postgres-backups` Docker volume)

### Retention Policy
- **Daily**: Keep for `${BACKUP_RETENTION_DAYS}` days (default: 30)
- **Weekly**: Keep for `${POSTGRES_BACKUP_KEEP_WEEKS}` weeks (default: 4)
- **Monthly**: Keep for `${POSTGRES_BACKUP_KEEP_MONTHS}` months (default: 6)

### Backup Structure
```
/backups/
├── daily/          # Daily backups
├── weekly/         # Weekly backups  
├── monthly/        # Monthly backups
└── last/           # Latest backups
```

## Verification Procedures

### 1. Check Service Status

#### Verify Container is Running
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep postgres-backup
```
**Expected Output:**
```
postgres-backup     Up X minutes (healthy)   prodrigestivill/postgres-backup-local
```

#### Check Container Health
```bash
docker inspect postgres-backup --format='{{.State.Health.Status}}'
```
**Expected Output:** `healthy`

#### Test Health Check Endpoint
Using MacVLAN test container:
```bash
docker run --rm --network homelab --ip 192.168.3.104 alpine:latest sh -c "
  apk add --no-cache curl > /dev/null 2>&1
  curl -f http://192.168.3.55:8080/ && echo 'Health check OK' || echo 'Health check failed'
"
```

### 2. Verify Backup Schedule

#### Check Configured Schedule
```bash
grep POSTGRES_BACKUP_SCHEDULE .env
```
**Expected Output:** `POSTGRES_BACKUP_SCHEDULE=0 2 * * *`

#### Verify Schedule is Active
```bash
docker logs postgres-backup --tail 5
```
**Expected Output Should Include:**
```
new cron: 0 2 * * *
Opening port 8080 for health checking
```

### 3. Check Backup Files

#### List Backup Directory Structure
```bash
docker exec postgres-backup ls -la /backups/
```
**Expected Output:**
```
drwxr-xr-x 2 root root 4096 Aug 24 02:00 daily
drwxr-xr-x 2 root root 4096 Aug 24 02:00 last
drwxr-xr-x 2 root root 4096 Aug 24 02:00 monthly
drwxr-xr-x 2 root root 4096 Aug 24 02:00 weekly
```

#### Check Daily Backups
```bash
docker exec postgres-backup ls -la /backups/daily/
```
**Expected Output Example:**
```
-rw-r--r-- 1 root root 1633 Aug 23 02:00 default-20250823.sql.gz
-rw-r--r-- 4 root root 1633 Aug 24 02:00 default-20250824.sql.gz
lrwxrwxrwx 1 root root   23 Aug 24 02:00 default-latest.sql.gz -> default-20250824.sql.gz
```

#### Check Latest Backup Exists
```bash
docker exec postgres-backup ls -la /backups/daily/default-latest.sql.gz
```

#### Verify Today's Backup
```bash
TODAY=$(date +%Y%m%d)
docker exec postgres-backup ls -la /backups/daily/default-${TODAY}.sql.gz 2>/dev/null && echo "✅ Today's backup exists" || echo "❌ Today's backup missing"
```

### 4. Verify Backup Contents

#### Check Backup File Size
```bash
docker exec postgres-backup du -h /backups/daily/default-latest.sql.gz
```
**Expected:** Should be > 0 bytes (typically 1-10KB for schema-only backups)

#### Verify Backup Integrity
```bash
docker exec postgres-backup sh -c "
  gzip -t /backups/daily/default-latest.sql.gz && echo '✅ Backup file is valid' || echo '❌ Backup file is corrupted'
"
```

#### Preview Backup Content
```bash
docker exec postgres-backup sh -c "
  zcat /backups/daily/default-latest.sql.gz | head -20
"
```
**Expected Content Should Include:**
- SQL comments with backup metadata
- PostgreSQL version information
- Database schema definitions
- Table structures (if schema-only)

#### Check for PostgreSQL Standard Headers
```bash
docker exec postgres-backup sh -c "
  zcat /backups/daily/default-latest.sql.gz | grep -E '(PostgreSQL database dump|pg_dump version)' | head -2
"
```

### 5. Test Database Connection

#### Verify PostgreSQL Connectivity
```bash
docker exec postgres-backup sh -c "
  pg_isready -h postgres -p 5432 -U ${POSTGRES_USER} && echo '✅ Database connection OK' || echo '❌ Database connection failed'
"
```

#### Test Database Access
```bash
docker exec postgres-backup sh -c "
  PGPASSWORD=${POSTGRES_PASSWORD} psql -h postgres -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c 'SELECT version();' | head -1
"
```

### 6. Check Backup Logs

#### View Recent Backup Activity
```bash
docker logs postgres-backup --since 24h
```

#### Check for Errors
```bash
docker logs postgres-backup --since 48h | grep -i error
```
**Expected:** No error messages

#### Monitor Real-time Logs
```bash
docker logs postgres-backup -f
```

### 7. Verify Retention Policy

#### Count Daily Backups
```bash
docker exec postgres-backup sh -c "
  ls -1 /backups/daily/*.sql.gz | grep -v latest | wc -l
"
```
**Expected:** Should not exceed retention days + a few extra

#### Check Weekly Backups
```bash
docker exec postgres-backup ls -la /backups/weekly/
```

#### Check Monthly Backups
```bash
docker exec postgres-backup ls -la /backups/monthly/
```

### 8. Manual Backup Test

#### Trigger Manual Backup (Optional)
```bash
docker exec postgres-backup sh -c "
  cd /backups && 
  PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -h postgres -U ${POSTGRES_USER} -d ${POSTGRES_DB} ${POSTGRES_BACKUP_OPTS} | gzip > manual-test-$(date +%Y%m%d-%H%M%S).sql.gz &&
  echo 'Manual backup completed'
"
```

#### Verify Manual Backup
```bash
docker exec postgres-backup ls -la /backups/manual-test-*.sql.gz
```

## Automated Verification Script

Create this script for regular health checks:

```bash
#!/bin/bash
# postgres-backup-health-check.sh

echo "🔍 PostgreSQL Backup Health Check"
echo "=================================="

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^postgres-backup$"; then
    echo "✅ Container is running"
else
    echo "❌ Container is not running"
    exit 1
fi

# Check container health
HEALTH=$(docker inspect postgres-backup --format='{{.State.Health.Status}}' 2>/dev/null)
if [ "$HEALTH" = "healthy" ]; then
    echo "✅ Container health check: $HEALTH"
elif [ "$HEALTH" = "unhealthy" ]; then
    echo "❌ Container health check: $HEALTH"
    echo "ℹ️  Check health check logs with: docker inspect postgres-backup --format='{{.State.Health}}'"
else
    echo "⚠️  Container health check: $HEALTH (starting up or no health check)"
fi

# Check if today's backup exists
TODAY=$(date +%Y%m%d)
if docker exec postgres-backup ls /backups/daily/default-${TODAY}.sql.gz > /dev/null 2>&1; then
    echo "✅ Today's backup exists"
    SIZE=$(docker exec postgres-backup du -h /backups/daily/default-${TODAY}.sql.gz | cut -f1)
    echo "📁 Backup size: $SIZE"
    
    # Verify backup integrity
    if docker exec postgres-backup gzip -t /backups/daily/default-${TODAY}.sql.gz > /dev/null 2>&1; then
        echo "✅ Backup file is valid"
    else
        echo "❌ Backup file is corrupted"
        exit 1
    fi
else
    echo "❌ Today's backup is missing"
    echo "ℹ️  This is normal if it's before 2:00 AM"
fi

# Test database connectivity
if docker exec postgres-backup pg_isready -h postgres -p 5432 -U "${POSTGRES_USER}" > /dev/null 2>&1; then
    echo "✅ Database connectivity OK"
else
    echo "❌ Cannot connect to PostgreSQL database"
    exit 1
fi

# Check recent logs for errors
ERROR_COUNT=$(docker logs postgres-backup --since 24h 2>&1 | grep -i error | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ No recent errors in logs"
else
    echo "⚠️  Found $ERROR_COUNT error(s) in recent logs"
    docker logs postgres-backup --since 24h | grep -i error
fi

# Check backup counts
DAILY_COUNT=$(docker exec postgres-backup sh -c "ls -1 /backups/daily/*.sql.gz 2>/dev/null | grep -v latest | wc -l")
echo "📊 Daily backups: $DAILY_COUNT"

WEEKLY_COUNT=$(docker exec postgres-backup sh -c "ls -1 /backups/weekly/*.sql.gz 2>/dev/null | wc -l")
echo "📊 Weekly backups: $WEEKLY_COUNT"

MONTHLY_COUNT=$(docker exec postgres-backup sh -c "ls -1 /backups/monthly/*.sql.gz 2>/dev/null | wc -l")
echo "📊 Monthly backups: $MONTHLY_COUNT"

# Check if retention is working (shouldn't have too many daily backups)
if [ "$DAILY_COUNT" -gt 35 ]; then
    echo "⚠️  Too many daily backups found - check retention policy"
fi

echo "✅ Health check completed"
```

Make it executable and run:
```bash
chmod +x postgres-backup-health-check.sh
./postgres-backup-health-check.sh
```

## Troubleshooting

### Common Issues

#### Container Unhealthy
1. **Check health endpoint**: `curl http://192.168.3.55:8080/` (from MacVLAN container)
2. **Verify port configuration**: Check `HEALTHCHECK_PORT=8080` in compose.yaml
3. **Check container logs**: `docker logs postgres-backup`
4. **Restart service**: `docker-compose restart postgres-backup`

#### No Backup Files Created
1. **Check database connectivity**: `docker exec postgres-backup pg_isready -h postgres`
2. **Verify credentials**: Check `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` variables
3. **Check schedule**: `docker logs postgres-backup | grep cron`
4. **Verify permissions**: `docker exec postgres-backup ls -la /backups`

#### Backup Files Too Small or Empty
1. **Check backup options**: Verify `POSTGRES_BACKUP_OPTS` settings
2. **Test manual backup**: Run manual pg_dump command
3. **Check database content**: Verify PostgreSQL has data to backup
4. **Review dump options**: Consider removing `--schema-only` if you need data

#### Database Connection Issues
1. **Check PostgreSQL health**: `docker ps | grep postgres`
2. **Verify network connectivity**: Both containers on same network
3. **Check credentials**: Ensure environment variables match
4. **Test from backup container**: `docker exec postgres-backup ping postgres`

#### Permission Denied Errors
1. **Check volume mounts**: Verify `/backups` volume is mounted correctly
2. **Check PostgreSQL permissions**: Ensure user has dump privileges
3. **Verify container user**: Check if running as correct user

### Log Analysis

#### Successful Backup Log Pattern
```
new cron: 0 2 * * *
Opening port 8080 for health checking
```

#### Backup Execution Logs
Look for patterns indicating backup start/completion times.

#### Error Indicators
- `connection refused`
- `permission denied`
- `authentication failed`
- `pg_dump: error:`
- `could not connect`

## Recovery Procedures

### Restore from Backup

#### List Available Backups
```bash
docker exec postgres-backup ls -la /backups/daily/
```

#### Restore Latest Backup
```bash
# Stop applications using the database
docker-compose stop pgadmin

# Restore from latest backup
docker exec postgres-backup sh -c "
  PGPASSWORD=${POSTGRES_PASSWORD} zcat /backups/daily/default-latest.sql.gz | 
  psql -h postgres -U ${POSTGRES_USER} -d ${POSTGRES_DB}
"

# Restart applications
docker-compose start pgadmin
```

#### Restore Specific Backup
```bash
# Replace YYYYMMDD with desired date
docker exec postgres-backup sh -c "
  PGPASSWORD=${POSTGRES_PASSWORD} zcat /backups/daily/default-YYYYMMDD.sql.gz | 
  psql -h postgres -U ${POSTGRES_USER} -d ${POSTGRES_DB}
"
```

### Point-in-Time Recovery
For more sophisticated recovery, consider:
1. **PostgreSQL WAL archiving**: Enable continuous archiving
2. **Base backups**: Combine with transaction log shipping
3. **Replica setup**: Streaming replication for high availability

## Monitoring Integration

### Health Check Integration
The service provides a health endpoint on port 8080:
```bash
# From MacVLAN container
curl http://192.168.3.55:8080/
```

### Prometheus Metrics (Future Enhancement)
Consider adding metrics for:
- Backup success/failure rates
- Backup file sizes over time
- Backup duration metrics
- Database connectivity status

### Alerting Recommendations
Set up alerts for:
- Failed backups (missing daily files after 3:00 AM)
- Container health check failures
- Database connectivity issues
- Backup file corruption
- Retention policy violations

## Maintenance

### Regular Tasks
1. **Daily**: Check backup files exist and health status
2. **Weekly**: Run health check script and verify backup integrity
3. **Monthly**: Test backup restoration process
4. **Quarterly**: Review retention policies and storage usage

### Backup Optimization

#### Adjust Backup Options
```bash
# For data-only backups
POSTGRES_BACKUP_OPTS=--data-only

# For complete backups (schema + data)
POSTGRES_BACKUP_OPTS=--clean --if-exists

# For specific tables
POSTGRES_BACKUP_OPTS=--table=specific_table
```

#### Storage Management
```bash
# Check backup storage usage
docker exec postgres-backup du -sh /backups/*

# Manual cleanup (if needed)
docker exec postgres-backup find /backups/daily -name "*.sql.gz" -mtime +30 -delete
```

## Security Considerations

### Database Credentials
- Store credentials in environment variables
- Use Docker secrets for production
- Rotate passwords regularly
- Limit database user privileges to minimum required

### Backup File Security
- Consider encrypting backup files
- Secure backup storage location
- Implement access controls
- Regular security audits

### Network Security
- Use MacVLAN isolation
- Limit health check port exposure
- Monitor network traffic

---

## Quick Reference

### Daily Verification (30 seconds)
```bash
# Check if today's backup exists and container is healthy
TODAY=$(date +%Y%m%d)
docker exec postgres-backup ls /backups/daily/default-${TODAY}.sql.gz && docker ps | grep postgres-backup
```

### Weekly Deep Check (2 minutes)
```bash
# Run the health check script
./postgres-backup-health-check.sh
```

### Emergency Commands
- **Check backup files**: `docker exec postgres-backup ls -la /backups/daily/`
- **Test database connection**: `docker exec postgres-backup pg_isready -h postgres`
- **View recent logs**: `docker logs postgres-backup --tail 20`
- **Restart service**: `docker-compose restart postgres-backup`
- **Manual backup**: `docker exec postgres-backup pg_dump ...`

### Environment Variables Reference
```bash
POSTGRES_BACKUP_SCHEDULE=0 2 * * *     # Cron schedule
POSTGRES_BACKUP_OPTS=-Z6 --schema-only  # pg_dump options
BACKUP_RETENTION_DAYS=30               # Daily retention
POSTGRES_BACKUP_KEEP_WEEKS=4           # Weekly retention  
POSTGRES_BACKUP_KEEP_MONTHS=6          # Monthly retention
```
