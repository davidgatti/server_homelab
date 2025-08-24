# HomeLab Service Dependency Order

## 🔄 Startup Sequence

This document explains the logical dependency chain that ensures your HomeLab services start in the correct order.

### **Dependency Chain Visualization**

```
Level 1 (Base Services - No Dependencies):
┌─────────────┐    ┌─────────────┐
│   postgres  │    │ watchtower  │
│ (database)  │    │(monitoring) │
└─────────────┘    └─────────────┘
       │
       ▼
Level 2 (Database-Dependent Services):
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│postgres-    │    │ pgadmin     │    │postgres-    │
│backup       │    │(admin UI)   │    │exporter     │
│(backup)     │    │             │    │(metrics)    │
└─────────────┘    └─────────────┘    └─────────────┘
                                             │
                                             ▼
Level 3 (Independent Monitoring):           │
┌─────────────┐                             │
│  cadvisor   │◄────────────────────────────┘
│(container   │
│ metrics)    │
└─────────────┘
       │
       ▼
Level 4 (Metrics Aggregation):
┌─────────────┐
│ prometheus  │◄── depends on: cadvisor + postgres-exporter
│(monitoring) │
└─────────────┘
       │
       ▼
Level 5 (Visualization):
┌─────────────┐
│  grafana    │◄── depends on: prometheus + postgres
│(dashboards) │
└─────────────┘

Level 6 (Backup Services):
┌─────────────┐
│volume-      │◄── depends on: postgres + postgres-backup
│backup       │
│(full backup)│
└─────────────┘
```

### **Dependency Logic**

#### **Level 1: Core Infrastructure**
- **postgres**: Database foundation - everything depends on this
- **watchtower**: Independent container updater

#### **Level 2: Database Services**
- **postgres-backup**: Needs healthy postgres for database dumps
- **pgadmin**: Needs healthy postgres for database administration
- **postgres-exporter**: Needs healthy postgres for metrics collection

#### **Level 3: Container Monitoring**
- **cadvisor**: Independent container metrics (no dependencies)

#### **Level 4: Metrics Aggregation**
- **prometheus**: Waits for cadvisor and postgres-exporter to be healthy

#### **Level 5: Visualization**
- **grafana**: Waits for prometheus (data source) and postgres (potential data storage)

#### **Level 6: Comprehensive Backup**
- **volume-backup**: Waits for postgres and postgres-backup to ensure all data is ready

### **Health Check Integration**

Each service dependency uses `condition: service_healthy`, which means:

1. **Service must start successfully**
2. **Health check must pass** (return healthy status)
3. **Only then dependent services will start**

### **Benefits of This Approach**

✅ **Prevents startup failures** due to missing dependencies
✅ **Ensures data integrity** (database ready before backup services)
✅ **Optimizes resource usage** (services start when actually needed)
✅ **Improves reliability** (health checks ensure services are truly ready)
✅ **Logical service ordering** (monitoring comes after core services)

### **Startup Time Estimation**

```
postgres:          ~15-30 seconds
├── postgres-backup:    +10 seconds
├── pgadmin:           +15 seconds  
├── postgres-exporter: +5 seconds
    └── cadvisor:      +10 seconds (parallel)
        └── prometheus: +15 seconds
            └── grafana: +20 seconds
└── volume-backup:     +5 seconds (after postgres + postgres-backup)

Total estimated startup: ~60-90 seconds for full stack
```

### **Troubleshooting Startup Issues**

If services fail to start, check in this order:

1. **postgres** - Check database logs: `docker compose logs postgres`
2. **postgres-exporter** - Check connection: `docker compose logs postgres-exporter`
3. **cadvisor** - Check container access: `docker compose logs cadvisor`
4. **prometheus** - Check configuration: `docker compose logs prometheus`
5. **grafana** - Check data sources: `docker compose logs grafana`

### **Testing Dependency Chain**

```bash
# Test the complete startup sequence
docker compose down
docker compose up -d

# Monitor startup progress
watch -n 2 "docker compose ps --format 'table {{.Name}}\t{{.Status}}'"

# Check final health status
./scripts/health-monitor.sh
```

This dependency chain ensures your HomeLab starts reliably every time! 🚀
