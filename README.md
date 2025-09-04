# Homelab Compose

This repository is a centralized place that codifies the whole HomeLab server. This way there is one source of thought that is easy to edit, track, and test on a different network on a different server to make sure any changes done will work perfectly in the main HomeLab server.

## Quick Start

### Fresh System Setup (One-time)

**Before running compose for the first time, you need:**

1. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com | sudo bash
   ```

2. **Add your user to docker group**:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in, or run: newgrp docker
   ```

3. **Ensure you're using regular Docker** (not rootless):
   ```bash
   docker context use default
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
   ./homelab.sh start
   ```

4. **Check status**:
   ```bash
   ./homelab.sh status
   ```

## Management Commands

The `homelab.sh` script provides easy management:

```bash
./homelab.sh start            # Start all services
./homelab.sh stop             # Stop all services
./homelab.sh restart          # Restart all services
./homelab.sh status           # Show service status
./homelab.sh logs             # Show all logs
./homelab.sh logs postgres    # Show specific service logs
./homelab.sh backup           # Backup all data
```