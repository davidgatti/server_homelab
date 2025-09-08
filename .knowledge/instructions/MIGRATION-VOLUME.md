# Migrating Docker Volumes to a new setup

Before migrating to a new server, this guide will help you create an up-to-date backup of all Docker volumes to ensure you have the latest data for migration, since the automated backup is good for disaster recovery, but when migrating you want to always have the latest backup at hand.

## All Docker Volumes

### On The Old Server

Create a fresh backup of existing volumes using the same backup image

```bash
# Create a one-time backup with current timestamp of only the volumes you care about
docker run --rm \
  -v n8n-data:/backup/n8n-data:ro \
  -v docmost-data:/backup/docmost-data:ro \
  -v cups-config:/backup/cups-config:ro \
  -v $(pwd)/migration-backup:/archive \
  -e BACKUP_FILENAME=migration-volumes-$(date +%Y%m%d-%H%M%S).tar.gz \
  offen/docker-volume-backup:latest
```

### On the working laptop

Copy the migration backup to local machine (run this from your laptop/local machine)

```bash
ssh home_lab "cat /home/davidgatti/migration-backup/migration-volumes-*.tar.gz" > migration-volumes-backup.tar.gz
```

### On The New Server

```bash
# Copy backup FROM laptop TO new server (run this from your laptop where the file exists)
cat migration-volumes-backup.tar.gz | ssh home_lab_research "cat > migration-volumes-backup.tar.gz"

# Now SSH to the new server to continue
ssh home_lab_research

# Verify the backup file is present on the new server
ls -lh migration-volumes-backup.tar.gz

# IMPORTANT: Clean existing volume data first
docker compose down

# Remove ALL existing volumes (this deletes everything!)
docker volume prune -f
docker volume rm $(docker volume ls -q --filter name=homelab) 2>/dev/null || true

# Create fresh volumes by starting compose (this creates empty volumes)
docker compose up --no-start

# Restore important volumes from the backup (other volumes will start fresh)
docker run --rm \
  -v postgres-data:/backup/postgres-data \
  -v qdrant-data:/backup/qdrant-data \
  -v n8n-data:/backup/n8n-data \
  -v homeassistant-config:/backup/homeassistant-config \
  -v docmost-data:/backup/docmost-data \
  -v cups-config:/backup/cups-config \
  -v $(pwd):/archive \
  offen/docker-volume-backup:latest \
  /bin/sh -c "cd /archive && tar -xzf migration-volumes-backup.tar.gz --strip-components=1"

# Start all services
docker compose up -d

# Clean up the migration backup file
rm migration-volumes-backup.tar.gz
```

## Notes

- The backup only includes critical volumes that contain important data/configuration
- Excluded volumes (redis, jellyfin, speedtest) will start fresh on the new server as they contain disposable data
- Missing volumes (grafana, pgadmin, prometheus, etc.) will start fresh on the new server
- Uses the same `offen/docker-volume-backup` image that's configured in your new HomeLab
- All important volumes are backed up in a single archive for simplicity
- Volumes are completely cleaned and recreated on the new server
- The migration backup file is automatically cleaned up after restoration
