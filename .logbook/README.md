# HomeLab Infrastructure Logbook

## 📋 Purpose

This logbook tracks all major infrastructure changes, optimizations, and maintenance activities for the HomeLab Docker Compose environment. Each entry provides a complete record of what was changed, why, and how to verify or rollback if needed.

## 📁 Naming Convention

Logbook entries follow this naming pattern:
```
YYYY-MM-DD_HH:MM_short-descriptive-title.md
```

**Examples**:
- `2025-08-24_12:35_homelab-complete-optimization.md`
- `2025-09-15_09:30_grafana-dashboard-updates.md`
- `2025-10-03_14:45_security-hardening-phase1.md`

## 📝 Entry Template

Each logbook entry should contain:

### Header Section
```markdown
# Short Descriptive Title

**Date**: YYYY-MM-DD
**Type**: [Major Infrastructure | Service Update | Security | Maintenance | Troubleshooting]
**Impact**: [High | Medium | Low] - Brief impact description
**Status**: [🔧 In Progress | ✅ Completed | ❌ Failed | 🔄 Partial]
```

### Required Sections
- **Executive Summary**: 2-3 sentence overview of what was done
- **Changes Made**: Detailed list of modifications with files and rationale
- **System Status After Changes**: Current state and performance metrics
- **Verification Steps**: How to confirm changes are working
- **Next Steps for Future AI Agents**: Guidance for continued work
- **Rollback Information**: How to undo changes if needed

## 🤖 AI Agent Guidelines

### When to Create Logbook Entries

Create a new logbook entry for:
- ✅ Major infrastructure changes (new services, architecture changes)
- ✅ Performance optimizations or resource limit adjustments
- ✅ Security updates or hardening measures
- ✅ Configuration migrations or refactoring
- ✅ Troubleshooting that results in permanent changes
- ✅ Service additions or removals

### When NOT to Create Entries

Skip logbook entries for:
- ❌ Minor configuration tweaks
- ❌ Temporary debugging commands
- ❌ Read-only information gathering
- ❌ Documentation-only updates (unless major restructuring)

### Required Actions for AI Agents

1. **Before Major Changes**: Review latest logbook entries to understand current state
2. **During Changes**: Document decisions and rationale as you work
3. **After Changes**: Create comprehensive logbook entry with verification steps
4. **Update References**: Update this README or other docs if procedures change

## 📊 Current System State (Last Updated: 2025-08-24)

### Infrastructure Overview
- **Hardware**: Intel Celeron N3350 (2 cores @ 1.10GHz), 5.6GB RAM, 98GB storage
- **Network**: MacVLAN on 192.168.3.0/24
- **Services**: 9 Docker containers with resource optimization
- **Configuration**: Single-file compose.yaml (environment-free)

### Key Services
- **Database**: PostgreSQL with daily backups to `/opt/homelab/backups/postgres/`
- **Monitoring**: Prometheus + Grafana with foundation-first dependencies
- **Management**: pgAdmin, Watchtower for updates
- **Metrics**: cAdvisor, postgres-exporter for system monitoring

### Resource Allocation
- **Memory Usage**: 2.7GB allocated (48% of total), 2.9GB safety margin
- **CPU Allocation**: 2.85 cores (143% oversubscription - normal for HomeLab)
- **Health Status**: All services healthy with comprehensive healthchecks

### Key File Locations
- **Main Config**: `compose.yaml` (self-contained, no external dependencies)
- **Monitoring**: `scripts/homelab-resource-monitor.sh`
- **Logbook Helper**: `scripts/logbook-helper.sh` (generates timestamped templates)
- **Documentation**: `.docs/` directory
- **Backups**: `/opt/homelab/backups/postgres/`

## 🔧 Common Maintenance Tasks

### Weekly Tasks
```bash
# Resource monitoring
./scripts/homelab-resource-monitor.sh

# Service health check
docker compose ps
docker stats --no-stream
```

### Monthly Tasks
- Review logbook entries for patterns
- Check actual resource usage vs limits
- Verify backup integrity
- Update documentation if procedures changed

## 🚨 Troubleshooting Quick Reference

### Service Won't Start
1. Check logbook for recent changes
2. Verify healthcheck endpoints: `docker compose logs [service]`
3. Check resource constraints: `docker stats`
4. Review dependency order in foundation-first strategy

### Resource Issues
1. Run resource monitor: `./scripts/homelab-resource-monitor.sh`
2. Check for services hitting limits
3. Review recent logbook entries for resource changes
4. Consider temporary limit adjustments

### Configuration Issues
1. Validate syntax: `docker compose config --quiet`
2. Check for recent environment-free migration changes
3. Review logbook for configuration modifications
4. Compare against git history for rollback

## 📚 Documentation Cross-References

- **Architecture**: `ARCHITECTURE.md` - System design and component relationships
- **Agents Guide**: `AGENTS.md` - AI agent operational procedures
- **Complete Optimization**: `.docs/HOMELAB-COMPLETE-OPTIMIZATION.md` - Latest major changes
- **Foundation Strategy**: `.docs/FOUNDATION-FIRST-ORDER.md` - Dependency approach
- **Environment Migration**: `.docs/ENVIRONMENT-FREE-MIGRATION.md` - Configuration simplification

## 🔄 Version History

### v1.0 (2025-08-24)
- Initial logbook system creation at 12:35
- Complete infrastructure optimization documented
- Template and guidelines established
- Timestamped naming convention implemented

---

**Maintainer**: AI Assistant Infrastructure Team  
**Review Schedule**: Monthly  
**Last Updated**: August 24, 2025
