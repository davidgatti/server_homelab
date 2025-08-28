# PostgreSQL Backup Restoration Guide

This guide covers the straightforward approach to restoring PostgreSQL data```bash
# 5. Restore from backup (provide password when prompted)
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | 
  docker exec -i postgres psql -h localhost -U admin -d default
```es from backups created by `prodrigestivill/postgres-backup-local`.

## 📋 Overview

The `postgres-backup-local` container creates compressed SQL dump files (`.sql.gz`) that can be easily restored using standard PostgreSQL commands. This guide focuses on the **manual restoration approach** - simple, predictable, and easy to understand.

## 🗂️ Backup File Structure

Your backups are stored on the host at `/opt/homelab/backups/postgres/`:

```
/opt/homelab/backups/postgres/
├── daily/
│   ├── default-20250823.sql.gz    # Daily backup from Aug 23
│   ├── default-20250824.sql.gz    # Daily backup from Aug 24
│   └── default-latest.sql.gz      # Symlink to latest daily backup
├── weekly/
│   ├── default-202534.sql.gz      # Weekly backup (week 34)
│   └── default-latest.sql.gz      # Symlink to latest weekly backup
├── monthly/
│   ├── default-202508.sql.gz      # Monthly backup (August 2025)
│   └── default-latest.sql.gz      # Symlink to latest monthly backup
└── last/
    ├── default-20250824-020000.sql.gz  # Last backup with timestamp
    └── default-latest.sql.gz           # Symlink to very latest backup
```

## 🚀 Quick Start - Basic Restoration

**Note**: The PostgreSQL password is configured in your `.env` file (`POSTGRES_PASSWORD=password`). You'll be prompted for this password when running the commands below.

### Step 1: List Available Backups
```bash
# List all backups with details
ls -lh /opt/homelab/backups/postgres/daily/

# Or use the helper script
./scripts/restore-postgres.sh list
```

### Step 2: Create New Database for Restoration
```bash
# Create a new database (always restore to new DB first for safety)
# Note: Use postgres database and provide password when prompted
docker exec -it postgres psql -h localhost -U admin -d postgres -c "CREATE DATABASE restored_db;"
```

### Step 3: Restore the Backup
```bash
# Restore backup to the new database (provide password when prompted)
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | \
  docker exec -i postgres psql -h localhost -U admin -d restored_db
```

### Step 4: Verify Restoration
```bash
# Check if restoration was successful (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d restored_db -c "\dt"
docker exec -it postgres psql -h localhost -U admin -d restored_db -c "\l"
```

## 🛠️ Manual Restoration Methods

### Method 1: Restore to New Database (Recommended)

This is the **safest approach** - it creates a new database and leaves your original data untouched.

```bash
# 1. Choose your backup file
backup_file="/opt/homelab/backups/postgres/daily/default-20250824.sql.gz"

# 2. Create a new database (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d postgres -c "CREATE DATABASE test_restore;"

# 3. Restore the backup (provide password when prompted)
zcat "$backup_file" | docker exec -i postgres psql -h localhost -U admin -d test_restore

# 4. Check the results (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d test_restore -c "SELECT version();"
```

### Method 2: Restore to Existing Database (Destructive)

⚠️ **Warning**: This will overwrite existing data in the target database.

```bash
# 1. Choose your backup and target database
backup_file="/opt/homelab/backups/postgres/daily/default-20250824.sql.gz"
target_db="my_existing_db"

# 2. Clear the target database (optional but recommended, provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d "$target_db" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# 3. Restore the backup (provide password when prompted)
zcat "$backup_file" | docker exec -i postgres psql -h localhost -U admin -d "$target_db"
```

### Method 3: Replace Main Database (Nuclear Option)

⚠️ **DANGER**: This completely replaces your main database. Use only in emergencies.

```bash
# 1. Stop PostgreSQL
docker compose stop postgres

# 2. Remove the data volume
docker volume rm homelab_postgres-data

# 3. Start PostgreSQL (creates fresh volume)
docker compose up -d postgres

# 4. Wait for PostgreSQL to initialize
sleep 15

# 5. Restore from backup
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | \
  docker exec -i postgres psql -U admin -d default
```

## 🤖 Using the Automation Script

For convenience, use the included restoration script:

```bash
# Make the script executable
chmod +x scripts/restore-postgres.sh

# List available backups
./scripts/restore-postgres.sh list

# Restore latest backup to new database
./scripts/restore-postgres.sh latest

# Restore specific backup
./scripts/restore-postgres.sh restore /opt/homelab/backups/postgres/daily/default-20250824.sql.gz

# Get info about a backup file
./scripts/restore-postgres.sh info /opt/homelab/backups/postgres/daily/default-20250824.sql.gz
```

## 🔍 Understanding Your Backups

### Check Backup Contents
```bash
# Preview what's in a backup
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | head -20

# Count lines in backup (estimate size)
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | wc -l

# Search for specific content
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz | grep "CREATE TABLE"
```

### Backup File Information
```bash
# Check file size and date
ls -lh /opt/homelab/backups/postgres/daily/

# Verify backup is valid gzip
file /opt/homelab/backups/postgres/daily/default-latest.sql.gz

# Test backup integrity
zcat /opt/homelab/backups/postgres/daily/default-latest.sql.gz > /dev/null && echo "Backup is valid"
```

## 📝 Important Notes

### About Current Backup Configuration

Your backups are configured with these options:
- `--schema-only`: Only database structure, no data
- `--blobs`: Include large objects if any
- `-Z6`: Compression level 6

This means your backups contain:
- ✅ Database schema (tables, views, functions, etc.)
- ✅ Permissions and roles
- ❌ Actual table data (unless you change the configuration)

### Backup Types Explained

- **Daily**: Created every day at 2:00 AM, kept for 30 days
- **Weekly**: Created weekly, kept for 4 weeks  
- **Monthly**: Created monthly, kept for 6 months
- **Last**: Always the most recent backup with full timestamp

## 🛡️ Safety Best Practices

### Before Restoring
1. **Always test in a new database first**
2. **Check backup file integrity**
3. **Verify you have enough disk space**
4. **Note the backup creation date**

### During Restoration
1. **Monitor PostgreSQL logs**: `docker logs -f postgres`
2. **Check disk space**: `df -h`
3. **Don't interrupt the process**

### After Restoration
1. **Verify tables were created**: `\dt`
2. **Check permissions**: `\du`
3. **Test basic queries**
4. **Compare with expected schema**

## 🔧 Troubleshooting Common Issues

### "Database already exists" Error
```bash
# Solution: Use a different database name or drop existing one
docker exec postgres dropdb -U admin existing_db_name
```

### "Permission denied" Error
```bash
# Solution: Check PostgreSQL user permissions
docker exec postgres psql -U admin -c "\du"
```

### Backup File Not Found
```bash
# Solution: Check the exact path and filename
ls -la /opt/homelab/backups/postgres/daily/
```

### Out of Space Error
```bash
# Solution: Clean up old data or add more storage
df -h
docker system prune
```

## 📚 Command Reference

### Essential Commands
```bash
# List databases (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -l

# Connect to specific database (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d database_name

# Show tables in database (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d database_name -c "\dt"

# Show database sizes (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"

# Create database (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d postgres -c "CREATE DATABASE new_database;"

# Drop database (provide password when prompted)
docker exec -it postgres psql -h localhost -U admin -d postgres -c "DROP DATABASE old_database;"
```

### Backup Commands
```bash
# Manual backup creation
docker exec postgres pg_dump -U admin -d default | gzip > manual-backup-$(date +%Y%m%d).sql.gz

# Compare two databases
docker exec postgres pg_dump -U admin -d db1 -s > schema1.sql
docker exec postgres pg_dump -U admin -d db2 -s > schema2.sql
diff schema1.sql schema2.sql
```

This straightforward approach gives you full control over the restoration process while keeping it simple and predictable!
