#!/bin/bash
# logbook-helper.sh - Generate timestamped logbook entry template

if [ -z "$1" ]; then
    echo "Usage: ./scripts/logbook-helper.sh 'short-description'"
    echo "Example: ./scripts/logbook-helper.sh 'grafana-dashboard-updates'"
    exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d_%H%M')
DESCRIPTION="$1"
FILENAME=".logbook/${TIMESTAMP}_${DESCRIPTION}.md"

# Create the template
cat > "$FILENAME" << EOF
# ${DESCRIPTION//-/ }

**Date**: $(date '+%Y-%m-%d %H:%M')  
**Type**: [Major Infrastructure | Service Update | Security | Maintenance | Troubleshooting]  
**Impact**: [High | Medium | Low] - Brief impact description  
**Status**: [🔧 In Progress | ✅ Completed | ❌ Failed | 🔄 Partial]  

## Executive Summary

[2-3 sentence overview of what was done]

## Changes Made

### 1. Change Name
- **File**: \`filename\`
- **Change**: Description of modification
- **Rationale**: Why this change was needed
- **Impact**: Effect on system

## System Status After Changes

### Resource Utilization
- **Memory**: Current usage and allocation
- **CPU**: Load and allocation status
- **Services**: Health status overview

### Performance Metrics
- **Startup Time**: Service initialization performance
- **Response Time**: Service availability checks
- **Resource Efficiency**: Utilization vs allocation

## Verification Steps Completed

1. ✅ Step 1 verification
2. ✅ Step 2 verification
3. ✅ Step 3 verification

## Next Steps for Future AI Agents

1. **Action 1**: Description of recommended follow-up
2. **Action 2**: Monitoring or maintenance tasks
3. **Action 3**: Future optimization opportunities

## Rollback Information

- **Configuration Backup**: Location of previous state
- **Critical Commands**: How to undo changes
- **Data Safety**: Backup verification steps
- **Recovery Time**: Expected time to rollback

## Additional Notes

[Any additional context, lessons learned, or special considerations]

---

**Completed by**: AI Assistant / Human  
**Review Required**: [Yes/No] - [Reason if yes]  
**Next Review Date**: [Date for follow-up]  
**Emergency Contact**: Check \`.logbook/README.md\` for procedures
EOF

echo "Created logbook entry: $FILENAME"
echo "Edit the file to complete the documentation."
