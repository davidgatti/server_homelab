# HomeLab Dependency Strategy

## 🏗️ Foundation-First Approach

This HomeLab uses a **Foundation-First** dependency strategy that prioritizes core infrastructure services (monitoring, backup, management) while respecting minimal technical dependencies. This approach ensures your main HomeLab interfaces are available quickly while maintaining system reliability.

## 🚀 Startup Sequence Overview

```
Phase 1: FOUNDATION SERVICES (Parallel Start ~30s)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   postgres  │    │  cadvisor   │    │ watchtower  │
│ (database)  │    │(monitoring) │    │(management) │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   │                   │
┌─────────────┐            │                   │
│postgres-    │            │                   │
│exporter     │            │                   │
│(metrics)    │            │                   │
└─────────────┘            │                   │
       │                   │                   │
       └───────┬───────────┘                   │
               ▼                               │
Phase 2: CORE HOMELAB SERVICES (~20s)          │
┌─────────────┐                                 │
│ prometheus  │◄── depends on: postgres-exporter│
│(monitoring  │                                 │
│ foundation) │                                 │
└─────────────┘                                 │
       │                                       │
       ▼                                       │
┌─────────────┐    ┌─────────────┐            │
│  grafana    │    │volume-      │            │
│(dashboards) │    │backup       │◄───────────┘
│             │    │(protection) │
└─────────────┘    └─────────────┘
                           │
Phase 3: SUPPORT SERVICES (~5s parallel)       │
┌─────────────┐    ┌─────────────┐            │
│postgres-    │    │  pgadmin    │            │
│backup       │    │(admin UI)   │            │
│(db backup)  │    │             │            │
└─────────────┘    └─────────────┘
```

## 🎯 Priority Levels

### **Priority 1: Foundation (Critical Infrastructure)**
- **`postgres`** - Data foundation for all database-dependent services
- **`cadvisor`** - Container monitoring foundation (independent)  
- **`watchtower`** - System maintenance and updates (independent)

### **Priority 2: Core HomeLab Services (Primary Interface)**
- **`prometheus`** - Metrics aggregation and alerting engine
- **`grafana`** - Main HomeLab dashboard and visualization
- **`volume-backup`** - Data protection and disaster recovery

### **Priority 3: Support Services (Enhancement)**
- **`postgres-backup`** - Database-specific backup strategy
- **`postgres-exporter`** - Database metrics for monitoring
- **`pgadmin`** - Database administration interface
- **`alertmanager`** - Alert routing and notification
- **`blackbox-exporter`** - External service monitoring

## 🔄 Dependency Logic

### **Health Check Integration**
Each service dependency uses `condition: service_healthy`, which ensures:

1. **Service starts successfully** with proper configuration
2. **Health check passes** (returns healthy status)
3. **Dependent services start** only after dependencies are truly ready

### **Foundation-First Benefits**

#### **Core HomeLab Infrastructure Starts Early:**
✅ **Prometheus** - Monitoring foundation starts as soon as postgres-exporter is ready  
✅ **Grafana** - Main dashboard starts as soon as Prometheus is ready  
✅ **Volume-backup** - Data protection starts immediately (independent)  
✅ **cAdvisor** - Container monitoring starts immediately (independent)  

#### **Reduced Critical Path Dependencies:**
- **Grafana** can start without waiting for all database services
- **Prometheus** discovers services as they become available
- **Volume-backup** protects data independently of service readiness
- **Support services** start in parallel during final phase

## ⚡ Startup Time Analysis

### **Foundation-First Timing:**
```
Phase 1: postgres + cadvisor + watchtower (parallel ~30s)
Phase 2: postgres-exporter (5s) → prometheus (15s) → grafana (20s)  
Phase 3: volume-backup + postgres-backup + pgadmin (parallel ~5s)
Total: ~75 seconds with core services available at ~50s
```

### **Key Timing Benefits:**
- **Main dashboard available**: ~50 seconds (Grafana ready)
- **Full monitoring stack**: ~50 seconds (Prometheus + Grafana)
- **Data protection active**: ~35 seconds (volume-backup ready)
- **Complete system**: ~75 seconds (all services healthy)

## 🔍 Service Dependencies Detail

### **Level 1: No Dependencies (Foundation)**
```yaml
postgres:      # Database foundation
  # No dependencies - starts immediately
  
cadvisor:      # Container monitoring  
  # No dependencies - starts immediately
  
watchtower:    # System maintenance
  # No dependencies - starts immediately
```

### **Level 2: Single Dependencies**
```yaml
postgres-exporter:
  depends_on:
    postgres: { condition: service_healthy }

volume-backup:
  depends_on: 
    postgres: { condition: service_healthy }

postgres-backup:
  depends_on:
    postgres: { condition: service_healthy }

pgadmin:
  depends_on:
    postgres: { condition: service_healthy }
```

### **Level 3: Multiple Dependencies**
```yaml
prometheus:
  depends_on:
    postgres-exporter: { condition: service_healthy }
    cadvisor: { condition: service_healthy }

grafana:
  depends_on:
    prometheus: { condition: service_healthy }
    postgres: { condition: service_healthy }

alertmanager:
  depends_on:
    prometheus: { condition: service_healthy }
```

## 🧪 Testing & Verification

### **Test Complete Startup**
```bash
# Test the foundation-first startup sequence
docker compose down
docker compose up -d

# Monitor startup progress by phase
watch -n 2 "docker compose ps --format 'table {{.Name}}\t{{.Status}}'"
```

### **Verify Foundation Services First**
```bash
# Check that foundation services start immediately
./homelab.sh start
sleep 10
docker ps --filter "name=postgres" --filter "name=cadvisor" --filter "name=watchtower"
```

### **Test Core Service Availability**
```bash
# Verify monitoring stack comes online quickly  
timeout 60 bash -c 'until curl -s http://192.168.3.59/-/healthy; do sleep 2; done'
timeout 90 bash -c 'until curl -s http://192.168.3.60/api/health; do sleep 2; done'
```

## 🚨 Troubleshooting Startup Issues

### **Check Startup Progress by Phase**
```bash
# Phase 1: Foundation services
docker compose logs postgres cadvisor watchtower

# Phase 2: Core HomeLab services  
docker compose logs postgres-exporter prometheus grafana

# Phase 3: Support services
docker compose logs postgres-backup pgadmin volume-backup
```

### **Common Dependency Issues**
1. **Postgres not starting**: Check database logs and volume permissions
2. **Prometheus not starting**: Verify postgres-exporter health and configuration
3. **Grafana not connecting**: Check prometheus availability and database connection
4. **Services stuck in "starting"**: Check health check endpoints and timeouts

### **Health Check Verification**
```bash
# Check health status of all services
docker compose ps --format 'table {{.Name}}\t{{.Status}}'

# Get detailed health information
docker inspect <service-name> --format='{{json .State.Health}}' | jq '.'
```

## 💡 Philosophy Summary

**Traditional Approach**: "Wait for all technical dependencies before starting any service"  
**Foundation-First Approach**: "Start core HomeLab infrastructure ASAP, connect to dependencies when available"

This strategy reflects how you actually use your HomeLab:
- **Monitoring and dashboards** are your primary interfaces
- **Data protection** should start immediately  
- **Administrative tools** can start after core services are stable

🚀 **Result**: Your main HomeLab dashboard (Grafana) and monitoring (Prometheus) are available much faster, while maintaining proper dependency management and data integrity.
