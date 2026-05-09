# 🎯 SPRINT 9 EXECUTION PLAN - Integration & Staging
## Phase 3: End-to-End Validation - Perseus Migration

**Sprint:** Sprint 9 (Integration & Staging)  
**Duration:** 1 week (40 hours)  
**Start Date:** 2025-12-02 (Monday)  
**End Date:** 2025-12-06 (Friday)  
**Project:** SQL Server → PostgreSQL Migration - Perseus Database  
**Lead:** Pierre Ribeiro (Senior DBA/DBRE)

---

## 📋 EXECUTION RESPONSIBILITY MATRIX

### 🎭 Executor Roles

| Executor | Symbol | Responsibilities | Environment |
|----------|--------|------------------|-------------|
| **Pierre (Manual)** | 👤 | Infrastructure ops, approvals, stakeholder comm, manual validations | Multiple |
| **Claude Desktop** | 🧠 | Strategic analysis, documentation, planning, review, tracking | Desktop (Command Center) |
| **Claude Code** | ⚙️ | Code execution, testing, deployment scripts, validation scripts | VSCode (Hands) |

### Task Format

```
[EXECUTOR] Task Description
├─ Subtask 1
├─ Subtask 2
└─ Deliverable: What is produced
⏱️ Time: X hours | 🚨 Blocker Risk: LOW/MEDIUM/HIGH
```

---

## 🗓️ SPRINT 9 TIMELINE - DAY BY DAY

```
Mon 12/02: [DAY 1] Pre-Integration Setup (8h)
Tue 12/03: [DAY 2] Unit Testing - Part 1 (8h)
Wed 12/04: [DAY 3] Unit Testing - Part 2 (8h)
Thu 12/05: [DAY 4] Integration Testing (8h)
Fri 12/06: [DAY 5] Security & Documentation Review (8h)
```

---

## 📅 DAY 1: PRE-INTEGRATION SETUP (Monday 12/02)

**Goal:** STAGING environment ready with all 15 procedures deployed and monitoring active  
**Total Time:** 8 hours

---

### PHASE 1.1: STAGING Environment Verification (2h)

#### [👤 PIERRE] Task 1.1.1: Validate STAGING Infrastructure
```
Connect to STAGING PostgreSQL and validate environment readiness
├─ SSH/VPN into STAGING environment
├─ Verify PostgreSQL 16 is running
├─ Check database "perseus" exists and is accessible
├─ Validate disk space (minimum 50GB free)
├─ Check CPU/RAM allocation (minimum 4 cores, 16GB RAM)
└─ Deliverable: Environment validation checklist completed

⏱️ Time: 0.5 hours
🚨 Blocker Risk: HIGH (Sprint cannot proceed without STAGING)
📍 Checkpoint: STAGING accessible and healthy
```

#### [⚙️ CLAUDE CODE] Task 1.1.2: Extension & Dependency Check
```
Run validation script to check all PostgreSQL extensions and functions
├─ Create validation script: scripts/validation/staging-dependency-check.sh
├─ Check extensions: postgres_fdw, plpgsql, pg_stat_statements
├─ Verify functions exist: McGetUpStreamByList, GetTreeList, GetBothParents
├─ Verify views exist: (list from dependency analysis)
├─ Check external DB connections (Argus via postgres_fdw)
└─ Deliverable: Dependency validation report (dependencies-staging-status.md)

⏱️ Time: 1.0 hours
🚨 Blocker Risk: MEDIUM (missing dependencies delay testing)
📍 Checkpoint: All dependencies present or documented as missing
```

**Handoff:** Code → Desktop (validation report)

#### [🧠 CLAUDE DESKTOP] Task 1.1.3: Analyze Dependency Report
```
Review dependency validation report and create action plan
├─ Analyze dependencies-staging-status.md
├─ Identify missing functions/views
├─ Categorize as P0 (critical blockers) or P1 (can workaround)
├─ Create installation instructions for missing items
└─ Deliverable: dependency-action-plan.md with priorities

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (planning task)
📍 Checkpoint: Action plan for missing dependencies ready
```

**Handoff:** Desktop → Pierre (action plan)

---

### PHASE 1.2: Procedure Deployment (3h)

#### [👤 PIERRE] Task 1.2.1: Install Missing Dependencies
```
Execute installation commands for missing dependencies identified in action plan
├─ Install missing functions (if any)
├─ Install missing views (if any)
├─ Configure postgres_fdw for Argus connection
├─ Grant necessary permissions
└─ Deliverable: All dependencies installed and accessible

⏱️ Time: 1.0 hours
🚨 Blocker Risk: MEDIUM (may require coordination with other teams)
📍 Checkpoint: All P0 dependencies installed
```

#### [⚙️ CLAUDE CODE] Task 1.2.2: Prepare Deployment Package
```
Create deployment package with all 15 procedures in correct order
├─ Analyze procedure dependencies (caller → callee relationships)
├─ Create deployment order list (dependency-first)
├─ Generate deployment script: scripts/deployment/deploy-all-staging.sh
├─ Include rollback script: scripts/deployment/rollback-all-staging.sh
├─ Add syntax validation pre-check
└─ Deliverable: Deployment package ready (deploy-all-staging.sh)

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW (preparation task)
📍 Checkpoint: Deployment script validated locally
```

**Handoff:** Code → Pierre (deployment script)

#### [👤 PIERRE] Task 1.2.3: Execute Deployment to STAGING
```
Run deployment script and monitor for errors
├─ Review deployment script: deploy-all-staging.sh
├─ Execute deployment: bash scripts/deployment/deploy-all-staging.sh
├─ Monitor deployment logs for errors
├─ Verify all 15 procedures created successfully
├─ Test basic connectivity (SELECT from procedures)
└─ Deliverable: All 15 procedures deployed to STAGING

⏱️ Time: 0.5 hours
🚨 Blocker Risk: MEDIUM (deployment may fail)
📍 Checkpoint: All procedures exist in STAGING database
```

#### [⚙️ CLAUDE CODE] Task 1.2.4: Post-Deployment Validation
```
Run automated validation suite to confirm deployment success
├─ Create validation script: scripts/validation/post-deployment-check.sh
├─ Verify all 15 procedures exist (pg_proc query)
├─ Check procedure signatures match expected
├─ Run basic smoke test (call each procedure with minimal args)
├─ Generate validation report
└─ Deliverable: deployment-validation-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (validation task)
📍 Checkpoint: Deployment confirmed successful
```

**Handoff:** Code → Desktop (validation report)

---

### PHASE 1.3: Monitoring Setup (3h)

#### [👤 PIERRE] Task 1.3.1: Configure PostgreSQL Logging
```
Enable comprehensive logging for STAGING database
├─ Edit postgresql.conf: log_statement = 'all'
├─ Set log_min_duration_statement = 5000 (log queries >5s)
├─ Enable log_line_prefix with timestamp, user, database
├─ Configure log rotation (daily, keep 7 days)
├─ Reload PostgreSQL configuration
└─ Deliverable: Logging configured and active

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (can test without logging if needed)
📍 Checkpoint: PostgreSQL logs capturing procedure executions
```

#### [⚙️ CLAUDE CODE] Task 1.3.2: Create Monitoring Dashboards
```
Generate Grafana dashboard configuration for procedure monitoring
├─ Create Grafana dashboard JSON: monitoring/grafana-perseus-dashboard.json
├─ Define metrics:
│   ├─ Procedure execution count (per procedure)
│   ├─ Execution duration (avg, p95, p99)
│   ├─ Error rate (per procedure)
│   └─ Concurrent executions
├─ Add alert rules (execution >30s, error rate >5%)
├─ Generate documentation: monitoring/dashboard-setup-guide.md
└─ Deliverable: Grafana dashboard config + setup guide

⏱️ Time: 1.5 hours
🚨 Blocker Risk: LOW (monitoring is nice-to-have for Day 1)
📍 Checkpoint: Dashboard config ready for import
```

**Handoff:** Code → Pierre (dashboard config)

#### [👤 PIERRE] Task 1.3.3: Import Monitoring Dashboards
```
Import Grafana dashboard and validate metrics
├─ Access Grafana UI for STAGING
├─ Import dashboard: monitoring/grafana-perseus-dashboard.json
├─ Configure data source (PostgreSQL STAGING)
├─ Validate metrics are populating
├─ Set up alert notification channels
└─ Deliverable: Monitoring dashboards live and functional

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (can monitor manually if Grafana fails)
📍 Checkpoint: Real-time monitoring active
```

#### [🧠 CLAUDE DESKTOP] Task 1.3.4: Day 1 Status Report
```
Generate comprehensive Day 1 completion report
├─ Consolidate all validation reports (dependencies, deployment, monitoring)
├─ Document any issues encountered and resolutions
├─ Assess readiness for Day 2 (unit testing)
├─ Identify any remaining blockers
├─ Update progress-tracker.md with Day 1 completion
└─ Deliverable: day1-completion-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (documentation task)
📍 Checkpoint: Day 1 complete, ready for Day 2
```

**End of Day 1 Deliverables:**
- ✅ STAGING environment validated
- ✅ All dependencies installed
- ✅ All 15 procedures deployed
- ✅ Monitoring active
- ✅ Day 1 status report

---

## 📅 DAY 2: UNIT TESTING - PART 1 (Tuesday 12/03)

**Goal:** Execute first batch of unit tests (7-8 procedures) and document results  
**Total Time:** 8 hours

---

### PHASE 2.1: Test Suite Preparation (1.5h)

#### [🧠 CLAUDE DESKTOP] Task 2.1.1: Test Execution Plan
```
Create detailed test execution plan with priorities
├─ Review all test files: tests/unit/test_*.sql
├─ Categorize tests by procedure priority (P1 → P2 → P3)
├─ Identify test dependencies (which tests must run first)
├─ Estimate execution time per test
├─ Create test execution order
└─ Deliverable: test-execution-plan.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (planning task)
📍 Checkpoint: Test execution order defined
```

#### [⚙️ CLAUDE CODE] Task 2.1.2: Test Runner Script
```
Create automated test runner with result aggregation
├─ Create script: scripts/testing/run-unit-tests.sh
├─ Features:
│   ├─ Execute tests in specified order
│   ├─ Capture test output (PASS/FAIL)
│   ├─ Measure execution time per test
│   ├─ Generate summary report
│   └─ Continue on failure (don't stop at first fail)
├─ Add logging to file: test-results-YYYYMMDD-HHMMSS.log
└─ Deliverable: Automated test runner (run-unit-tests.sh)

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW (can run tests manually if script fails)
📍 Checkpoint: Test runner ready for execution
```

**Handoff:** Code → Pierre (test runner script)

---

### PHASE 2.2: Execute Batch 1 Tests (P1 Procedures - 3h)

#### [👤 PIERRE] Task 2.2.1: Execute P1 Procedure Tests
```
Run unit tests for all 6 P1 procedures using test runner
├─ Execute: bash scripts/testing/run-unit-tests.sh --batch P1
├─ Monitor test execution in real-time
├─ Note any test failures or unexpected behavior
├─ Tests to run:
│   ├─ test_usp_UpdateMUpstream.sql (3 scenarios)
│   ├─ test_ReconcileMUpstream.sql (10 scenarios)
│   ├─ test_ProcessSomeMUpstream.sql (5 scenarios)
│   ├─ test_usp_UpdateMDownstream.sql (4 scenarios)
│   ├─ test_AddArc.sql (4 scenarios)
│   ├─ test_RemoveArc.sql (3 scenarios)
│   └─ test_ProcessDirtyTrees.sql (8 scenarios)
└─ Deliverable: Raw test execution logs

⏱️ Time: 1.5 hours
🚨 Blocker Risk: MEDIUM (test failures may require investigation)
📍 Checkpoint: All P1 tests executed (pass or fail)
```

#### [⚙️ CLAUDE CODE] Task 2.2.2: Analyze P1 Test Results
```
Parse test logs and generate detailed analysis report
├─ Parse test-results log file
├─ Extract PASS/FAIL counts per procedure
├─ Identify failed test scenarios (if any)
├─ Categorize failures:
│   ├─ P0: Critical blockers (procedure doesn't work)
│   ├─ P1: Data integrity issues
│   └─ P2: Minor discrepancies
├─ For each failure, extract:
│   ├─ Expected vs Actual output
│   ├─ Error message
│   └─ Execution time
└─ Deliverable: p1-test-analysis-report.md

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW (analysis task)
📍 Checkpoint: P1 test results documented
```

**Handoff:** Code → Desktop (analysis report)

#### [🧠 CLAUDE DESKTOP] Task 2.2.3: P1 Failure Triage
```
Review P1 test failures and create fix instructions
├─ Review p1-test-analysis-report.md
├─ For each P0/P1 failure:
│   ├─ Determine root cause (code bug, test bug, data issue)
│   ├─ Create fix instructions for Claude Code
│   └─ Estimate fix complexity
├─ Prioritize fixes (P0 first, then P1)
├─ If no P0 failures: approve to proceed to P2 tests
└─ Deliverable: p1-fix-instructions.md (if failures) OR approval to proceed

⏱️ Time: 0.5 hours
🚨 Blocker Risk: MEDIUM (P0 failures block progress)
📍 Checkpoint: P1 failures triaged and prioritized
```

**Decision Point:** IF P0 failures exist, PAUSE and fix before Day 3. ELSE proceed to Phase 2.3.

---

### PHASE 2.3: Execute Batch 2 Tests (P2 Procedures - 3h)

#### [👤 PIERRE] Task 2.3.1: Execute P2 Procedure Tests
```
Run unit tests for P2 procedures (if P1 passed or no P0 blockers)
├─ Execute: bash scripts/testing/run-unit-tests.sh --batch P2
├─ Monitor test execution
├─ Tests to run:
│   ├─ test_TransitionToMaterial.sql (3 scenarios)
│   ├─ test_sp_move_node.sql (4 scenarios)
│   └─ test_MaterialToTransition.sql (3 scenarios)
└─ Deliverable: Raw test execution logs for P2

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW (P2 are simpler procedures)
📍 Checkpoint: All P2 tests executed
```

#### [⚙️ CLAUDE CODE] Task 2.3.2: Analyze P2 Test Results
```
Parse P2 test logs and generate analysis report
├─ Same process as Task 2.2.2 but for P2 procedures
└─ Deliverable: p2-test-analysis-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: P2 test results documented
```

**Handoff:** Code → Desktop (P2 analysis report)

#### [🧠 CLAUDE DESKTOP] Task 2.3.3: P2 Failure Triage
```
Review P2 test failures and create fix instructions
├─ Same process as Task 2.2.3 but for P2 procedures
└─ Deliverable: p2-fix-instructions.md (if failures) OR approval

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: P2 failures triaged
```

#### [🧠 CLAUDE DESKTOP] Task 2.3.4: Day 2 Status Report
```
Generate Day 2 completion report
├─ Consolidate P1 and P2 test results
├─ Calculate pass rate (target: >95%)
├─ Document any blockers for Day 3
├─ Update progress-tracker.md
└─ Deliverable: day2-completion-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Day 2 complete
```

**End of Day 2 Deliverables:**
- ✅ Test runner script created
- ✅ P1 tests executed (6 procedures, ~37 scenarios)
- ✅ P2 tests executed (3 procedures, ~10 scenarios)
- ✅ Test failure analysis complete
- ✅ Fix instructions created (if needed)
- ✅ Day 2 status report

---

## 📅 DAY 3: UNIT TESTING - PART 2 (Wednesday 12/04)

**Goal:** Complete remaining unit tests (P3), fix any P0/P1 failures from Day 2, performance validation  
**Total Time:** 8 hours

---

### PHASE 3.1: Fix P0/P1 Failures (If Any - 2-4h)

**CONDITIONAL:** Only execute if P0 or P1 failures identified on Day 2

#### [⚙️ CLAUDE CODE] Task 3.1.1: Implement Fixes
```
Implement fixes based on Desktop's fix instructions
├─ Review fix-instructions.md from Day 2
├─ For each P0/P1 failure:
│   ├─ Analyze procedure code
│   ├─ Implement fix
│   ├─ Test fix locally
│   └─ Commit fix to repository
├─ Generate fix summary report
└─ Deliverable: Fixed procedures + fix-summary.md

⏱️ Time: 2-3 hours (depends on failure count)
🚨 Blocker Risk: HIGH (P0 failures must be fixed)
📍 Checkpoint: All P0 failures resolved
```

**Handoff:** Code → Pierre (fixed procedures)

#### [👤 PIERRE] Task 3.1.2: Redeploy Fixed Procedures
```
Deploy fixed procedures to STAGING and retest
├─ Deploy fixed procedures: bash scripts/deployment/deploy-procedure.sh {name}
├─ Rerun failed tests: bash scripts/testing/run-unit-tests.sh --retest-failed
├─ Verify all previously failed tests now pass
└─ Deliverable: Retest results

⏱️ Time: 0.5-1.0 hours
🚨 Blocker Risk: MEDIUM
📍 Checkpoint: All P0/P1 failures resolved
```

---

### PHASE 3.2: Execute Batch 3 Tests (P3 Procedures - 1.5h)

#### [👤 PIERRE] Task 3.2.1: Execute P3 Procedure Tests
```
Run unit tests for all P3 procedures
├─ Execute: bash scripts/testing/run-unit-tests.sh --batch P3
├─ Tests to run:
│   ├─ test_usp_UpdateContainerTypeFromArgus.sql (3 scenarios)
│   ├─ test_LinkUnlinkedMaterials.sql (4 scenarios)
│   ├─ test_MoveContainer.sql (3 scenarios)
│   └─ test_MoveGooType.sql (3 scenarios)
└─ Deliverable: Raw test execution logs for P3

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: All P3 tests executed
```

#### [⚙️ CLAUDE CODE] Task 3.2.2: Analyze P3 Test Results
```
Parse P3 test logs and generate analysis report
├─ Same process as previous analysis tasks
└─ Deliverable: p3-test-analysis-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: P3 test results documented
```

---

### PHASE 3.3: Performance Validation (3h)

#### [⚙️ CLAUDE CODE] Task 3.3.1: Performance Benchmark Suite
```
Create performance benchmarking scripts for all 15 procedures
├─ Create script: scripts/testing/benchmark-procedures.sh
├─ For each procedure:
│   ├─ Execute with realistic data volume
│   ├─ Measure execution time (5 runs, take median)
│   ├─ Record CPU and memory usage
│   └─ Compare against SQL Server baseline (if available)
├─ Generate performance report
└─ Deliverable: Performance benchmark suite + baseline report

⏱️ Time: 1.5 hours
🚨 Blocker Risk: LOW (performance is measured, not blocking)
📍 Checkpoint: Performance benchmarks ready
```

**Handoff:** Code → Pierre (benchmark script)

#### [👤 PIERRE] Task 3.3.2: Execute Performance Benchmarks
```
Run performance benchmarks on STAGING
├─ Execute: bash scripts/testing/benchmark-procedures.sh
├─ Monitor system resources during benchmarks
├─ Note any procedures with execution time >30s
└─ Deliverable: Raw benchmark results

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Performance data collected
```

#### [🧠 CLAUDE DESKTOP] Task 3.3.3: Performance Analysis
```
Analyze benchmark results and identify optimization opportunities
├─ Review benchmark results
├─ Compare against target (±20% of SQL Server baseline)
├─ Identify procedures exceeding target
├─ Categorize performance issues:
│   ├─ P0: Critical (>50% slower than baseline)
│   ├─ P1: Moderate (20-50% slower)
│   └─ P2: Minor (<20% variance)
├─ For each issue, suggest optimization
└─ Deliverable: performance-analysis-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (optimizations can be post-Sprint 9)
📍 Checkpoint: Performance bottlenecks identified
```

---

### PHASE 3.4: Data Integrity Validation (2h)

#### [⚙️ CLAUDE CODE] Task 3.4.1: Data Integrity Test Suite
```
Create data integrity validation scripts
├─ Create script: scripts/validation/data-integrity-check.sql
├─ Checks to implement:
│   ├─ Temp table cleanup (no orphaned temp tables)
│   ├─ Referential integrity (foreign keys valid)
│   ├─ Data consistency (no NULL in NOT NULL columns)
│   ├─ Duplicate detection (unique constraints honored)
│   └─ Orphaned record check (dangling references)
├─ Generate integrity report
└─ Deliverable: Data integrity test suite

⏱️ Time: 1.0 hours
🚨 Blocker Risk: MEDIUM (data corruption is serious)
📍 Checkpoint: Integrity tests ready
```

**Handoff:** Code → Pierre (integrity test script)

#### [👤 PIERRE] Task 3.4.2: Execute Data Integrity Tests
```
Run data integrity validation on STAGING
├─ Execute: psql -f scripts/validation/data-integrity-check.sql
├─ Review integrity report for violations
├─ Document any data issues found
└─ Deliverable: Data integrity results

⏱️ Time: 0.5 hours
🚨 Blocker Risk: MEDIUM (integrity issues may require fixes)
📍 Checkpoint: Data integrity validated
```

#### [🧠 CLAUDE DESKTOP] Task 3.4.3: Day 3 Status Report
```
Generate Day 3 completion report
├─ Consolidate all test results (unit + performance + integrity)
├─ Calculate overall test pass rate
├─ Document remaining issues
├─ Assess readiness for Day 4 (integration testing)
├─ Update progress-tracker.md
└─ Deliverable: day3-completion-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Day 3 complete
```

**End of Day 3 Deliverables:**
- ✅ All P0/P1 failures fixed (if any)
- ✅ All P3 tests executed
- ✅ Performance benchmarks complete
- ✅ Data integrity validated
- ✅ Day 3 status report

---

## 📅 DAY 4: INTEGRATION TESTING (Thursday 12/05)

**Goal:** Validate end-to-end workflows and procedure interactions  
**Total Time:** 8 hours

---

### PHASE 4.1: Integration Test Planning (1h)

#### [🧠 CLAUDE DESKTOP] Task 4.1.1: Workflow Mapping
```
Map all critical procedure workflows and dependencies
├─ Identify workflow chains:
│   ├─ ProcessDirtyTrees → ProcessSomeMUpstream → ReconcileMUpstream
│   ├─ AddArc / RemoveArc operations
│   ├─ MaterialToTransition ↔ TransitionToMaterial
│   └─ Container movement workflows
├─ Document data flow between procedures
├─ Identify integration points (shared temp tables, etc.)
└─ Deliverable: workflow-integration-map.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Workflows documented
```

#### [⚙️ CLAUDE CODE] Task 4.1.2: Integration Test Suite
```
Create integration test scripts for each workflow
├─ Create script: scripts/testing/run-integration-tests.sh
├─ Tests to create:
│   ├─ test_workflow_dirty_trees.sql (coordinator pattern)
│   ├─ test_workflow_arc_operations.sql (add/remove cycle)
│   ├─ test_workflow_material_transitions.sql (bidirectional)
│   ├─ test_workflow_container_movements.sql
│   └─ test_workflow_external_systems.sql (Argus integration)
├─ Each test validates:
│   ├─ Procedure A passes data correctly to Procedure B
│   ├─ Transaction boundaries work correctly
│   └─ Error propagation works as expected
└─ Deliverable: Integration test suite

⏱️ Time: 1.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Integration tests ready
```

---

### PHASE 4.2: Execute Workflow Tests (3h)

#### [👤 PIERRE] Task 4.2.1: Execute Integration Tests - Batch 1
```
Run integration tests for coordinator pattern workflows
├─ Execute: bash scripts/testing/run-integration-tests.sh --workflow dirty_trees
├─ Test scenarios:
│   ├─ ProcessDirtyTrees calls ProcessSomeMUpstream correctly
│   ├─ ProcessSomeMUpstream calls ReconcileMUpstream correctly
│   ├─ Data flows correctly through refcursor pattern
│   └─ WHILE loop termination works (4-second timeout)
└─ Deliverable: Integration test results - Batch 1

⏱️ Time: 1.0 hours
🚨 Blocker Risk: HIGH (coordinator pattern is critical)
📍 Checkpoint: Coordinator pattern validated
```

#### [👤 PIERRE] Task 4.2.2: Execute Integration Tests - Batch 2
```
Run integration tests for arc and material workflows
├─ Execute arc operations workflow test
├─ Execute material transitions workflow test
└─ Deliverable: Integration test results - Batch 2

⏱️ Time: 1.0 hours
🚨 Blocker Risk: MEDIUM
📍 Checkpoint: Arc and material workflows validated
```

#### [👤 PIERRE] Task 4.2.3: Execute Integration Tests - Batch 3
```
Run integration tests for container and external system workflows
├─ Execute container movements workflow test
├─ Execute Argus integration test (postgres_fdw)
└─ Deliverable: Integration test results - Batch 3

⏱️ Time: 1.0 hours
🚨 Blocker Risk: MEDIUM (Argus dependency)
📍 Checkpoint: All workflows tested
```

---

### PHASE 4.3: Concurrent Execution Testing (2h)

#### [⚙️ CLAUDE CODE] Task 4.3.1: Concurrency Test Suite
```
Create concurrent execution test scripts
├─ Create script: scripts/testing/test-concurrency.sh
├─ Test scenarios:
│   ├─ Multiple instances of same procedure simultaneously
│   ├─ Different procedures accessing same tables
│   ├─ Lock contention detection
│   └─ Deadlock scenario testing
├─ Use pgbench or custom multi-connection script
└─ Deliverable: Concurrency test suite

⏱️ Time: 1.0 hours
🚨 Blocker Risk: LOW (concurrency issues can be addressed later)
📍 Checkpoint: Concurrency tests ready
```

**Handoff:** Code → Pierre (concurrency test script)

#### [👤 PIERRE] Task 4.3.2: Execute Concurrency Tests
```
Run concurrent execution tests on STAGING
├─ Execute: bash scripts/testing/test-concurrency.sh
├─ Monitor for:
│   ├─ Lock wait events
│   ├─ Deadlocks
│   ├─ Performance degradation
│   └─ Transaction conflicts
└─ Deliverable: Concurrency test results

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Concurrency behavior documented
```

#### [🧠 CLAUDE DESKTOP] Task 4.3.3: Concurrency Analysis
```
Analyze concurrency test results and recommend improvements
├─ Review concurrency test results
├─ Identify deadlock scenarios
├─ Recommend locking strategy improvements
├─ Document safe concurrency limits
└─ Deliverable: concurrency-analysis-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Concurrency risks documented
```

---

### PHASE 4.4: Failure Scenario Testing (1.5h)

#### [⚙️ CLAUDE CODE] Task 4.4.1: Failure Test Suite
```
Create failure scenario test scripts
├─ Create script: scripts/testing/test-failure-scenarios.sh
├─ Test scenarios:
│   ├─ Network timeout (simulate with pg_sleep)
│   ├─ Transaction rollback on error
│   ├─ Invalid input data
│   ├─ Missing dependencies (function not found)
│   └─ Disk full scenario (if safe to test)
└─ Deliverable: Failure test suite

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Failure tests ready
```

#### [👤 PIERRE] Task 4.4.2: Execute Failure Tests
```
Run failure scenario tests on STAGING
├─ Execute: bash scripts/testing/test-failure-scenarios.sh
├─ Verify graceful error handling
├─ Confirm transaction rollback works
├─ Check error messages are informative
└─ Deliverable: Failure test results

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW (failure handling is defensive)
📍 Checkpoint: Failure scenarios tested
```

#### [🧠 CLAUDE DESKTOP] Task 4.4.3: Day 4 Status Report
```
Generate Day 4 completion report
├─ Consolidate all integration test results
├─ Calculate integration test pass rate
├─ Document any workflow issues
├─ Assess readiness for Day 5 (security & docs)
├─ Update progress-tracker.md
└─ Deliverable: day4-completion-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Day 4 complete
```

**End of Day 4 Deliverables:**
- ✅ Workflow integration tests complete
- ✅ Concurrency testing complete
- ✅ Failure scenario testing complete
- ✅ Integration issues documented
- ✅ Day 4 status report

---

## 📅 DAY 5: SECURITY & DOCUMENTATION REVIEW (Friday 12/06)

**Goal:** Security validation, documentation finalization, Sprint 9 retrospective  
**Total Time:** 8 hours

---

### PHASE 5.1: Security Review (3h)

#### [⚙️ CLAUDE CODE] Task 5.1.1: Security Audit Script
```
Create comprehensive security audit script
├─ Create script: scripts/security/audit-procedures.sh
├─ Checks to implement:
│   ├─ Permissions audit (EXECUTE grants)
│   ├─ SQL injection vulnerability scan
│   ├─ Dynamic SQL usage review
│   ├─ Input validation check
│   ├─ RAISE level appropriateness (no sensitive data in logs)
│   └─ Transaction isolation level validation
├─ Generate security audit report
└─ Deliverable: Security audit script + initial report

⏱️ Time: 1.5 hours
🚨 Blocker Risk: MEDIUM (security issues must be fixed)
📍 Checkpoint: Security audit ready
```

**Handoff:** Code → Pierre (audit script)

#### [👤 PIERRE] Task 5.1.2: Execute Security Audit
```
Run security audit on STAGING
├─ Execute: bash scripts/security/audit-procedures.sh
├─ Review audit report for security issues
├─ Categorize issues as P0/P1/P2
└─ Deliverable: Security audit results

⏱️ Time: 0.5 hours
🚨 Blocker Risk: MEDIUM
📍 Checkpoint: Security status assessed
```

#### [🧠 CLAUDE DESKTOP] Task 5.1.3: Security Issue Triage
```
Review security audit and create remediation plan
├─ Review security audit results
├─ For each P0/P1 issue:
│   ├─ Document risk level
│   ├─ Create fix instructions
│   └─ Estimate fix effort
├─ Prioritize remediations
└─ Deliverable: security-remediation-plan.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: HIGH (P0 security issues block production)
📍 Checkpoint: Security issues triaged
```

#### [⚙️ CLAUDE CODE] Task 5.1.4: Implement Security Fixes
```
Implement P0/P1 security fixes
├─ Review security-remediation-plan.md
├─ Implement fixes for P0 issues
├─ Implement fixes for P1 issues (if time permits)
├─ Rerun security audit to verify fixes
└─ Deliverable: Security-hardened procedures

⏱️ Time: 0.5 hours
🚨 Blocker Risk: HIGH (P0 must be fixed)
📍 Checkpoint: Critical security issues resolved
```

---

### PHASE 5.2: Documentation Finalization (3h)

#### [🧠 CLAUDE DESKTOP] Task 5.2.1: Operational Runbooks
```
Create comprehensive operational runbooks for all 15 procedures
├─ For each procedure, document:
│   ├─ Purpose and business logic
│   ├─ Input parameters and expected values
│   ├─ Expected execution time
│   ├─ Common error scenarios and resolutions
│   ├─ Monitoring queries
│   └─ Troubleshooting guide
├─ Create master runbook index
└─ Deliverable: docs/runbooks/ directory with 15 runbooks + index

⏱️ Time: 2.0 hours
🚨 Blocker Risk: LOW (docs can be refined post-Sprint 9)
📍 Checkpoint: Runbooks complete
```

#### [🧠 CLAUDE DESKTOP] Task 5.2.2: Deployment Guide Finalization
```
Finalize deployment guide for production
├─ Document:
│   ├─ Pre-deployment checklist
│   ├─ Deployment procedure (step-by-step)
│   ├─ Validation procedure (post-deployment)
│   ├─ Rollback procedure (emergency)
│   └─ Communication templates
├─ Include staging lessons learned
└─ Deliverable: docs/deployment-guide-production.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Production deployment guide ready
```

#### [⚙️ CLAUDE CODE] Task 5.2.3: Rollback Procedure Scripts
```
Create comprehensive rollback scripts for production
├─ Create script: scripts/rollback/rollback-all-production.sh
├─ Features:
│   ├─ Backup current procedures before rollback
│   ├─ Restore previous versions
│   ├─ Validation after rollback
│   └─ Logging of rollback actions
├─ Create individual rollback scripts per procedure
└─ Deliverable: Complete rollback script suite

⏱️ Time: 0.5 hours
🚨 Blocker Risk: MEDIUM (rollback is critical safety net)
📍 Checkpoint: Rollback procedures ready
```

---

### PHASE 5.3: Sprint 9 Retrospective (2h)

#### [🧠 CLAUDE DESKTOP] Task 5.3.1: Sprint 9 Metrics Collection
```
Collect and analyze all Sprint 9 metrics
├─ Compile test results:
│   ├─ Unit test pass rate
│   ├─ Integration test pass rate
│   ├─ Performance benchmark results
│   └─ Security audit results
├─ Calculate Sprint 9 statistics:
│   ├─ Total hours invested
│   ├─ Issues discovered and resolved
│   ├─ Test coverage percentage
│   └─ Success rate vs targets
└─ Deliverable: sprint9-metrics-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Sprint 9 metrics collected
```

#### [🧠 CLAUDE DESKTOP] Task 5.3.2: Lessons Learned Documentation
```
Document Sprint 9 lessons learned
├─ What went well:
│   ├─ Test automation effectiveness
│   ├─ Issue detection rate
│   └─ Team collaboration
├─ What could improve:
│   ├─ Test coverage gaps
│   ├─ Process bottlenecks
│   └─ Tool limitations
├─ Surprises/Unexpected:
│   ├─ Performance results
│   ├─ Integration issues
│   └─ Security findings
├─ Recommendations for Sprint 10
└─ Deliverable: sprint9-lessons-learned.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Lessons learned captured
```

#### [🧠 CLAUDE DESKTOP] Task 5.3.3: Sprint 10 Planning
```
Create Sprint 10 (Production Deployment) detailed plan
├─ Review Sprint 9 outcomes and readiness
├─ Document any blockers for production
├─ Create Sprint 10 execution plan (similar structure to this doc)
├─ Define production deployment schedule
├─ Identify stakeholders for approval
└─ Deliverable: sprint10-execution-plan.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Sprint 10 plan ready
```

#### [🧠 CLAUDE DESKTOP] Task 5.3.4: Sprint 9 Final Report
```
Generate comprehensive Sprint 9 completion report
├─ Executive summary (1-page)
├─ Detailed test results
├─ Issues discovered and resolved
├─ Readiness assessment for production
├─ Sign-off recommendation
├─ Update progress-tracker.md (Sprint 9 complete)
└─ Deliverable: sprint9-final-report.md

⏱️ Time: 0.5 hours
🚨 Blocker Risk: LOW
📍 Checkpoint: Sprint 9 complete
```

---

## ✅ SPRINT 9 SUCCESS CRITERIA

### Must-Have (Blocking)

- [ ] All 15 procedures deployed to STAGING
- [ ] All unit tests passing (target: >95% pass rate)
- [ ] All integration tests passing (target: >90% pass rate)
- [ ] Zero P0 security issues remaining
- [ ] Performance within 50% of target (can optimize in Sprint 10)
- [ ] Rollback procedures tested and validated
- [ ] Documentation complete (runbooks + deployment guide)

### Should-Have (Non-Blocking)

- [ ] Performance within 20% of SQL Server baseline
- [ ] All P1 security issues resolved
- [ ] Concurrent execution validated
- [ ] Monitoring dashboards operational
- [ ] All test automation complete

### Nice-to-Have (Deferred)

- [ ] P2 security issues resolved
- [ ] Advanced monitoring (alerts, custom dashboards)
- [ ] Performance optimizations beyond baseline
- [ ] Additional test coverage

---

## 🚨 BLOCKER ESCALATION PROTOCOL

### Level 1: Standard Issues (0-4 hours delay)
**Examples:** Test failures, minor deployment issues  
**Action:** Resolve within sprint, document in daily report  
**Escalation:** None required

### Level 2: Moderate Blockers (4-8 hours delay)
**Examples:** Missing dependencies, integration failures  
**Action:** Pause affected phase, focus team on resolution  
**Escalation:** Notify stakeholders, adjust sprint timeline

### Level 3: Critical Blockers (>8 hours delay)
**Examples:** STAGING environment down, security vulnerabilities  
**Action:** Stop sprint, immediate escalation  
**Escalation:** Emergency stakeholder meeting, consider Sprint 9 extension

---

## 📊 DAILY HANDOFF CHECKLIST

### End of Each Day, Pierre Creates:
```
Daily Handoff Report Template:

Date: YYYY-MM-DD
Day: X of Sprint 9
Status: ON TRACK / AT RISK / BLOCKED

Completed Today:
- [ ] Task 1
- [ ] Task 2

Issues Encountered:
- Issue 1: [Description] - Resolution: [How fixed]

Blockers:
- Blocker 1: [Description] - Impact: [HIGH/MEDIUM/LOW]

Tomorrow's Plan:
- [ ] Task 1
- [ ] Task 2

Notes:
- [Any important observations]
```

---

## 🎯 SPRINT 9 DELIVERABLES SUMMARY

### Day 1: Pre-Integration Setup
1. ✅ dependencies-staging-status.md (Code → Desktop)
2. ✅ dependency-action-plan.md (Desktop → Pierre)
3. ✅ deploy-all-staging.sh (Code → Pierre)
4. ✅ deployment-validation-report.md (Code → Desktop)
5. ✅ grafana-perseus-dashboard.json (Code → Pierre)
6. ✅ day1-completion-report.md (Desktop)

### Day 2: Unit Testing - Part 1
7. ✅ test-execution-plan.md (Desktop)
8. ✅ run-unit-tests.sh (Code → Pierre)
9. ✅ p1-test-analysis-report.md (Code → Desktop)
10. ✅ p1-fix-instructions.md (Desktop, if failures)
11. ✅ p2-test-analysis-report.md (Code → Desktop)
12. ✅ day2-completion-report.md (Desktop)

### Day 3: Unit Testing - Part 2
13. ✅ fix-summary.md (Code, if P0/P1 failures)
14. ✅ p3-test-analysis-report.md (Code → Desktop)
15. ✅ benchmark-procedures.sh (Code → Pierre)
16. ✅ performance-analysis-report.md (Desktop)
17. ✅ data-integrity-check.sql (Code → Pierre)
18. ✅ day3-completion-report.md (Desktop)

### Day 4: Integration Testing
19. ✅ workflow-integration-map.md (Desktop)
20. ✅ run-integration-tests.sh (Code)
21. ✅ test-concurrency.sh (Code → Pierre)
22. ✅ concurrency-analysis-report.md (Desktop)
23. ✅ test-failure-scenarios.sh (Code)
24. ✅ day4-completion-report.md (Desktop)

### Day 5: Security & Documentation
25. ✅ audit-procedures.sh (Code → Pierre)
26. ✅ security-remediation-plan.md (Desktop)
27. ✅ docs/runbooks/ (15 files, Desktop)
28. ✅ deployment-guide-production.md (Desktop)
29. ✅ rollback-all-production.sh (Code)
30. ✅ sprint9-metrics-report.md (Desktop)
31. ✅ sprint9-lessons-learned.md (Desktop)
32. ✅ sprint10-execution-plan.md (Desktop)
33. ✅ sprint9-final-report.md (Desktop)

**TOTAL DELIVERABLES:** 33 artifacts

---

## 🔗 CRITICAL PATHS & DEPENDENCIES

### Day 1 → Day 2 Dependency
**CRITICAL:** STAGING must be fully operational with all procedures deployed  
**BLOCKER:** If deployment fails, Day 2 cannot start  
**MITIGATION:** Have rollback plan ready, secondary STAGING if available

### Day 2 → Day 3 Dependency
**CRITICAL:** P0/P1 test failures must be identified  
**BLOCKER:** If >50% tests fail, need to reassess procedure quality  
**MITIGATION:** Timebox fix effort, may need Sprint 9 extension

### Day 3 → Day 4 Dependency
**CRITICAL:** All unit tests must pass before integration testing  
**BLOCKER:** Integration tests invalid if unit tests fail  
**MITIGATION:** Focus on P1 procedures first, defer P3 if needed

### Day 4 → Day 5 Dependency
**CRITICAL:** Integration tests must validate workflow correctness  
**BLOCKER:** Cannot proceed to production if workflows broken  
**MITIGATION:** Document workarounds, may need procedure fixes

### Day 5 → Sprint 10 Dependency
**CRITICAL:** Security P0 issues must be resolved  
**BLOCKER:** Cannot deploy to production with security vulnerabilities  
**MITIGATION:** Extend Sprint 9 if needed, security is non-negotiable

---

## 📞 COMMUNICATION PROTOCOL

### Daily Standup (15 minutes, 9:00 AM)
**Attendees:** Pierre, Team Leads, Stakeholders (optional)  
**Format:**
- What was completed yesterday
- What is planned today
- Any blockers

### Daily Status Email (End of Day)
**Recipients:** Stakeholders, Team  
**Template:** Use Daily Handoff Checklist  
**Timing:** Before 6:00 PM

### Emergency Escalation
**Trigger:** Level 3 blocker encountered  
**Action:** Immediate email + Slack notification  
**Recipients:** Project Manager, Technical Lead, DBA Team Lead

---

## 🎖️ FINAL NOTES

**THIS EXECUTION PLAN IS:**
- ✅ Comprehensive (33 deliverables, 5 days)
- ✅ Structured (clear phases and checkpoints)
- ✅ Role-Separated (Pierre/Desktop/Code clearly defined)
- ✅ Time-Boxed (8 hours per day, realistic estimates)
- ✅ Risk-Aware (blocker risk levels documented)
- ✅ Flexible (conditional paths for failures)

**REMEMBER:**
- 🧠 Desktop = Strategic (analysis, planning, docs)
- ⚙️ Code = Tactical (scripts, tests, execution)
- 👤 Pierre = Operational (infra, approvals, coordination)

**SUCCESS DEPENDS ON:**
1. STAGING environment readiness (Day 1 critical)
2. Test automation (saves 50% manual effort)
3. Clear handoffs (Desktop → Code → Pierre)
4. Daily communication (no surprises)
5. Blocker management (escalate early)

---

**SPRINT 9 EXECUTION PLAN v1.0**  
**Created:** 2025-11-29  
**Author:** Claude Desktop (Command Center)  
**For:** Pierre Ribeiro - Perseus Migration Project  
**Next:** Execute Day 1 on 2025-12-02

**Over and out! 📡**
