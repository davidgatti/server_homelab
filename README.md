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

9. **Set up NAS mounting** (with resilience for disconnections):
   
   First, ensure cifs-utils is installed:
   ```bash
   dpkg -s cifs-utils &>/dev/null || (echo "Installing cifs-utils..." && sudo apt update && sudo apt install -y cifs-utils)
   ```

   **Note:** These mounts are configured with options to handle network disconnections gracefully. They use `soft` mounting for non-blocking failures and `retry` for reconnection attempts. However, for long-term unavailability (e.g., 30+ minutes), the mounts won't automatically reconnect. For better resilience, we'll set up systemd automount units below, which mount shares on-demand and handle reconnections more robustly.

   **Create systemd automount units for each share:**

   **Dropbox Share:**
   ```bash
   sudo mkdir -p /mnt/nas_dropbox
   sudo groupadd nas_dropbox
   sudo chown root:nas_dropbox /mnt/nas_dropbox
   sudo chmod 0775 /mnt/nas_dropbox
   sudo usermod -aG nas_dropbox $USER
   
   # Create mount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_dropbox.mount
   [Unit]
   Description=NAS Dropbox Share
   After=network-online.target
   Wants=network-online.target
   
   [Mount]
   What=//192.168.2.2/dropbox
   Where=/mnt/nas_dropbox
   Type=cifs
   Options=guest,forceuid,forcegid,uid=0,gid=nas_dropbox,file_mode=0664,dir_mode=0775,rw,vers=3.0,soft,retry=5
   TimeoutSec=30
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   # Create automount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_dropbox.automount
   [Unit]
   Description=Automount NAS Dropbox Share
   After=network-online.target
   Wants=network-online.target
   
   [Automount]
   Where=/mnt/nas_dropbox
   TimeoutIdleSec=300
   
   [Install]
   WantedBy=multi-user.target
   EOF
   ```

   **Media Share:**
   ```bash
   sudo mkdir -p /mnt/nas_media
   sudo groupadd nas_media
   sudo chown root:nas_media /mnt/nas_media
   sudo chmod 0775 /mnt/nas_media
   sudo usermod -aG nas_media $USER
   
   # Create mount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_media.mount
   [Unit]
   Description=NAS Media Share
   After=network-online.target
   Wants=network-online.target
   
   [Mount]
   What=//192.168.2.2/media
   Where=/mnt/nas_media
   Type=cifs
   Options=guest,forceuid,forcegid,uid=0,gid=nas_media,file_mode=0664,dir_mode=0775,rw,vers=3.0,soft,retry=5
   TimeoutSec=30
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   # Create automount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_media.automount
   [Unit]
   Description=Automount NAS Media Share
   After=network-online.target
   Wants=network-online.target
   
   [Automount]
   Where=/mnt/nas_media
   TimeoutIdleSec=300
   
   [Install]
   WantedBy=multi-user.target
   EOF
   ```

   **Docker Share:**
   ```bash
   sudo mkdir -p /mnt/nas_docker
   sudo groupadd nas_docker
   sudo chown root:nas_docker /mnt/nas_docker
   sudo chmod 0775 /mnt/nas_docker
   sudo usermod -aG nas_docker $USER
   
   # Create mount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_docker.mount
   [Unit]
   Description=NAS Docker Share
   After=network-online.target
   Wants=network-online.target
   
   [Mount]
   What=//192.168.2.2/docker
   Where=/mnt/nas_docker
   Type=cifs
   Options=guest,forceuid,forcegid,uid=0,gid=nas_docker,file_mode=0664,dir_mode=0775,rw,vers=3.0,soft,retry=5
   TimeoutSec=30
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   # Create automount unit
   cat <<EOF | sudo tee /etc/systemd/system/mnt-nas_docker.automount
   [Unit]
   Description=Automount NAS Docker Share
   After=network-online.target
   Wants=network-online.target
   
   [Automount]
   Where=/mnt/nas_docker
   TimeoutIdleSec=300
   
   [Install]
   WantedBy=multi-user.target
   EOF
   ```

   **Enable and start the automount units:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable mnt-nas_dropbox.automount mnt-nas_media.automount mnt-nas_docker.automount
   sudo systemctl start mnt-nas_dropbox.automount mnt-nas_media.automount mnt-nas_docker.automount
   ```

10. **Activate the mounts**:
    ```bash
    sudo systemctl daemon-reload
    sudo mount -a
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
