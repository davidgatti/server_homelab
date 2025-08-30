# HomeLab Architecture & Implementation Guide

## Project Philosophy

This HomeLab project demonstrates **modern infrastructure best practices** using Docker Compose with a **security-first, automation-focused approach**. The core principle is achieving maximum functionality while maintaining proper security layers and minimal manual intervention.

### Key Principles

1. **Security Layered Architecture**: Docker daemon handles privileges, containers run as non-root
2. **Direct LAN Integration**: Each service gets unique IP via macvlan networking
3. **Zero Manual Configuration**: Automated detection and setup
4. **Declarative Infrastructure**: Everything defined in version-controlled files
5. **Production-Ready Monitoring**: Built-in observability stack

## Architecture Overview

### Network Architecture: macvlan Direct LAN Access

```
┌─────────────────────────────────────────────────────────┐
│                    Home Network                         │
│                   192.168.3.0/24                        │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────┴────────┐
              │    Router      │
              │  192.168.3.1   │
              └───────┬────────┘
                      │
              ┌───────┴────────┐
              │  Docker Host   │
              │  192.168.3.51  │  ← Server
              └───────┬────────┘
                      │
              ┌───────┴────────┐
              │ macvlan bridge │
              │   (homelab)    │
              └───────┬────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────┴───┐   ┌─────┴──┐   ┌──────┴───┐
   │Grafana │   │Postgres│   │Prometheus│
   │ .3.60  │   │ .3.53  │   │ .3.59    │
   │(port80)│   │(5432)  │   │(port80)  │
   └────────┘   └────────┘   └──────────┘
```

**Benefits:**
- No port conflicts - each service uses native ports
- Direct access from any network device (no port forwarding)
- Services appear as separate devices to router
- Clean URLs: http://grafana.home, http://prometheus.home

### Security Architecture: Layered Privilege Model

```
┌─────────────────────────────────────────────────────────┐
│                System Level (Root)                      │
│  ┌─────────────────────────────────────────────────┐    │
│  │           Docker Daemon                         │    │
│  │  • Creates macvlan interfaces                   │    │
│  │  • Manages privileged operations                │    │
│  │  • Handles network namespaces                   │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────┘
                      │ docker group membership
┌─────────────────────┴───────────────────────────────────┐
│              User Level (Non-Root)                      │
│  ┌─────────────────────────────────────────────────┐    │
│  │           Docker Client                         │    │
│  │  • Sends commands to daemon                     │    │
│  │  • Manages compose orchestration                │    │
│  │  • No direct system privileges                  │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────┘
                      │ container creation
┌─────────────────────┴───────────────────────────────────┐
│            Container Level (Application)                │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐  │
│  │   PostgreSQL    │ │    Grafana      │ │   Apps    │  │
│  │ (postgres user) │ │  (root for :80) │ │(app users)│  │
│  │   uid=999       │ │    uid=0        │ │ uid=1000+ │  │
│  └─────────────────┘ └─────────────────┘ └───────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Security Benefits:**
- **Minimal Attack Surface**: Only necessary containers run as root
- **Principle of Least Privilege**: Each layer has minimal required permissions
- **Network Isolation**: Containers can't access host network stack
- **User Separation**: Application compromises don't affect host system

## Implementation Details

### Docker Context Management

The project uses **regular Docker** (not rootless) for macvlan capabilities:

```bash
# Ensure correct Docker context
docker context use default

# Verify regular daemon (not rootless)
docker version  # Should NOT show "rootlesskit"
```

### Network Creation Strategy

**Compose-Managed macvlan** (preferred approach):

```yaml
networks:
  homelab:
    name: homelab  # Override default "project_network" naming
    driver: macvlan
    driver_opts:
      parent: ${NETWORK_INTERFACE:-eno1}  # Auto-detected or manual
    ipam:
      config:
        - subnet: 192.168.3.0/24
          gateway: 192.168.3.1
```

**Benefits over manual creation:**
- Version controlled network configuration
- Automatic interface detection
- Portable across different systems
- Single command deployment

### Service Configuration Patterns

#### Standard Non-Root Service
```yaml
postgres:
  image: postgres:latest
  container_name: postgres
  # No user override - runs as postgres (uid=999)
  networks:
    homelab:
      ipv4_address: 192.168.3.53
  volumes:
    - postgres-data:/var/lib/postgresql/data
  environment:
    - POSTGRES_USER=${POSTGRES_USER}
  # Result: Secure, isolated, direct LAN access
```

#### Privileged Service (Only When Required)
```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  user: "0"  # Required for port 80 binding
  networks:
    homelab:
      ipv4_address: 192.168.3.60
  volumes:
    - ./configs/grafana/grafana.ini:/etc/grafana/grafana.ini:ro
  # Result: Root privileges only where absolutely necessary
```

### Configuration Management

**External Configuration Files** (recommended pattern):

```
configs/
├── grafana/
│   └── grafana.ini       # Custom Grafana config
├── prometheus/
│   └── prometheus.yml    # Service discovery config
└── nginx/
    └── nginx.conf        # Future reverse proxy
```

**Benefits:**
- Configuration changes without rebuilding images
- Version-controlled settings
- Environment-specific overrides
- Easy troubleshooting and debugging

### Monitoring Stack Implementation

**Prometheus Service Discovery**:
```yaml
# Auto-discovers Docker containers
docker_sd_configs:
  - host: unix:///var/run/docker.sock
    refresh_interval: 5s
    filters:
      - name: label
        values: ["prometheus.scrape=true"]
```

**Container Labeling Pattern**:
```yaml
labels:
  - "prometheus.scrape=true"      # Enable monitoring
  - "prometheus.job=servicename"  # Job classification
  - "prometheus.path=/metrics"    # Metrics endpoint
```

## Extension Patterns

### Adding New Services

**Required Elements for New Services:**
```yaml
new-service:
  image: service:latest
  container_name: service-name
  restart: unless-stopped
  networks:
    homelab:
      ipv4_address: 192.168.3.XX  # Next available IP
      mac_address: "02:42:48:4C:NN:XX"  # See AGENTS.md for pattern
  volumes:
    - service-data:/data
  labels:
    - "prometheus.scrape=true"    # Enable monitoring
    - "prometheus.port=PORT"      # Service port
    - "prometheus.job=service-name"
  depends_on:
    postgres: { condition: service_healthy }  # If needed
```

**Don't forget to add the volume:**
```yaml
volumes:
  service-data:
    driver: local
```

### Configuration Strategy

**External configs for maintainability:**
- Create `configs/service-name/` directory
- Mount as read-only: `./configs/service-name/config.yml:/app/config.yml:ro`
- Version control all configuration files

## Quick Start

### Prerequisites
1. **Docker**: `curl -fsSL https://get.docker.com | sudo bash`
2. **User Access**: `sudo usermod -aG docker $USER` (logout/login required)
3. **Regular Docker**: `docker context use default` (not rootless)

## Key Architectural Decisions

### Why macvlan Instead of Bridge Networking?

**Decision**: Use macvlan for direct LAN access instead of Docker bridge + port forwarding

**Rationale**:
- **No port conflicts**: Each service uses native ports (Grafana on :80, not :3000)
- **Network simplicity**: Services appear as real devices to router/firewall
- **External access**: No complex port forwarding rules
- **Clean URLs**: `http://grafana.home` instead of `http://server:3000`

**Trade-off**: Host cannot reach containers directly (use `--network host` for testing)

### Why Some Containers Run as Root?

**Decision**: Minimal root usage - only when required for functionality

**Services requiring root**:
- **Grafana**: Needs root to bind to port 80
- **Traefik** (future): Needs root for SSL certificate management

**All others run as non-root**: postgres (uid=999), exporters (uid=65534), etc.

**Rationale**: Principle of least privilege while maintaining functionality

### Why Compose-Managed Networks?

**Decision**: Define macvlan network in compose.yaml instead of manual creation

**Benefits**:
- **Version controlled**: Network config tracked in git
- **Portable**: Works across different systems
- **Auto-detection**: Network interface discovered automatically
- **Single command**: `docker compose up` handles everything

### Why External Configuration Files?

**Decision**: Mount config files from `configs/` instead of environment variables

**Rationale**:
- **Complex configs**: Prometheus rules, Grafana dashboards need structured formats
- **Version control**: Configuration changes tracked in git
- **No rebuilds**: Change config without rebuilding images
- **Validation**: Can validate config syntax before deployment

## Agent Context Summary

**For AI Agents working on this project:**

### Core Architectural Decisions

1. **macvlan networking**: Direct LAN IPs, no port forwarding
2. **Minimal root privileges**: Only Grafana runs as root (port 80 binding)
3. **External configuration**: Files in `configs/` directory, not env vars
4. **Health-based dependencies**: Services wait for actual health, not just startup
5. **Prometheus service discovery**: Auto-discovers containers via labels

### Adding New Services Checklist

- [ ] Assign next available IP in 192.168.3.x range
- [ ] Add MAC address following pattern in AGENTS.md
- [ ] Include Prometheus labels for monitoring
- [ ] Add `depends_on` with health checks if needed
- [ ] Use external config files for complex configuration
- [ ] Test with MacVLAN-aware commands (see AGENTS.md)

### Key Files

- `compose.yaml`: Service definitions with macvlan networking
- `homelab.sh`: Management script with auto-detection
- `configs/*/`: Service-specific configuration files

### Testing Reminders

- **MacVLAN isolation**: Host cannot reach containers directly
- **Use network-aware testing**: `docker run --rm --network host curlimages/curl`
- **Validate with**: `./homelab.sh status` after changes

This architecture enables secure, maintainable homelab infrastructure with enterprise-grade monitoring and zero-configuration deployment.
