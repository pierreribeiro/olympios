# Analysis: [Object Name]

**Object Type:** [view | function | table | index | constraint | procedure]
**Priority:** [P0 | P1 | P2 | P3]
**Lote:** [lote1 | lote2 | lote3 | lote4 | external | jobs]
**Analyst:** [Name]
**Date:** [YYYY-MM-DD]

---

## 1. Source Analysis

### SQL Server Original

**File:** `source/original/sqlserver/[object-name].sql`
**Lines of Code:** [number]
**Dependencies:** [List tables, views, functions this object depends on]
**Dependents:** [List objects that depend on this object]

**Key Characteristics:**
- [ ] Uses vendor-specific syntax (T-SQL extensions)
- [ ] Contains cursors or WHILE loops
- [ ] Uses temp tables (#temp)
- [ ] Uses table variables (@table)
- [ ] Uses IDENTITY columns
- [ ] Uses linked servers (OPENQUERY/OPENROWSET)
- [ ] Uses indexed views
- [ ] Uses recursive CTEs
- [ ] Uses dynamic SQL
- [ ] Uses TRY/CATCH error handling

### AWS SCT Conversion

**File:** `source/original/pgsql-aws-sct-converted/[object-name].sql`
**Lines of Code:** [number]
**AWS SCT Warnings:** [count]
**Conversion Quality:** [Baseline estimate: 0-100%]

**SCT Issues Identified:**
1. [Issue description with line number]
2. [Issue description with line number]
3. [...]

---

## 2. Constitution Compliance Check

### Core Principles Assessment

- [ ] **I. ANSI-SQL Primacy** - Uses standard SQL, minimal vendor extensions
- [ ] **II. Strict Typing & Explicit Casting** - All casts use CAST() or ::
- [ ] **III. Set-Based Execution** - No cursors, no WHILE loops, uses CTEs/window functions
- [ ] **IV. Atomic Transaction Management** - Explicit BEGIN/COMMIT/ROLLBACK, specific exceptions
- [ ] **V. Idiomatic Naming & Scoping** - snake_case names, schema-qualified references
- [ ] **VI. Structured Error Resilience** - Specific exception types, no WHEN OTHERS only
- [ ] **VII. Modular Logic Separation** - Clean schema architecture, one responsibility

**Violations Found:**
| Principle | Line # | Issue | Severity |
|-----------|--------|-------|----------|
| [I-VII] | [#] | [Description] | [P0/P1/P2/P3] |

---

## 3. Complexity Analysis

### Cyclomatic Complexity
- **Branching Points:** [count IF/CASE statements]
- **Loop Structures:** [count WHILE/FOR loops]
- **Recursion Depth:** [max expected depth if recursive]
- **External Dependencies:** [count FDW/external calls]

### Logic Complexity Score (1-5)
- **1 - CRUD:** Simple INSERT/UPDATE/DELETE/SELECT
- **2 - Simple:** Basic JOINs, WHERE clauses, no subqueries
- **3 - Moderate:** Subqueries, aggregations, GROUP BY
- **4 - Complex:** Nested CTEs, window functions, complex JOINs
- **5 - Advanced:** Recursive CTEs, dynamic SQL, advanced set operations

**Score:** [1-5] - [Justification]

---

## 4. Data Type Mapping

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| [type] | [type] | [Any precision/scale considerations] |
| ... | ... | ... |

**Critical Conversions:**
- **MONEY →** NUMERIC(19,4) - [Precision acceptable? Yes/No]
- **UNIQUEIDENTIFIER →** UUID - [Extension enabled? Yes/No]
- **DATETIME →** TIMESTAMP - [Timezone handling? Documented]
- **VARCHAR(MAX) →** TEXT - [Acceptable? Yes/No]

---

## 5. Performance Considerations

### Query Patterns
- **Read-heavy:** [% SELECT operations]
- **Write-heavy:** [% INSERT/UPDATE/DELETE operations]
- **Mixed workload:** [Concurrent read/write]

### Expected Volume
- **Row count:** [Estimated rows processed per execution]
- **Execution frequency:** [per second | per minute | per hour | per day]
- **Peak load:** [Concurrent executions expected]

### Index Requirements
- **Covering indexes:** [List required indexes for optimal performance]
- **Join columns:** [Columns requiring indexes for JOINs]
- **Filter columns:** [WHERE clause columns requiring indexes]

---

## 6. Migration Strategy

### Refactoring Approach

**Option 1: [Minimal Change]**
- Use AWS SCT output as baseline
- Fix only P0/P1 violations
- Estimated effort: [hours]
- Risk: [Low | Medium | High]

**Option 2: [Moderate Refactoring]**
- Refactor cursors to set-based
- Optimize query patterns
- Apply constitution principles
- Estimated effort: [hours]
- Risk: [Low | Medium | High]

**Option 3: [Full Rewrite]**
- Rewrite from scratch using best practices
- Apply all constitution principles
- Optimize for PostgreSQL idioms
- Estimated effort: [hours]
- Risk: [Low | Medium | High]

**Recommended:** [Option 1 | 2 | 3] - [Justification]

### Pattern Reuse
- **Similar objects:** [List similar migrated objects to reuse patterns from]
- **Reusable components:** [CTEs, subqueries, temp table patterns to extract]
- **Expected pattern reuse:** [0-100%]

---

## 7. Testing Requirements

### Unit Test Cases
1. **Happy path:** [Description]
2. **Edge case 1:** [Empty input, NULL values, etc.]
3. **Edge case 2:** [Max values, boundary conditions]
4. **Error case:** [Invalid input, constraint violations]
5. **Performance:** [Large dataset, concurrent execution]

### Integration Test Cases
1. **Dependency test:** [Verify dependent objects work correctly]
2. **Workflow test:** [End-to-end application workflow]
3. **FDW test:** [If applicable - external database connectivity]

### Validation Criteria
- [ ] Syntax validation passes (scripts/validation/syntax-check.sh)
- [ ] Dependency check passes (scripts/validation/dependency-check.sql)
- [ ] Result set matches SQL Server output 100% (scripts/validation/data-integrity-check.sql)
- [ ] Performance within 20% of SQL Server baseline (scripts/validation/performance-test.sql)
- [ ] All unit tests pass
- [ ] Quality score ≥7.0/10 (≥8.0/10 for P0 objects)

---

## 8. Quality Score Prediction

### Estimated Scores (Pre-Refactoring)

| Dimension | Score (0-10) | Notes |
|-----------|--------------|-------|
| **Syntax Correctness** (20%) | [score] | [AWS SCT warnings, syntax errors] |
| **Logic Preservation** (30%) | [score] | [Business logic identical to SQL Server?] |
| **Performance** (20%) | [score] | [Expected performance vs baseline] |
| **Maintainability** (15%) | [score] | [Readability, documentation, complexity] |
| **Security** (15%) | [score] | [SQL injection risks, permissions] |
| **Overall** | **[weighted avg]** | Minimum 7.0/10 required |

**P0/P1 Blockers:** [Count violations requiring fix before deployment]
**P2/P3 Issues:** [Count issues to address before STAGING]

---

## 9. Risk Assessment

### Technical Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Description] | [1-5] | [1-5] | [Strategy] |

### Migration Risks
- **Rollback complexity:** [Can easily roll back? Yes/No]
- **Data loss risk:** [Zero tolerance - validation strategy]
- **Downtime risk:** [Estimated deployment time]

---

## 10. Decision & Next Steps

### Final Recommendation
- **Proceed with migration:** [Yes | No | Conditional]
- **Refactoring approach:** [Option 1 | 2 | 3]
- **Estimated effort:** [hours]
- **Target sprint:** [Sprint N]

### Action Items
- [ ] Create refactored SQL in `source/building/pgsql/refactored/[type]/[name].sql`
- [ ] Create unit tests in `tests/unit/[type]/test_[name].sql`
- [ ] Add to dependency deployment sequence
- [ ] Update tracking/database-objects-inventory.csv status to "analyzed"
- [ ] Schedule for refactoring phase

---

**Analysis Completed:** [YYYY-MM-DD]
**Approved By:** [Name]
**Status:** [Draft | Approved | Rejected]
