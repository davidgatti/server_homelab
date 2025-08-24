# Logbook Quick Reference

## 🚀 For AI Agents

### Before Starting Work
```bash
# Check latest changes
ls -la .logbook/ | tail -5

# Review current system state  
./scripts/homelab-resource-monitor.sh

# Read latest logbook entry
cat .logbook/$(ls .logbook/*.md | tail -1)
```

### Creating New Logbook Entry
```bash
# Use the helper script (recommended):
./scripts/logbook-helper.sh 'short-description'

# Manual naming format:
.logbook/YYYY-MM-DD_HH:MM_short-description.md

# Example:
.logbook/2025-08-24_12:35_homelab-complete-optimization.md
.logbook/2025-09-15_09:30_grafana-dashboard-updates.md
```

### Required Entry Sections
1. **Header**: Date, Type, Impact, Status
2. **Executive Summary**: What was done in 2-3 sentences
3. **Changes Made**: Detailed modifications with files and rationale
4. **System Status**: Current state after changes
5. **Verification Steps**: How to confirm it's working
6. **Next Steps**: Guidance for future AI agents
7. **Rollback Info**: How to undo changes

## 📋 For Humans

### Check System Status
```bash
# Latest infrastructure changes
ls -lt .logbook/*.md | head -3

# Current resource usage
./scripts/homelab-resource-monitor.sh

# Service health
docker compose ps
```

### Find Specific Information
```bash
# Search logbook for specific changes
grep -r "prometheus" .logbook/

# Check resource limit history
grep -r "memory.*limit" .logbook/

# Find troubleshooting info
grep -r "troubleshoot\|rollback\|failed" .logbook/
```

## ⚡ Emergency Reference

### System Not Starting
1. Check latest logbook entry for recent changes
2. Run `docker compose config --quiet` to validate syntax
3. Check resource constraints: `./scripts/homelab-resource-monitor.sh`
4. Look for rollback instructions in relevant logbook entry

### Performance Issues
1. Run resource monitor: `./scripts/homelab-resource-monitor.sh`
2. Check logbook for recent resource limit changes
3. Review foundation-first dependency strategy in latest entries
4. Consider temporary limit adjustments

### Configuration Problems
1. Verify no external dependencies: all config in `compose.yaml`
2. Check logbook for environment-free migration details
3. Validate with `docker compose config --quiet`
4. Use git history for emergency rollback

---
**Last Updated**: August 24, 2025  
**System**: Intel Celeron N3350, 5.6GB RAM, Optimized HomeLab
