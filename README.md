# Homelab Compose

This repository is a centralized place that codifies the whole HomeLab server. This way there is one source of thought that is easy to edit, track, and test on a different network on a different server to make sure any changes done will work perfectly in the main HomeLab server.

## Quick Start

### Fresh System Setup (One-time)

**Before running compose for the first time, you need to prepare your system. Follow these steps in order:**

1. **Update and upgrade the system**:

   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. **Install Docker** (if not already installed):

   ```bash
   curl -fsSL https://get.docker.com | sudo bash
   ```

3. **Add your user to docker group**:

   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in, or run: newgrp docker
   ```

4. **Ensure you're using regular Docker** (not rootless):

   ```bash
   docker context use default
   ```

5. **Reboot to apply group changes**:

   ```bash
   sudo reboot
   ```

6. **Install GitHub CLI and configure Git**:

   ```bash
   sudo apt install gh
   git config --global user.name "David Gatti"
   git config --global user.email "dawid@gatti.io"
   gh auth login
   ```

7. **Clone necessary repositories**:

   ```bash
   git clone https://github.com/davidgatti/tools_cli.git
   ```

8. **Install basic tools**:

   ```bash
   sudo apt update && sudo apt install -y mc zip jq cmatrix
   ```

9. **Set up NAS mounting** (backup and media shares):

   First, ensure cifs-utils is installed:

   ```bash
   sudo apt install -y cifs-utils
   ```

   **Create mount directories and groups:**

   ```bash
   # Create directories
   sudo mkdir -p /mnt/backup 
   sudo mkdir -p /mnt/nas_media
   sudo mkdir -p /mnt/nas_documents
   
   # Create groups
   sudo groupadd nas_backup 2>/dev/null || true
   sudo groupadd nas_media 2>/dev/null || true
   sudo groupadd nas_documents 2>/dev/null || true
   
   # Set permissions
   sudo chown root:nas_backup /mnt/backup
   sudo chown root:nas_media /mnt/nas_media
   sudo chown root:nas_documents /mnt/nas_documents
   
   sudo chmod 0775 /mnt/backup 
   sudo chmod 0775 /mnt/nas_media
   sudo chmod 0775 /mnt/nas_documents
   
   # Add your user to the groups
   sudo usermod -aG nas_backup $USER
   sudo usermod -aG nas_media $USER
   sudo usermod -aG nas_documents $USER
   ```

   **Add NAS mounts to fstab:**

   **For shares that require credentials (like backup):**

   ```shell
   # Create credentials directory and file (for backup share)
   sudo mkdir -p /etc/cifs

   echo -e "username=backup\npassword=XXXXXXXX" | sudo tee /etc/cifs/documents-credentials > /dev/null
   sudo chmod 600 /etc/cifs/backup-credentials
   echo "//192.168.2.2/backup /mnt/backup cifs credentials=/etc/cifs/backup-credentials,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,vers=2.0 0 0" | sudo tee -a /etc/fstab

   echo -e "username=documents\npassword=XXXXXXXX" | sudo tee /etc/cifs/documents-credentials > /dev/null
   sudo chmod 600 /etc/cifs/documents-credentials
   echo "//192.168.2.2/documents /mnt/nas_documents cifs credentials=/etc/cifs/documents-credentials,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,vers=2.0 0 0" | sudo tee -a /etc/fstab
   ```

   **For public shares (like media):**

   ```bash
   # Media share (guest access)
   echo "//192.168.2.2/media /mnt/nas_media cifs guest,forceuid,forcegid,uid=0,gid=nas_media,file_mode=0664,dir_mode=0775,rw,vers=2.0 0 0" | sudo tee -a /etc/fstab
   ```

   **Mount the shares:**

   ```bash
   sudo systemctl daemon-reload
   sudo mount -a
   ```

   **Verify mounts are working:**

   ```bash
   df -h | grep nas
   ls -la /mnt/backup /mnt/nas_media
   ```

   > **Security Note:**
   > - **Credential files** are stored in `/etc/cifs/` with `600` permissions (root only)
   > - **Guest access** is used for public shares (media) that don't require authentication
   > - **Never commit credential files** to version control - they contain sensitive passwords

10. **Log out and back in** to apply group changes:

    ```bash
    # Log out and back in, or run:
    newgrp nas_backup
    newgrp nas_media
    ```

### Project Setup

1. **Clone and setup**:

   ```bash
   git clone https://github.com/davidgatti/HomeLab
   cd HomeLab
   ```

2. **Create necessary folders**:

   ```bash
   mkdir -p ~/homelab/backups/databases/postgres
   mkdir -p ~/homelab/backups/volumes
   ```

3. **Start services**:

   ```bash
   docker compose up -d
   ```

4. **Check status**:

   ```bash
   docker compose ps
   ```

### Database Setup (One-time)

After starting the services, you need to create database users for certain applications:

**For Paperless (document management):**

```bash
# Connect to PostgreSQL container
docker exec -it postgres psql -U admin -d default

# Create paperless user and database
CREATE USER paperless WITH PASSWORD 'Paperless2025SecurePass';
CREATE DATABASE paperless OWNER paperless;
GRANT ALL PRIVILEGES ON DATABASE paperless TO paperless;

# Exit PostgreSQL
\q
```

> **Note:** Other services like Docmost automatically create their databases using the admin credentials, but Paperless requires its own dedicated user.

## Management Commands

Standard Docker Compose commands:

```bash
docker compose up -d          # Start all services
docker compose down           # Stop all services
docker compose restart       # Restart all services
docker compose ps            # Show service status
docker compose logs          # Show all logs
docker compose logs postgres # Show specific service logs
```


```bash
# Create gitea database
docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "CREATE USER gitea WITH PASSWORD 'gitea';"
docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "CREATE DATABASE gitea WITH OWNER gitea;"
docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;"
```

#### Create Gitea Admin User

```bash
# Create your admin user (replace with your details)
docker exec -u git gitea /usr/local/bin/gitea admin user create --admin --username david --password password --email david@local.lan
```

```bash
docker exec -u git gitea /usr/local/bin/gitea actions generate-runner-token
docker exec act-runner sh -c "cd /data && act_runner register --no-interactive --instance http://gitea --token TOKEN" 2>/dev/null || echo "Runner already registered"
docker restart act-runner
```

docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "CREATE USER kanboard WITH PASSWORD 'kanboard';"
docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "CREATE DATABASE kanboard WITH OWNER kanboard;"
docker exec -e PGPASSWORD=password postgres psql -h localhost -U admin -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE kanboard TO kanboard;"