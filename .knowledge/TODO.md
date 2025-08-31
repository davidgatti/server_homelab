# 🚀 HomeLab Expansion TODO

## 🎯 Current Status: SOLID FOUNDATION COMPLETE ✅

### ✅ **Completed Infrastructure**
- [x] **Data Layer**: PostgreSQL + Automated Backups
- [x] **Monitoring Stack**: Prometheus + Grafana + AlertManager + Blackbox Exporter
- [x] **Container Monitoring**: cAdvisor + postgres-exporter
- [x] **Management Tools**: Watchtower + pgAdmin
- [x] **Network**: Dynamic network detection (192.168.5.x/192.168.3.x)
- [x] **Resource Management**: CPU/Memory limits optimized for Celeron N3350
- [x] **Health Checks**: All services with proper health monitoring

## 🎯 **Service Expansion Roadmap**

### 🌐 **Network & Security Services**

#### **Reverse Proxy & SSL Management**
- [ ] **Traefik** - Modern reverse proxy with automatic HTTPS
  - **Benefits**: Clean URLs (grafana.yourdomain.com), automatic SSL certificates
  - **Resource**: ~50MB RAM, very lightweight
  - **Integration**: Perfect for your existing services
  - **Priority**: ⭐⭐⭐ HIGH (Foundation for external access)

#### **VPN & Remote Access**
- [ ] **WireGuard** - Modern VPN server
  - **Benefits**: Secure remote access to HomeLab
  - **Resource**: ~10MB RAM, kernel-level efficiency
  - **Priority**: ⭐⭐ MEDIUM (Remote access)

- [ ] **Tailscale** - Zero-config VPN mesh
  - **Benefits**: Easy setup, automatic NAT traversal
  - **Resource**: ~15MB RAM
  - **Priority**: ⭐⭐ MEDIUM (Alternative to WireGuard)

### 📁 **File Storage & Media Services**

#### **Cloud Storage**
- [ ] **Nextcloud** - Private cloud platform
  - **Benefits**: Files, calendar, contacts, apps ecosystem
  - **Resource**: ~200MB RAM (uses your PostgreSQL)
  - **Integration**: Perfect fit with existing database
  - **Priority**: ⭐⭐⭐ HIGH (Replace Google Drive/Dropbox)

- [ ] **MinIO** - S3-compatible object storage
  - **Benefits**: Backup target, application data storage
  - **Resource**: ~100MB RAM
  - **Integration**: Great for backup strategies
  - **Priority**: ⭐⭐ MEDIUM (Advanced storage)

#### **Media Management**
- [ ] **Jellyfin** - Media server (Plex alternative)
  - **Benefits**: Stream movies/TV shows, no licensing
  - **Resource**: ~150MB RAM + transcoding (CPU intensive)
  - **Celeron Note**: May struggle with 4K transcoding
  - **Priority**: ⭐⭐ MEDIUM (Entertainment)

- [ ] **Transmission** - BitTorrent client
  - **Benefits**: Download management with web UI
  - **Resource**: ~50MB RAM
  - **Priority**: ⭐ LOW (If needed for media)

- [ ] **Sonarr/Radarr** - TV/Movie automation
  - **Benefits**: Automatic media collection and management
  - **Resource**: ~100MB RAM each
  - **Priority**: ⭐ LOW (Advanced media automation)

### 🏠 **Home Automation**

#### **Core Home Automation**
- [ ] **Home Assistant** - Home automation platform
  - **Benefits**: Smart home device management, automation
  - **Resource**: ~300MB RAM (can be resource intensive)
  - **Celeron Note**: Consider resource impact
  - **Priority**: ⭐⭐ MEDIUM (If you have smart devices)

- [ ] **Mosquitto** - MQTT broker
  - **Benefits**: IoT device communication hub
  - **Resource**: ~10MB RAM, very lightweight
  - **Integration**: Required for many IoT setups
  - **Priority**: ⭐ LOW (Only if doing IoT)

- [ ] **Zigbee2MQTT** - Zigbee device integration
  - **Benefits**: Connect Zigbee devices without proprietary hubs
  - **Resource**: ~30MB RAM
  - **Hardware**: Requires Zigbee USB dongle
  - **Priority**: ⭐ LOW (Hardware dependent)

### 💻 **Development & Productivity**

#### **Development Tools**
- [ ] **Gitea** - Self-hosted Git service
  - **Benefits**: Private repositories, issue tracking, CI/CD
  - **Resource**: ~100MB RAM (uses your PostgreSQL)
  - **Integration**: Perfect database integration
  - **Priority**: ⭐⭐⭐ HIGH (If you code)

#### **Database & Caching**
- [x] **Redis** - In-memory data store ✅ **NEXT TO IMPLEMENT**
  - **Benefits**: High-performance caching, session storage, pub/sub messaging
  - **Resource**: ~30-50MB RAM, very efficient
  - **Integration**: Perfect for web apps, API caching, Grafana monitoring available
  - **Priority**: ⭐⭐⭐ HIGH (Performance boost for applications)

#### **Documentation & Knowledge**
- [ ] **Outline** - Team wiki/documentation
  - **Benefits**: Beautiful documentation platform
  - **Resource**: ~150MB RAM (uses your PostgreSQL)
  - **Integration**: Database integration available
  - **Priority**: ⭐⭐ MEDIUM (Documentation)

- [ ] **BookStack** - Documentation platform
  - **Benefits**: Organized documentation with hierarchy
  - **Resource**: ~100MB RAM
  - **Priority**: ⭐⭐ MEDIUM (Alternative to Outline)

- [ ] **DokuWiki** - File-based wiki
  - **Benefits**: No database needed, very lightweight
  - **Resource**: ~20MB RAM
  - **Priority**: ⭐ LOW (Simple documentation)

### 🔒 **Security & Backup**

#### **Security Services**
- [ ] **Vault** - Secrets management
  - **Benefits**: Secure credential storage, API key management
  - **Resource**: ~100MB RAM
  - **Priority**: ⭐⭐ MEDIUM (Security enhancement)

- [ ] **Authelia** - Authentication & authorization
  - **Benefits**: Single sign-on, 2FA for all services
  - **Resource**: ~50MB RAM
  - **Integration**: Works with Traefik/NGINX
  - **Priority**: ⭐⭐ MEDIUM (Security layer)

- [ ] **Vaultwarden** - Bitwarden server
  - **Benefits**: Self-hosted password manager
  - **Resource**: ~30MB RAM (uses your PostgreSQL)
  - **Integration**: Database integration
  - **Priority**: ⭐⭐⭐ HIGH (Password management)

#### **Enhanced Backup**
- [ ] **Duplicati** - Encrypted cloud backups
  - **Benefits**: Backup to cloud providers with encryption
  - **Resource**: ~100MB RAM
  - **Priority**: ⭐⭐ MEDIUM (Cloud backup)

- [ ] **Restic** - Modern backup solution
  - **Benefits**: Deduplication, encryption, multiple backends
  - **Resource**: ~50MB RAM
  - **Priority**: ⭐⭐ MEDIUM (Advanced backup)

### 📊 **Enhanced Monitoring**

#### **System Monitoring**
- [ ] **Node Exporter** - Host system metrics
  - **Benefits**: CPU temp, disk health, complete system visibility
  - **Resource**: ~20MB RAM
  - **Integration**: Perfect for your Prometheus setup
  - **Priority**: ⭐⭐⭐ HIGH (Complete monitoring)

#### **Log Management**
- [*] **Loki** - Log aggregation system
  - **Benefits**: Centralized log collection and analysis
  - **Resource**: ~150MB RAM
  - **Integration**: Grafana integration
  - **Priority**: ⭐⭐ MEDIUM (Advanced monitoring)

- [*] **Promtail** - Log collection agent
  - **Benefits**: Collects logs from all containers
  - **Resource**: ~30MB RAM
  - **Integration**: Feeds Loki
  - **Priority**: ⭐⭐ MEDIUM (With Loki)

## Quake 3 Arena

docker create --name quake3 \
  --network=homelab \
  --ip=192.168.3.20 \
  --mac-address=02:DC:03:00:00:20 \
  --dns=192.168.1.10 \
  --hostname quake3 \
  -e TZ=Europe/Rome \
  -e SERVER_NAME="My Quake 3 Server" \
  -e FRONTEND_URL=http://192.168.3.20 \
  -e BOT_SKILLS=3 \
  -e MIN_PLAYERS=4 \
  -e MAX_CLIENTS=16 \
  -e API_AUTH_USER="admin" \
  -e API_AUTH_PASSWORD="password" \
  -v /home/davidgatti/Documents/quake3/pak0.pk3:/home/ioq3srv/ioquake3/baseq3/pak0.pk3:ro \
  tractr/simple-quake-3-server:latest