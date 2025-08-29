# Grafana Dashboards

This directory contains Grafana dashboard configurations for the HomeLab environment.

## Structure
```
configs/grafana/dashboards/
├── README.md                    # This file
└── homelab-dashboard.json       # Main HomeLab services monitoring dashboard
```

## Dashboard Files

### homelab-dashboard.json
**Main HomeLab Services Monitoring Dashboard**
- **Description**: Comprehensive monitoring of all Docker services
- **Panels**: CPU, Memory, Network, Disk I/O metrics + Service Health
- **Services**: All 13 HomeLab services tracked
- **Features**: Time-series graphs, clean UI (no legends), color-coded thresholds

## Usage

### Deploy Dashboard
```bash
# From repository root
./scripts/grafana-dashboard.sh deploy configs/grafana/dashboards/homelab-dashboard.json
```

### List Current Dashboards
```bash
./scripts/grafana-dashboard.sh list
```

### Delete Dashboard
```bash
./scripts/grafana-dashboard.sh delete <dashboard-uid>
```

## Adding New Dashboards

1. **Create JSON file** in this directory
2. **Follow naming convention**: `service-name-dashboard.json`
3. **Deploy using script**: `./scripts/grafana-dashboard.sh deploy configs/grafana/dashboards/your-dashboard.json`
4. **Update this README** with dashboard description

## Dashboard Development

### Testing Changes
1. Make changes to JSON file
2. Deploy updated version: `./scripts/grafana-dashboard.sh deploy <file>`
3. Old version is automatically replaced

### Backup Current Dashboards
Export from Grafana UI and save to this directory for version control.

## Access URLs
- **Grafana**: http://192.168.5.60/
- **Current HomeLab Dashboard**: Check deployment output for latest URL

## Notes
- All dashboards use Prometheus data source (http://192.168.5.59:9090)
- Dashboards auto-refresh every 30 seconds
- Time range defaults to last 1 hour
- Dark theme is default
