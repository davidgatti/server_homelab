# Development Guidelines

## 📋 Required Reading for AI Agents

**Before making any changes, AI agents MUST:**

1. **Check Latest Logbook Entry**: Review `.knowledge/logbook/` directory for recent changes and current system state
2. **Read Current Documentation**: Check `.knowledge/instructions/` for architecture and optimization guides  
3. **Review Expansion Planning**: Check `TODO.md` in project root for planned service additions
4. **Verify System Status**: Run `./homelab.sh status` to understand current state
5. **Document Major Changes**: Create timestamped logbook entries for significant modifications

**Current System State**: Complete monitoring infrastructure (12 services) on Intel Celeron N3350 (5.6GB RAM) with foundation-first dependencies and dynamic network detection. Last major update: 2025-08-28.

## Philosophy

### Core Beliefs

- **Incremental progress over big bangs** - Small infrastructure changes that can be tested
- **Learning from existing patterns** - Study current setup and extend consistently
- **Pragmatic over dogmatic** - Adapt to infrastructure reality and constraints
- **Clear intent over clever configurations** - Be boring and obvious with config

### Simplicity Means

- Single responsibility per service/container
- Avoid premature abstractions in compose files
- No clever tricks - choose the boring infrastructure solution
- If you need to explain the architecture, it's too complex

### Infrastructure-Specific Principles

- **Security by default** - Non-root containers unless absolutely necessary
- **Observable by design** - All services should expose metrics/health
- **Declarative over imperative** - Prefer compose files over manual commands
- **Testable changes** - Validate with `./homelab.sh status` after changes

## Process

### 1. Planning & Staging

Break complex work into 3-5 stages. Document in `IMPLEMENTATION_PLAN.md`:

```markdown
## Stage N: [Name]
**Goal**: [Specific deliverable]
**Success Criteria**: [Testable outcomes]
**Tests**: [Specific test cases]
**Status**: [Not Started|In Progress|Complete]
```
- Update status as you progress
- Remove file when all stages are done

### 2. Implementation Flow

1. **Understand** - Study existing patterns in `compose.yaml` and configs
2. **Plan** - Document changes in terms of services/networks/volumes
3. **Test** - Validate current state with `./homelab.sh status`
4. **Implement** - Make minimal changes to achieve goal
5. **Verify** - Test with `./homelab.sh restart` and status check
6. **Document** - Update ARCHITECTURE.md with patterns used

### Infrastructure Testing

- **Before changes**: `./homelab.sh status` to document current state
- **After changes**: Verify all services healthy and accessible
- **Network validation**: Confirm IPs and connectivity work
- **Configuration validation**: Services start with new configs
- **Rollback plan**: Always know how to revert changes
- **Resource monitoring**: Check system resources stay within limits

### 3. When Stuck (After 3 Attempts)

**CRITICAL**: Maximum 3 attempts per issue, then STOP.

1. **Document what failed**:
   - What you tried
   - Specific error messages
   - Why you think it failed

2. **Research alternatives**:
   - Find 2-3 similar implementations
   - Note different approaches used

3. **Question fundamentals**:
   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. **Try different angle**:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Technical Standards

### Infrastructure Principles

- **Security layering** - Docker daemon (root) → User commands → Non-root containers
- **Network isolation** - macvlan for direct LAN access, no unnecessary host access
- **Configuration externalization** - Use `configs/` directory for service configs
- **Service discovery** - Prometheus labels for automatic monitoring
- **Resource constraints** - Always define memory/CPU limits
- **Health monitoring** - Implement health checks for critical services

### Infrastructure Quality

- **Every change must**:
  - Maintain or improve security posture
  - Pass health checks after restart
  - Preserve existing service functionality
  - Follow established IP allocation patterns
  - Include appropriate Prometheus labels
  - Use version-controlled configuration (never manual UI changes)

- **Before committing infrastructure changes**:
  - Test full restart: `./homelab.sh restart`
  - Verify all services accessible via assigned IPs
  - Check monitoring targets in Prometheus
  - Ensure configuration files are properly mounted
  - Validate resource usage is within limits
  - Test Grafana dashboards load from JSON files

- **Configuration Management Rules**:
  - All configs live in `configs/` directory
  - Grafana dashboards are JSON files, not UI creations
  - Database schemas/migrations through version-controlled scripts
  - Environment variables for secrets, files for configuration

### Service Dependencies

Always add `depends_on` with health checks for services that rely on other service to work.

### Error Handling

- Fail fast with descriptive messages
- Include context for debugging
- Handle errors at appropriate level
- Never silently swallow exceptions

## Decision Framework

When multiple valid approaches exist, choose based on:

1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Project Integration

### Learning the Codebase

- Find 3 similar features/components
- Identify common patterns and conventions
- Use same libraries/utilities when possible
- Follow existing test patterns

### Tooling

- Use project's existing build system
- Use project's test framework
- Use project's formatter/linter settings
- Don't introduce new tools without strong justification

## Quality Gates

### Definition of Done

- [ ] Services start successfully with `./homelab.sh start`
- [ ] All health checks passing
- [ ] Network connectivity verified (can access services by IP)
- [ ] Monitoring integration working (Prometheus targets)
- [ ] Configuration files properly mounted and valid
- [ ] Resource limits appropriate and tested
- [ ] Security posture maintained (non-root where possible)
- [ ] ARCHITECTURE.md updated with any new patterns
- [ ] Logbook entry created for major changes (`.logbook/YYYY-MM-DD_description.md`)

### Infrastructure Testing Guidelines

- Test service isolation (containers can't access host inappropriately)
- Verify network connectivity between services when required
- Test configuration reloads without container restart when possible
- Validate backup/restore procedures for stateful services
- Check service discovery and monitoring integration
- Test failure scenarios (what happens if service goes down)

## 📚 Logbook System

### When to Create Logbook Entries

AI agents must create timestamped logbook entries (`.logbook/YYYY-MM-DD_HHMM_title.md`) for:
- ✅ Major infrastructure changes or new service additions
- ✅ Performance optimizations or resource limit modifications
- ✅ Security updates or configuration migrations
- ✅ Troubleshooting that results in permanent changes

**Helper Script**: Use `./scripts/logbook-helper.sh 'description'` to generate timestamped templates automatically.

### Logbook Entry Requirements

1. **Timestamp**: Use format `YYYY-MM-DD_HHMM_descriptive-title.md`
2. **Complete Documentation**: Include rationale, changes made, verification steps
3. **Future Guidance**: Clear instructions for next AI agents
4. **Rollback Information**: How to undo changes if needed

### Using Logbook Information

1. **Always check latest entries** before starting work
2. **Follow established patterns** from previous successful changes
3. **Update references** if procedures change
4. **Cross-reference** with `.docs/` for comprehensive context

## Important Reminders

**NEVER**:
- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code

**ALWAYS**:
- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess

## 🗺️ Navigation Patterns for AI Agents

### Before Any Work
```bash
# 1. Check system state
./homelab.sh status

# 2. Review recent changes
ls -la .knowledge/logbook/ | tail -3

# 3. Validate current setup
docker compose config --quiet
```

### Finding Relevant Information
- **Service patterns**: Search `compose.yaml` for similar services
- **Network allocation**: Check `ARCHITECTURE.md` IP ranges
- **Resource limits**: Follow patterns from existing services
- **Testing examples**: Use `.knowledge/instructions/TESTING.md` templates

## MacVLAN Network Testing (Critical Understanding)

### 🧠 Mental Model Shift

```
Docker Host: CANNOT reach MacVLAN containers directly
MacVLAN containers: Live on LAN as independent network devices
Testing: Must be done from ANOTHER container or external LAN device
```

**Key Reality**: MacVLAN = "Container gets real LAN IP, bypasses Docker host entirely"

### ⚡ Correct MacVLAN Testing Pattern

```bash
# ❌ WRONG - This will ALWAYS fail
curl 192.168.3.x:port  # Host cannot reach MacVLAN

# ✅ CORRECT - Test from another container
docker run --rm --network host curlimages/curl:latest curl -f http://192.168.3.x:port/health

# ✅ ALTERNATIVE - Test from non-MacVLAN container
docker compose exec postgres curl -f http://192.168.3.x:port/health

# ✅ BEST - Test from external device (phone, laptop on same LAN)
# Browse to http://192.168.3.x:port from another device
```

### 🚨 Critical Agent Mistakes (STOP DOING THESE)

| ❌ Wrong (Will Always Fail) | ✅ Correct Approach |
|---|---|
| `curl 192.168.3.x` from host terminal | Use `--network host` container for testing |
| "Service is down" when host can't reach it | Test from LAN perspective, not host |
| Debug Docker networking | Think "network appliance" not "Docker container" |
| Check localhost bindings | MacVLAN bypasses localhost entirely |

### 📋 MacVLAN Service Testing Checklist

```bash
# 1. Container started successfully
docker compose ps | grep service-name | grep "Up"

# 2. Container has MacVLAN IP
docker compose exec service-name ip addr show eth0 | grep 192.168.3

# 3. Service accessible from network perspective (NOT host)
docker run --rm --network host curlimages/curl:latest \
  curl -f http://192.168.3.x:port/health

# 4. Service reachable from other containers
docker compose exec postgres curl -f http://192.168.3.x:port/health

# 5. Service accessible from external LAN device
# Test from phone/laptop: http://192.168.3.x:port
```

### 🔧 MacVLAN Debugging Reality

```bash
# Check container IP allocation
docker compose exec service-name ip addr show eth0

# Verify service is listening (from inside container)
docker compose exec service-name netstat -tulpn | grep :PORT

# Test network isolation reality
ping 192.168.3.x  # This WILL FAIL from host - that's correct!

# Test from network perspective
docker run --rm --network host alpine ping -c 1 192.168.3.x
```

### 💡 MacVLAN Success Indicators

**Working MacVLAN service:**
- Container shows `Up` in `docker compose ps`
- Container has IP in 192.168.3.x range
- Service responds to `curl` from `--network host` container
- Service accessible from other LAN devices
- Host CANNOT reach it directly (this is expected!)

**Testing Commands That Actually Work:**

```bash
# From Testing perspective (not host)
docker run --rm --network host curlimages/curl:latest curl http://192.168.3.10:3000

# From another service container
docker compose exec postgres curl http://192.168.3.10:3000

# From external device (phone, laptop)
# Browse to http://192.168.3.10:3000
```

## 📊 Grafana Dashboard Management (Version-Controlled)

### 🧠 Critical Understanding
**Dashboards are NOT managed through Grafana UI**. They are version-controlled JSON files that auto-provision.

### Dashboard Workflow (NEVER use Grafana UI for permanent changes)

```bash
# ❌ WRONG - Changes lost on container restart
# Edit dashboard in Grafana web UI → Save → Changes disappear

# ✅ CORRECT - Version-controlled dashboard creation
# 1. Create/edit JSON in configs/grafana/dashboards/
# 2. Restart Grafana service
# 3. Dashboard appears automatically
```

### Grafana Provisioning Architecture

```
configs/grafana/
├── grafana.ini                    # Main Grafana config
├── provisioning/
│   ├── dashboards/default.yaml   # Dashboard provisioning config  
│   └── datasources/              # Prometheus datasource config
└── dashboards/                   # JSON dashboard definitions
    ├── docker.json              # Docker monitoring dashboard
    ├── logs.json                 # Log analysis dashboard  
    └── postgres.json             # Database monitoring dashboard
```

### Adding New Dashboards

**Step 1: Create Dashboard JSON**
```bash
# Create new dashboard file
touch configs/grafana/dashboards/new-service.json

# Structure (minimal example):
{
  "dashboard": {
    "id": null,
    "title": "Service Name Monitoring",
    "tags": ["homelab", "service-name"],
    "timezone": "browser",
    "panels": [
      // Panel definitions here
    ]
  }
}
```

**Step 2: Auto-Provision Dashboard**
```bash
# Restart Grafana to load new dashboard
docker compose restart grafana

# Verify dashboard appears
# Browse to http://192.168.3.10:3000
```

### Dashboard Development Workflow

**Option 1: JSON-First (Recommended)**
1. Copy existing dashboard JSON from `configs/grafana/dashboards/`
2. Modify JSON directly for new service
3. Restart Grafana to test
4. Iterate on JSON file

**Option 2: UI-to-JSON (For Complex Dashboards)**
1. Create dashboard in Grafana UI for experimentation
2. Export JSON from UI (Settings → JSON Model)  
3. Save exported JSON to `configs/grafana/dashboards/`
4. Delete temporary dashboard from UI
5. Restart Grafana to provision from file

### Key Provisioning Concepts

**Automatic Management:**
- Dashboards load from `/etc/grafana/dashboards/` (mounted from repo)
- Changes to JSON files require Grafana restart to apply
- Dashboard IDs are auto-assigned (keep `"id": null`)
- Editable in UI but changes are **temporary**

**Persistence Rules:**
- ✅ Changes in JSON files = Permanent
- ❌ Changes in Grafana UI = Lost on restart
- ✅ Version controlled = Team accessible  
- ❌ UI-only changes = Developer-only

### Testing Dashboard Changes

```bash
# 1. Edit dashboard JSON file
vim configs/grafana/dashboards/service-name.json

# 2. Restart Grafana to apply changes  
docker compose restart grafana

# 3. Test dashboard loads correctly
docker run --rm --network host curlimages/curl:latest \
  curl -f http://192.168.3.10:3000/api/health

# 4. Verify in UI at http://192.168.3.10:3000
```

### Common Dashboard Patterns

**Service Monitoring Template:**
- CPU/Memory usage panels
- Request rate/latency panels  
- Error rate panels
- Health check status
- Prometheus metrics integration

**File Naming Convention:**
- `service-name.json` - Individual service dashboards
- `overview.json` - High-level system dashboards
- `logs.json` - Log analysis dashboards

## 🎯 30-Second Agent Orientation

### Essential Files (Read in Order)
1. [`README.md`](../../README.md) - Project overview
2. [Latest logbook entry](.knowledge/logbook/) - Current state
3. [`ARCHITECTURE.md`](ARCHITECTURE.md#agent-context-summary) - How it works
4. [`TODO.md`](../../TODO.md) - What's next
5. [`TESTING.md`](TESTING.md) - How to validate

### Mental Model
```
Foundation Services (postgres, monitoring) 
    ↓ 
Core Services (grafana, prometheus)
    ↓ 
Support Services (backup, admin tools)
```

### Common Tasks Quick Reference
- **Add service**: Copy pattern from compose.yaml + update IP range + add `depends_on`
- **Add dashboard**: Create JSON in `configs/grafana/dashboards/` + restart Grafana
- **Test change**: `./homelab.sh restart && ./homelab.sh status`
- **Document**: Create logbook entry for major changes
- **Troubleshoot**: Check health endpoints in ARCHITECTURE.md
