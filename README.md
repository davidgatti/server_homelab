# Homelab Compose

This repository is a centralized place that codifies the whole HomeLab server. This way there is one source of thought that is easy to edit, track, and test on a different network to make sure any changes done will work perfectly in the main HomeLab server.

## Knowledge

All the documentation, instructions, and history is located in the `.knowledge/` folder. This is a non-standard location for all the knowledge, but due to AI and the benefit of writing down everything to help an Agent understand what needs to be done, this centralized folder helps the project be easier to read, and more organized. If you are new, review the content of this folder, it has all the knowledge about this project.


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

4. **Network interface auto-detection**:
   - The script automatically detects your default network interface

### Project Setup

1. **Clone and setup**:
   ```bash
   git clone https://github.com/davidgatti/HomeLab
   cd HomeLab
   ```

2. **Start services**:
   ```bash
   ./homelab.sh start
   ```

3. **Check status**:
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

## Adding New Services

1. **Add to `compose.yaml`**:
   ```yaml
   services:
     postgres:
       # existing config...
     
     redis:
       image: redis:latest
       container_name: redis
       restart: unless-stopped
       networks:
         homelab:
           ipv4_address: 192.168.10.13
       volumes:
         - redis-data:/data
   
   volumes:
     redis-data:
   ```

2. **Update `.env`** with new service variables

3. **Test incrementally**:
   ```bash
   ./homelab.sh restart
   ./homelab.sh status
   ```

## Troubleshooting

### Docker Setup Issues

- **"Permission denied" when creating network**:
  ```bash
  # Check if user is in docker group
  groups $USER | grep docker
  # If not in group, run: sudo usermod -aG docker $USER
  # Then logout/login or run: newgrp docker
  ```

- **"Cannot connect to Docker daemon"**:
  ```bash
  # Check if Docker daemon is running
  sudo systemctl status docker
  # Start if needed: sudo systemctl start docker
  ```

- **"Invalid subinterface vlan name"**:
  ```bash
  # Check your network interface name
  ip route | grep default
  # Use the correct interface in the macvlan command (e.g., eth0, eno1, enp1s0)
  ```

- **VS Code Docker extension not showing containers**:
  ```bash
  # Ensure you're using regular Docker (not rootless)
  docker context use default
  docker context list  # Should show "default" as current
  ```

### Service Issues

- **Check logs**: `./homelab.sh logs [service]`
- **Verify network**: `docker network inspect homelab`
- **Check health**: `docker compose ps`
- **Reset everything**: `./homelab.sh stop && docker system prune -f && ./homelab.sh start`

### Change Tracking
- **Logbook**: `.knowledge/logbook/` contains timestamped records of all major infrastructure changes
  - Add a new entry on major using ghe init.sh tool first, and then edit the file.
- **Documentation**: `.knowledge/instructions/` contains comprehensive guides and architecture details
- **Expansion Planning**: `.knowledge/TODO.md` contains categorized roadmap for future service additions
- **Latest Changes**: Check logbook entries for recent optimizations and system updates