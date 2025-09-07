# Migrating to a new setup

Before migrating to a new server, this guide will helpe you run on time commadns to perform an upda to date backup of all the important services to be able to have the latest version of the data, since the automated backup is good for disaster recovery, but when migrating you want to always have the latest backup at hand.

## On The Old Server

### Databases

Postgress

Backup ALL databases in the PostgreSQL instance

```bash
docker exec postgres pg_dumpall -U admin | gzip > all-databases-backup.sql.gz
```

## On the working laptop

Copy backup to local machine (run this from your laptop/local machine)

```bash
ssh home_lab "cat /home/davidgatti/backup/all-databases-backup.sql.gz" > all-databases-backup.sql.gz
```

## On The New Server

### PostgreSQL Restoration (Clean Migration)

```bash
# Copy backup FROM laptop TO new server (run this from your laptop where the file exists)
cat all-databases-backup.sql.gz | ssh home_lab_research "cat > all-databases-backup.sql.gz"

# Now SSH to the new server to continue
ssh home_lab_research

# Verify the backup file is present on the new server
ls -lh all-databases-backup.sql.gz

# IMPORTANT: Clean existing PostgreSQL data first
docker compose down

# Remove existing PostgreSQL data volume (this deletes everything!)
docker volume rm homelab_postgres-data

# Start fresh PostgreSQL container
docker compose up -d postgres

# Wait for PostgreSQL to be ready (may take a minute for fresh initialization)
docker compose logs postgres | grep "ready to accept connections"

# Restore ALL databases, using TCP connection to bypass peer authentication
zcat all-databases-backup.sql.gz | docker exec -i -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres

# Start all other services
docker compose up -d
```