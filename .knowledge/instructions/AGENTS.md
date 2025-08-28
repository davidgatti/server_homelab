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

- **Before committing infrastructure changes**:
  - Test full restart: `./homelab.sh restart`
  - Verify all services accessible via assigned IPs
  - Check monitoring targets in Prometheus
  - Ensure configuration files are properly mounted
  - Validate resource usage is within limits

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
