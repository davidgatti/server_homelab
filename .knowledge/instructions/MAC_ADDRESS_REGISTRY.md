# HomeLab MAC Address Registry - Dynamic Network-Based Scheme

## Overview
This HomeLab uses a dynamic MAC address generation scheme that automatically adapts to the detected network. The MAC addresses are generated using the same network detection logic as the IP addresses.

## MAC Address Scheme
Format: `02:42:48:4C:NN:XX`
- `02:42` = Docker standard prefix (locally administered)
- `48:4C` = HomeLab identifier ("HL" in hex)
- `NN` = Network identifier (auto-detected):
  - `03` = 192.168.3.x network (LAB)
  - `05` = 192.168.5.x network (RESEARCH)
  - `07` = 192.168.7.x network (future)
  - etc.
- `XX` = Service IP last octet in hex (for easy IP/MAC correlation)

## Dynamic Generation Tools
- `./homelab.sh mac` - Show MAC addresses for current network
- `scripts/mac-generator.sh` - Generate MACs for any network

## Network Identification Benefits
- **Automatic adaptation**: Works on any configured network
- **Unique across router**: Each network has distinct MAC space
- **Easy network troubleshooting**: Immediately know which network a device belongs to
- **VLAN management**: Simple filtering by network identifier
- **Scalable**: Expands to new networks without manual configuration

## Current Network Assignments

> **Note**: These are automatically generated based on detected network

### Network 5 (192.168.5.x) - RESEARCH - NN=05

| Service | IP | MAC Address | Hex Conversion |
|---------|----|-----------|----|
| postgres | 192.168.5.53 | `02:42:48:4C:05:35` | 53 → 0x35 |
| watchtower | 192.168.5.54 | `02:42:48:4C:05:36` | 54 → 0x36 |
| alertmanager | 192.168.5.56 | `02:42:48:4C:05:38` | 56 → 0x38 |
| prometheus | 192.168.5.59 | `02:42:48:4C:05:3B` | 59 → 0x3B |
| grafana | 192.168.5.60 | `02:42:48:4C:05:3C` | 60 → 0x3C |

### Services Without Custom MAC (Docker assigns random):
| Service | IP | MAC | Description |
|---------|----|-----------|----|
| postgres-backup | 192.168.5.55 | Random | PostgreSQL Backup |
| volume-backup | 192.168.5.57 | Random | Volume Backup |
| pgadmin | 192.168.5.58 | Random | PostgreSQL Admin |
| blackbox-exporter | 192.168.5.61 | Random | Blackbox Monitoring |
| cadvisor | 192.168.5.62 | Random | Container Metrics |
| redis | 192.168.5.63 | Random | Redis Cache |
| postgres-exporter | 192.168.5.64 | Random | PostgreSQL Metrics |
| redis-exporter | 192.168.5.65 | Random | Redis Metrics |

## Future Network Examples

### Network 3 (192.168.3.x):
```yaml
# Example for 192.168.3.x network
service:
  networks:
    network3:
      ipv4_address: 192.168.3.100
      mac_address: "02:42:48:4C:03:64"  # 03=network, 64=100 in hex
```

### Network 7 (192.168.7.x):
```yaml
# Example for 192.168.7.x network  
service:
  networks:
    network7:
      ipv4_address: 192.168.7.50
      mac_address: "02:42:48:4C:07:32"  # 07=network, 32=50 in hex
```

## Benefits of This Scheme

### Network Identification
- **Easy to spot**: Any MAC starting with `02:42:HL` is a HomeLab device
- **Service categorization**: Second byte indicates service type
- **IP correlation**: Last byte matches IP for easy mapping

### Router/DHCP Configuration
```bash
# Example DHCP reservations based on MAC
02:42:HL:02:00:60 → grafana.homelab.local
02:42:HL:03:00:59 → prometheus.homelab.local
02:42:HL:01:00:53 → postgres.homelab.local
```

### Network Monitoring
- Filter network traffic by `02:42:HL:*` pattern
- Identify HomeLab devices in network scans
- Easy troubleshooting and inventory management

## Implementation Commands

```bash
# Apply MAC addresses to all services
docker compose down
docker compose up -d

# Verify MAC addresses
docker network inspect homelab | jq '.[] | .Containers | to_entries | map({name: .value.Name, mac: .value.MacAddress, ip: .value.IPv4Address})'
```

## Router Integration

### pfSense/OPNsense
1. **DHCP Reservations**: Use MAC addresses for static assignments
2. **Firewall Rules**: Create rules based on MAC patterns
3. **Traffic Monitoring**: Filter by HomeLab MAC prefix

### UniFi Controller
1. **Device Naming**: Automatically name devices based on MAC pattern
2. **Network Policies**: Apply QoS based on device type
3. **Monitoring**: Group HomeLab devices for statistics

## Future Expansion

When adding new services:
1. Choose appropriate category (01-06)
2. Use next available IP in range
3. Follow MAC pattern: `02:42:HL:XX:00:YY`
4. Update this registry

Example for new service:
```yaml
new-service:
  networks:
    homelab:
      ipv4_address: 192.168.5.67
      mac_address: "02:42:HL:04:00:67"  # Infrastructure category
```
