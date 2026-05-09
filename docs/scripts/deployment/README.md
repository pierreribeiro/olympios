# Deployment Scripts

## 📁 Directory Purpose

This directory contains **automated deployment scripts** for safely deploying PostgreSQL procedures across environments (DEV → QA → PROD) with rollback capabilities.

**Key Functions:**
- ✅ Single procedure deployment
- ✅ Batch (multiple) deployment
- ✅ Automated rollback
- ✅ Post-deployment validation (smoke tests)
- ✅ Environment-aware deployment

---

## 🎯 Deployment Philosophy

**Safety First, Speed Second**

Deployments must be:
- **Idempotent:** Can run multiple times safely
- **Atomic:** All-or-nothing (no partial deployments)
- **Reversible:** Rollback available within 5 minutes
- **Validated:** Smoke tests run automatically
- **Audited:** All changes logged

---

## 📋 Available Scripts

### 1. deploy-procedure.sh
**Purpose:** Deploy a single procedure to target environment

**Usage:**
```bash
./scripts/deployment/deploy-procedure.sh <procedure_name> <environment>
```

**Examples:**
```bash
# Deploy to DEV (no approval needed)
./scripts/deployment/deploy-procedure.sh reconcilemupstream dev

# Deploy to QA (requires passing tests)
./scripts/deployment/deploy-procedure.sh reconcilemupstream qa

# Deploy to PROD (requires approval + backup)
./scripts/deployment/deploy-procedure.sh reconcilemupstream prod
```

**What It Does:**
1. Validates environment (DEV/QA/PROD)
2. Checks prerequisites (syntax valid, tests passed)
3. Creates backup of existing procedure
4. Applies new version using `CREATE OR REPLACE`
5. Grants necessary permissions
6. Runs smoke test
7. Logs deployment details
8. Sends notification (Slack/Email)

**Exit Codes:**
- `0` = Success
- `1` = Validation failed (pre-deployment)
- `2` = Deployment failed (during execution)
- `3` = Smoke test failed (post-deployment)

---

### 2. deploy-batch.sh
**Purpose:** Deploy multiple procedures in sequence

**Usage:**
```bash
./scripts/deployment/deploy-batch.sh <environment> <procedure_list_file>
```

**Example:**
```bash
# Create deployment list
cat > sprint1-procedures.txt <<EOF
reconcilemupstream
addarc
removearc
EOF

# Deploy all at once
./scripts/deployment/deploy-batch.sh dev sprint1-procedures.txt
```

**Features:**
- Deploys in dependency order (if specified)
- Stops on first failure (fail-fast)
- Optional: Continue on error (`--continue-on-error`)
- Progress tracking (X/N completed)
- Summary report at end

**What It Does:**
1. Reads procedure list
2. Validates all procedures before starting
3. For each procedure:
   - Deploy using `deploy-procedure.sh`
   - Track success/failure
   - Continue or stop based on flags
4. Generate deployment report
5. Send summary notification

---

### 3. rollback-procedure.sh
**Purpose:** Rollback a procedure to previous version

**Usage:**
```bash
./scripts/deployment/rollback-procedure.sh <procedure_name> <environment>
```

**Example:**
```bash
# Something broke in QA - rollback immediately
./scripts/deployment/rollback-procedure.sh reconcilemupstream qa
```

**What It Does:**
1. Locates backup (created during deployment)
2. Verifies backup integrity
3. Replaces current version with backup
4. Grants permissions
5. Runs smoke test on rolled-back version
6. Logs rollback event
7. Sends alert notification

**Rollback Sources (priority order):**
1. Local backup (created by deploy-procedure.sh)
2. Git history (previous commit)
3. Database version history (if tracked)

**Time Limit:** Must complete rollback within **5 minutes**

---

### 4. smoke-test.sh
**Purpose:** Quick post-deployment validation

**Usage:**
```bash
./scripts/deployment/smoke-test.sh <procedure_name> <environment>
```

**What It Tests:**
```sql
-- 1. Procedure exists
SELECT EXISTS(
  SELECT 1 FROM pg_proc WHERE proname = 'procedure_name'
);

-- 2. Can execute (with test data)
SELECT * FROM procedure_name(test_param1, test_param2);

-- 3. Returns expected result structure
-- 4. No errors in execution
-- 5. Execution time reasonable (< 10x normal)
```

**Pass Criteria:**
- ✅ Procedure exists in target schema
- ✅ Can be called without errors
- ✅ Returns expected data structure
- ✅ Execution time < 10 seconds (configurable)
- ✅ No PostgreSQL errors/warnings

**Example Output:**
```
===========================================
SMOKE TEST: reconcilemupstream @ DEV
===========================================
✅ Procedure exists
✅ Can execute (test data)
✅ Returns correct structure
✅ Execution time: 0.85s (OK)
✅ No errors detected
===========================================
RESULT: ✅ PASS
===========================================
```

---

## 🔧 Configuration Files

### deployment-config.json
Environment-specific settings:
```json
{
  "environments": {
    "dev": {
      "host": "dev-postgres.internal",
      "database": "perseus_dev",
      "require_approval": false,
      "backup_retention_days": 7,
      "notification_channel": "#dev-deploys"
    },
    "qa": {
      "host": "qa-postgres.internal",
      "database": "perseus_qa",
      "require_approval": true,
      "backup_retention_days": 30,
      "notification_channel": "#qa-deploys"
    },
    "prod": {
      "host": "prod-postgres.internal",
      "database": "perseus_prod",
      "require_approval": true,
      "require_backup": true,
      "backup_retention_days": 90,
      "notification_channel": "#prod-deploys",
      "maintenance_window": "02:00-04:00 UTC"
    }
  },
  "deployment": {
    "max_concurrent": 1,
    "rollback_timeout_seconds": 300,
    "smoke_test_timeout_seconds": 60
  }
}
```

---

## 🎯 Deployment Gates by Environment

### DEV Environment
- ✅ Syntax check passed
- ✅ Unit tests passed (optional)
- ❌ No approval required
- ❌ No backup required
- 🚀 Deploy anytime

### QA Environment
- ✅ Syntax check passed
- ✅ All tests passed (unit + integration)
- ✅ Deployed successfully to DEV
- ✅ Peer review approved
- ⚠️ Approval required (DBA or Tech Lead)
- ✅ Backup created
- 🚀 Deploy during business hours

### PROD Environment
- ✅ ALL QA gates passed
- ✅ Performance test passed (≤120% baseline)
- ✅ Change Control ticket approved
- ✅ Stakeholder sign-off
- ✅ Runbook prepared
- ✅ Rollback plan documented
- ✅ Backup verified
- ✅ Monitoring configured
- 🚀 Deploy during maintenance window only

---

## 🚀 Deployment Workflow

```
┌─────────────────┐
│  Validated      │
│  Procedure      │
└────────┬────────┘
         │
         ├─> DEV  ──┐
         │          │ smoke test
         │          ▼
         │       ✅ PASS ──> Continue
         │
         ├─> QA   ──┐
         │          │ integration test
         │          ▼
         │       ✅ PASS ──> Approval
         │
         └─> PROD ──┐
                    │ final validation
                    ▼
                 🎉 DEPLOYED
                    │
                    └─> Monitor (24h)
```

---

## 📊 Deployment Tracking

### Deployment Log Format
```
===========================================
DEPLOYMENT LOG
===========================================
Timestamp: 2025-11-13 14:30:00 UTC
Procedure: reconcilemupstream
Environment: QA
Version: 1.2.3
Deployed By: pierre.ribeiro@dinamotech.com
Commit SHA: abc123def456
Backup: /backups/reconcilemupstream_20251113_143000.sql
Smoke Test: ✅ PASS
Duration: 45 seconds
Status: ✅ SUCCESS
===========================================
```

### Deployment Metrics
Track for each procedure:
- **Deployment Count:** How many times deployed
- **Success Rate:** % successful deployments
- **Average Duration:** Time per deployment
- **Rollback Count:** How many times rolled back
- **MTTR:** Mean Time To Rollback

---

## 🛡️ Safety Mechanisms

### 1. Pre-Deployment Checks
```bash
# Example checks before deployment
if [ "$ENV" == "prod" ]; then
  # Check maintenance window
  current_hour=$(date +%H)
  if [ $current_hour -lt 2 ] || [ $current_hour -gt 4 ]; then
    echo "ERROR: Outside maintenance window"
    exit 1
  fi
  
  # Verify approval ticket
  if ! check_approval_ticket "$TICKET_ID"; then
    echo "ERROR: No approval ticket"
    exit 1
  fi
  
  # Confirm backup exists
  if ! verify_backup "$PROCEDURE"; then
    echo "ERROR: Backup verification failed"
    exit 1
  fi
fi
```

### 2. Atomic Deployment
```sql
-- All changes in transaction
BEGIN;

  -- Create new version
  CREATE OR REPLACE FUNCTION ...;
  
  -- Update permissions
  GRANT EXECUTE ON FUNCTION ...;
  
  -- Update metadata
  INSERT INTO deployment_log ...;
  
  -- Verify
  SELECT * FROM procedure_name(test_data);

COMMIT;  -- or ROLLBACK if any step fails
```

### 3. Automatic Rollback
```bash
# Deploy with auto-rollback on failure
./deploy-procedure.sh reconcilemupstream qa || {
  echo "Deployment failed - auto-rollback triggered"
  ./rollback-procedure.sh reconcilemupstream qa
  exit 1
}
```

---

## 🚨 Emergency Procedures

### Fast Rollback (< 2 minutes)
```bash
# Emergency rollback (no validation)
./scripts/deployment/rollback-procedure.sh reconcilemupstream prod --emergency

# Disables smoke test
# Uses cached backup
# Skips approval process
# Immediate execution
```

### Disable Procedure (< 30 seconds)
```sql
-- Emergency disable (rename)
ALTER FUNCTION reconcilemupstream 
RENAME TO reconcilemupstream_disabled_20251113;

-- Or revoke permissions
REVOKE EXECUTE ON FUNCTION reconcilemupstream FROM PUBLIC;
```

### Enable Monitoring Alert
```bash
# Automatically create alert for new deployment
./scripts/deployment/create-alert.sh reconcilemupstream prod
```

---

## 📚 Related Documentation

- Validation scripts: `/scripts/validation/`
- Runbooks: `/docs/runbooks/`
- Smoke tests: `/tests/smoke/`
- Monitoring: `/docs/monitoring.md`
- Rollback procedures: `/docs/rollback-guide.md`

---

## 🔗 Integration Points

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
- name: Deploy to DEV
  run: ./scripts/deployment/deploy-procedure.sh ${{ env.PROCEDURE }} dev
  
- name: Deploy to QA
  if: env.ENVIRONMENT == 'qa'
  run: ./scripts/deployment/deploy-procedure.sh ${{ env.PROCEDURE }} qa
```

### Notification Integration
```bash
# Slack notification on deployment
send_slack_notification() {
  curl -X POST $SLACK_WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{
      \"text\": \"Deployed ${PROCEDURE} to ${ENV}\",
      \"status\": \"${STATUS}\"
    }"
}
```

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
