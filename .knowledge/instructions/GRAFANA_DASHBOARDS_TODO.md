# Grafana Dashboards TODO

## Current Status ✅
- **Redis Dashboard** - Complete (11 panels, real-time monitoring)
- **PostgreSQL Dashboard** - Complete (15 panels, comprehensive DB monitoring)  
- **Docker Containers Dashboard** - Complete (13 panels, container vitals)

---

## Priority 1: Network & Service Health Dashboard 🔥
**Status**: Not Started  
**Priority**: HIGH - Critical for infrastructure monitoring  
**Complexity**: Medium (3-4 hours)  

### Key Metrics Available:
- **External Connectivity**: 
  - `probe_http_status_code` for GitHub, Google, Docker.io
  - `probe_duration_seconds` for response times
  - `probe_http_ssl` for SSL certificate monitoring
- **Internal Service Health**: 
  - `up{job="blackbox-internal"}` for all HomeLab services
  - 16 monitored endpoints discovered
- **Network Performance**:
  - `probe_dns_lookup_time_seconds`
  - `probe_http_duration_seconds` 

### Proposed Panels:
1. External Services Status (GitHub, Google, Docker.io)
2. Internal Services Health Map (All 13 HomeLab services)
3. Response Time Trends
4. SSL Certificate Expiry Warning
5. DNS Resolution Performance
6. Service Availability Heatmap (24h)

---

## Priority 2: Monitoring Stack Health Dashboard 📊
**Status**: Not Started  
**Priority**: HIGH - Monitor the monitors  
**Complexity**: Medium (2-3 hours)  

### Key Metrics Available:
- **Prometheus Health** (209 metrics):
  - `prometheus_tsdb_head_samples_appended_total`
  - `prometheus_rule_evaluation_duration_seconds`
  - `prometheus_notifications_total`
- **Grafana Analytics** (357 metrics):
  - `grafana_api_dashboard_get_duration_seconds`
  - `grafana_database_connections_in_use`
  - `grafana_alerting_active_alerts`
- **AlertManager Status** (82 metrics):
  - `alertmanager_alerts`
  - `alertmanager_notifications_total`
  - `alertmanager_cluster_health_score`

### Proposed Panels:
1. Prometheus Query Performance
2. Grafana Dashboard Load Times
3. AlertManager Alert Processing
4. Data Ingestion Rates
5. Storage Usage Trends
6. API Response Times

---

## Priority 3: Host System & Hardware Dashboard 🖥️
**Status**: Not Started  
**Priority**: MEDIUM - Hardware monitoring  
**Complexity**: Medium (2-3 hours)  

### Key Metrics Available:
- **Machine Specs** (8 metrics):
  - `machine_cpu_cores`
  - `machine_memory_bytes`
  - `container_spec_memory_limit_bytes`
- **Process Monitoring** (9 metrics):
  - `process_cpu_seconds_total`
  - `process_resident_memory_bytes`
  - `process_open_fds`
- **Go Runtime** (151 metrics):
  - `go_memstats_alloc_bytes`
  - `go_gc_duration_seconds`

### Proposed Panels:
1. CPU Core Usage per Service
2. Memory Allocation by Container
3. File Descriptor Usage
4. Garbage Collection Performance
5. Process Lifecycle Monitoring
6. Resource Limits vs Usage

---

## Priority 4: Performance & Efficiency Dashboard ⚡
**Status**: Not Started  
**Priority**: MEDIUM - Optimization insights  
**Complexity**: High (4-5 hours)  

### Key Metrics Available:
- **GC Performance**: `go_gc_duration_seconds` across all services
- **Memory Patterns**: `go_memstats_*` for memory optimization
- **CPU Efficiency**: `go_cpu_classes_*` for CPU usage patterns
- **Container Specs**: Resource limits vs actual usage

### Proposed Panels:
1. Resource Efficiency Score (CPU/Memory)
2. Garbage Collection Impact Analysis
3. Memory Allocation Patterns
4. Container Right-sizing Recommendations
5. Performance Trends Over Time
6. Bottleneck Identification

---

## Priority 5: Security & Stability Dashboard 🔒
**Status**: Not Started  
**Priority**: LOW - Advanced monitoring  
**Complexity**: High (4-5 hours)  

### Key Metrics Available:
- **Alert Tracking**: `alertmanager_alerts_*`
- **Failed Connections**: `prometheus_notifications_failed_total`
- **SSL Monitoring**: `probe_http_ssl`
- **Service Restarts**: Container restart tracking

### Proposed Panels:
1. Security Alert Trends
2. Failed Authentication Attempts
3. SSL Certificate Status
4. Service Restart Frequency
5. Error Rate Monitoring
6. Anomaly Detection

---

## Implementation Notes

### Technical Approach:
- Use Grafana REST API for automated dashboard creation
- Follow established pattern from Redis/PostgreSQL/Docker dashboards
- 15-20 panels per dashboard for comprehensive coverage
- Auto-refresh every 30s for real-time monitoring

### Resource Requirements:
- Estimated 1000+ additional metrics per dashboard
- Current Prometheus retention: 200h (sufficient)
- Grafana memory usage: Well within 400M limit

### Priority Rationale:
1. **Network Health**: Critical for detecting connectivity issues
2. **Monitoring Stack**: Essential for maintaining observability
3. **Host System**: Important for resource planning
4. **Performance**: Nice-to-have for optimization
5. **Security**: Advanced monitoring for mature setups

---

## Next Actions:
1. **Choose Priority 1 Dashboard** to implement first
2. **Define specific panel layouts** for selected dashboard  
3. **Create dashboard via Grafana API** using proven approach
4. **Test and refine** metrics and visualizations
5. **Update this todo** with completion status

---

## Service Inventory (from metrics analysis):
**16 Active Endpoints Monitored**:
- prometheus, postgres-exporter, grafana, cadvisor, alertmanager
- blackbox-http (GitHub, Google, Docker.io, Router)
- blackbox-internal (alertmanager, cadvisor, pgadmin, grafana, prometheus)
- blackbox-exporter, redis-exporter

All services reporting `up=1` ✅
