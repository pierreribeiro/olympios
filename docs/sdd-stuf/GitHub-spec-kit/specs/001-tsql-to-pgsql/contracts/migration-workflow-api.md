# Migration Workflow API Contracts

**Created**: 2026-01-19
**Feature**: 001-tsql-to-pgsql
**Purpose**: Define interfaces for the four-phase migration workflow

---

## Overview

This document defines the API contracts (interfaces) for the Perseus database migration workflow. Since this is a database migration project (not a REST API), "contracts" represent:

1. **Input/Output Contracts**: What each migration phase consumes and produces
2. **Validation Contracts**: How to verify success at each gate
3. **Tool Interfaces**: How automation scripts interact with database objects
4. **Quality Gate Contracts**: Criteria for phase transitions

---

## Four-Phase Workflow Contract

```
Phase 1: Analysis
    Input: SQL Server object + AWS SCT output
    Output: Analysis document (issues, quality score, corrected code)

Phase 2: Refactoring
    Input: Analysis document
    Output: Production-ready PostgreSQL code

Phase 3: Validation
    Input: Refactored code
    Output: Test results, performance metrics

Phase 4: Deployment
    Input: Validated code
    Output: Deployed object, rollback procedure
```

---

## Phase 1: Analysis Contract

### Input Contract

```typescript
interface AnalysisInput {
    object_name: string;              // e.g., "McGetUpStream"
    object_type: ObjectType;          // 'view' | 'function' | 'table' | ...
    sql_server_source: string;        // Original T-SQL code
    aws_sct_output: string;           // AWS SCT converted code
    dependency_info: DependencyInfo;  // From lote1-4 analysis
}

interface DependencyInfo {
    depends_on: string[];             // Objects this depends on
    used_by: string[];                // Objects that use this
    priority: 'P0' | 'P1' | 'P2' | 'P3';
    complexity_score: number;         // 1-10
}

enum ObjectType {
    VIEW = 'view',
    FUNCTION = 'function',
    TABLE = 'table',
    INDEX = 'index',
    CONSTRAINT = 'constraint',
    TYPE = 'type',
    FDW = 'fdw',
    REPLICATION = 'replication',
    JOB = 'job'
}
```

### Output Contract

```typescript
interface AnalysisOutput {
    object_name: string;
    analysis_date: Date;
    quality_score: QualityScore;
    issues: Issue[];
    corrected_code: string;           // Manually refactored PostgreSQL code
    test_recommendations: TestCase[];
    migration_notes: string;
}

interface QualityScore {
    overall: number;                  // 0-10
    syntax_correctness: number;       // 0-10 (weight: 20%)
    logic_preservation: number;       // 0-10 (weight: 30%)
    performance: number;              // 0-10 (weight: 20%)
    maintainability: number;          // 0-10 (weight: 15%)
    security: number;                 // 0-10 (weight: 15%)
}

interface Issue {
    severity: 'P0' | 'P1' | 'P2' | 'P3';
    category: 'syntax' | 'logic' | 'performance' | 'security' | 'style';
    description: string;
    line_number: number | null;
    fix_applied: boolean;
}
```

### Phase 1 Gate Contract

**Criteria to proceed to Phase 2**:
```typescript
interface Phase1Gate {
    all_aws_sct_warnings_reviewed: boolean;
    all_p0_issues_documented: boolean;
    corrected_code_compiles: boolean;
    test_plan_defined: boolean;
    quality_score_minimum: number;    // Must be ≥ 6.0 to proceed
}
```

**Validation Script**: `scripts/validation/phase1-gate-check.sh`

---

## Phase 2: Refactoring Contract

### Input Contract

```typescript
interface RefactoringInput {
    analysis_output: AnalysisOutput;  // From Phase 1
    target_environment: 'DEV' | 'STAGING' | 'PRODUCTION';
}
```

### Output Contract

```typescript
interface RefactoringOutput {
    object_name: string;
    refactored_code: string;          // Production-ready PostgreSQL code
    file_path: string;                // e.g., source/building/pgsql/refactored/views/translated.sql
    constitution_compliance: ConstitutionCompliance;
    changes_applied: Change[];
    git_commit_hash: string;
}

interface ConstitutionCompliance {
    ansi_sql_primacy: boolean;        // Principle I
    strict_typing: boolean;           // Principle II
    set_based_execution: boolean;     // Principle III
    atomic_transactions: boolean;     // Principle IV
    idiomatic_naming: boolean;        // Principle V
    structured_errors: boolean;       // Principle VI
    modular_logic: boolean;           // Principle VII
}

interface Change {
    type: 'P0_fix' | 'P1_fix' | 'P2_fix' | 'optimization';
    description: string;
    diff: string;                     // Before/after code snippet
}
```

### Phase 2 Gate Contract

**Criteria to proceed to Phase 3**:
```typescript
interface Phase2Gate {
    postgresql_syntax_validates: boolean;
    all_p0_issues_resolved: boolean;
    code_review_completed: boolean;
    constitution_compliance_verified: boolean;
    no_syntax_errors: boolean;
}
```

**Validation Script**: `scripts/validation/syntax-check.sh`

---

## Phase 3: Validation Contract

### Input Contract

```typescript
interface ValidationInput {
    refactored_code: string;
    object_metadata: ObjectMetadata;
    test_environment: 'DEV' | 'STAGING';
}

interface ObjectMetadata {
    object_name: string;
    object_type: ObjectType;
    dependencies: string[];
    expected_behavior: string;        // From analysis phase
}
```

### Output Contract

```typescript
interface ValidationOutput {
    object_name: string;
    test_date: Date;
    test_results: TestResults;
    performance_metrics: PerformanceMetrics;
    data_integrity_check: DataIntegrityCheck;
}

interface TestResults {
    unit_tests: TestSuite;
    integration_tests: TestSuite;
    passed: boolean;
}

interface TestSuite {
    total_tests: number;
    passed: number;
    failed: number;
    skipped: number;
    failures: TestFailure[];
}

interface TestFailure {
    test_name: string;
    error_message: string;
    expected: string;
    actual: string;
}

interface PerformanceMetrics {
    sql_server_baseline_ms: number;
    postgresql_execution_ms: number;
    degradation_percent: number;      // Target: ≤20%
    explain_plan: string;
    passed_threshold: boolean;        // degradation ≤ 20%
}

interface DataIntegrityCheck {
    sql_server_row_count: number;
    postgresql_row_count: number;
    row_count_match: boolean;
    sql_server_checksum: string;
    postgresql_checksum: string;
    checksum_match: boolean;
    passed: boolean;
}
```

### Phase 3 Gate Contract

**Criteria to proceed to Phase 4**:
```typescript
interface Phase3Gate {
    all_tests_passed: boolean;
    performance_within_threshold: boolean;  // ≤20% degradation
    no_data_integrity_issues: boolean;
    no_errors_in_logs: boolean;
    deployment_approval_obtained: boolean;  // Technical lead + DBA
}
```

**Validation Scripts**:
- `scripts/validation/performance-test.sql`
- `scripts/validation/data-integrity-check.sql`

---

## Phase 4: Deployment Contract

### Input Contract

```typescript
interface DeploymentInput {
    validated_code: string;
    target_environment: 'DEV' | 'STAGING' | 'PRODUCTION';
    rollback_procedure: string;
    smoke_tests: TestCase[];
}
```

### Output Contract

```typescript
interface DeploymentOutput {
    object_name: string;
    deployment_date: Date;
    environment: 'DEV' | 'STAGING' | 'PRODUCTION';
    deployment_status: 'success' | 'failed' | 'rolled_back';
    smoke_test_results: TestResults;
    rollback_tested: boolean;
    monitoring_enabled: boolean;
}
```

### Phase 4 Gate Contract

**Criteria for production deployment**:
```typescript
interface Phase4Gate {
    staging_smoke_tests_passed: boolean;
    rollback_procedure_tested: boolean;
    production_approval_obtained: boolean;
    monitoring_configured: boolean;
    backup_created: boolean;
    downtime_window_scheduled: boolean;  // <8 hours for full cutover
}
```

**Post-Deployment Monitoring** (24-hour window):
```typescript
interface PostDeploymentMonitoring {
    error_rate: number;               // Errors per hour
    query_performance_degradation: number;  // Percent
    availability: number;             // Percent uptime
    issues_detected: Issue[];
}
```

**Validation Script**: `scripts/deployment/smoke-test.sh`

---

## Validation Contracts (Cross-Phase)

### Result Set Comparison Contract

**Purpose**: Verify PostgreSQL output matches SQL Server exactly

```typescript
interface ResultSetComparison {
    test_name: string;
    sql_server_query: string;
    postgresql_query: string;
    input_parameters: Record<string, any>;

    // Output comparison
    row_count_match: boolean;
    column_count_match: boolean;
    column_names_match: boolean;
    column_types_match: boolean;
    data_values_match: boolean;

    // Differences (if any)
    row_count_diff: number;
    value_differences: ValueDifference[];
}

interface ValueDifference {
    row_number: number;
    column_name: string;
    sql_server_value: any;
    postgresql_value: any;
    reason: string;               // e.g., "Floating point precision", "NULL vs empty string"
}
```

**Implementation**: `scripts/validation/compare-results.py`

**Test Case Example**:
```yaml
test_mcgetupstream_basic:
  sql_server_query: "SELECT * FROM McGetUpStream('MATERIAL123')"
  postgresql_query: "SELECT * FROM mcgetupstream('MATERIAL123')"
  expected_rows: 45
  expected_columns: ['start_point', 'end_point', 'hop_count', 'path']
  tolerance:
    floating_point: 0.0001
    timestamp: '1 second'
```

---

### Performance Baseline Contract

**Purpose**: Ensure query performance within 20% of SQL Server

```typescript
interface PerformanceBaseline {
    test_name: string;
    object_name: string;
    object_type: ObjectType;

    // SQL Server metrics
    sql_server_execution_time_ms: number;
    sql_server_io_reads: number;
    sql_server_cpu_time_ms: number;

    // PostgreSQL metrics
    postgresql_execution_time_ms: number;
    postgresql_buffer_hits: number;
    postgresql_cpu_time_ms: number;

    // Comparison
    execution_time_degradation_percent: number;
    within_threshold: boolean;        // ≤20%

    // Query plan
    sql_server_plan: string;
    postgresql_plan: string;
    index_usage: IndexUsage;
}

interface IndexUsage {
    indexes_used: string[];
    index_scans: number;
    sequential_scans: number;
    bitmap_scans: number;
}
```

**Implementation**: `scripts/validation/performance-test.sql`

**Benchmark Example**:
```sql
-- SQL Server baseline
SET STATISTICS TIME ON;
EXEC McGetUpStream 'MATERIAL123';
-- Capture: CPU time = 125 ms, elapsed time = 156 ms

-- PostgreSQL measurement
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM mcgetupstream('MATERIAL123');
-- Capture: Execution Time = 187 ms (20% degradation = acceptable)
```

---

### Constitution Compliance Contract

**Purpose**: Verify all seven core principles are followed

```typescript
interface ConstitutionCheck {
    object_name: string;
    principle_1_ansi_sql: ComplianceCheck;
    principle_2_strict_typing: ComplianceCheck;
    principle_3_set_based: ComplianceCheck;
    principle_4_atomic_transactions: ComplianceCheck;
    principle_5_idiomatic_naming: ComplianceCheck;
    principle_6_structured_errors: ComplianceCheck;
    principle_7_modular_logic: ComplianceCheck;
    overall_compliance: boolean;
}

interface ComplianceCheck {
    compliant: boolean;
    violations: Violation[];
    justification: string | null;    // Required if not compliant
}

interface Violation {
    severity: 'CRITICAL' | 'MAJOR' | 'MINOR';
    description: string;
    line_number: number;
    fix_required: boolean;
}
```

**Implementation**: Manual code review + automated checks

**Automated Checks**:
```bash
# Principle V: Naming convention
grep -E '[A-Z]' refactored.sql | grep -v '-- ' | grep -v 'CAST\|AS\|FROM\|SELECT'
# Should return no matches (all lowercase)

# Principle VII: Schema qualification
grep -E 'FROM [a-z_]+\(' refactored.sql | grep -v '\.'
# Should return no matches (all qualified)
```

---

## Tool Interface Contracts

### AWS SCT Conversion Interface

**Input**: SQL Server object definition
**Output**: PostgreSQL equivalent (baseline, needs manual review)

```typescript
interface AWSsctConversion {
    input_file: string;               // T-SQL source
    output_file: string;              // PL/pgSQL output
    conversion_warnings: SctWarning[];
    conversion_status: 'success' | 'partial' | 'failed';
}

interface SctWarning {
    code: string;                     // e.g., "MSSQL4035"
    severity: 'error' | 'warning' | 'info';
    message: string;
    line_number: number;
    category: 'temp_table' | 'transaction' | 'data_type' | 'syntax' | 'other';
}
```

**Common Warnings to Fix**:
- MSSQL4035: Temp table initialization requires manual fix
- MSSQL4004: Transaction control requires conversion
- MSSQL4016: IDENTITY INSERT needs alternative approach

---

### Dependency Analysis Interface

**Input**: Database object
**Output**: Dependency graph

```typescript
interface DependencyAnalysis {
    object_name: string;
    depends_on: Dependency[];
    used_by: Dependency[];
    migration_order: number;          // Sequencing for deployment
}

interface Dependency {
    object_name: string;
    object_type: ObjectType;
    dependency_type: 'direct' | 'indirect';
    schema_name: string;
}
```

**Implementation**: Read from `docs/code-analysis/dependency-analysis-*.md`

**Example**:
```yaml
mcgetupstreambylist:
  depends_on:
    - translated (view)
    - temp_goolist (temporary table pattern)
  used_by:
    - reconcilemupstream (procedure - already migrated)
    - processsomemupstream (procedure - already migrated)
  migration_order: 15  # After translated view (order 14)
```

---

## Quality Gate Summary

| Phase | Gate Name | Success Criteria | Blocking? |
|-------|-----------|------------------|-----------|
| 0 → 1 | Constitution Check | All 7 principles addressed | YES |
| 1 → 2 | Analysis Complete | All P0 issues documented, quality ≥6.0 | YES |
| 2 → 3 | Syntax Valid | No syntax errors, code review passed | YES |
| 3 → 4 | Validation Passed | Tests pass, performance ≤20% degradation, data integrity | YES |
| 4 → Production | Deployment Ready | Staging smoke tests pass, rollback tested, approval obtained | YES |

**Rollback Triggers**:
- P0 issue discovered post-deployment
- Data integrity violation detected
- Performance degradation >50%
- Critical errors in production logs

---

## Example: McGetUpStream Migration Contract

**Object**: McGetUpStream (P0 function)

**Phase 1 Contract**:
```json
{
  "analysis_input": {
    "object_name": "McGetUpStream",
    "object_type": "function",
    "sql_server_source": "source/original/sqlserver/McGetUpStream.sql",
    "aws_sct_output": "source/original/pgsql-aws-sct-converted/mcgetupstream.sql",
    "dependency_info": {
      "depends_on": ["translated"],
      "used_by": ["AddArc", "RemoveArc", "ReconcileMUpstream"],
      "priority": "P0",
      "complexity_score": 8
    }
  },
  "analysis_output": {
    "quality_score": {
      "overall": 8.2,
      "syntax_correctness": 9.0,
      "logic_preservation": 9.0,
      "performance": 7.5,
      "maintainability": 8.0,
      "security": 7.5
    },
    "issues": [
      {
        "severity": "P0",
        "category": "syntax",
        "description": "Temp table initialization requires manual fix",
        "line_number": 45,
        "fix_applied": true
      }
    ],
    "corrected_code": "source/building/pgsql/refactored/functions/mcgetupstream.sql"
  }
}
```

**Phase 3 Validation Contract**:
```json
{
  "test_results": {
    "unit_tests": {
      "total_tests": 12,
      "passed": 12,
      "failed": 0
    }
  },
  "performance_metrics": {
    "sql_server_baseline_ms": 156,
    "postgresql_execution_ms": 187,
    "degradation_percent": 19.9,
    "passed_threshold": true
  },
  "data_integrity_check": {
    "row_count_match": true,
    "checksum_match": true,
    "passed": true
  }
}
```

---

**Status**: ✅ Migration workflow contracts defined - Ready for implementation
