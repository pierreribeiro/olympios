# Test Templates

This directory contains templates for creating unit and integration tests for the Perseus database migration.

## Available Templates

### 1. unit-test-template.sql
**Purpose:** Template for testing individual database objects (views, functions, tables, procedures)

**Coverage:**
- Happy path execution
- Edge cases (NULL values, empty results, large datasets)
- Error handling validation
- Result set comparison with SQL Server baseline
- Constitution compliance checks
- Performance baseline comparison
- Data integrity validation
- Constraint enforcement

**Usage:**
```bash
cp templates/test-templates/unit-test-template.sql tests/unit/views/test_upstream_view.sql
# Edit test file to replace [object_name] with actual object name
# Customize test cases for specific object behavior
psql -d perseus_dev -f tests/unit/views/test_upstream_view.sql
```

### 2. integration-test-template.sql
**Purpose:** Template for testing cross-object workflows and end-to-end scenarios

**Coverage:**
- Material lineage workflows (goo + material_transition + views + functions)
- Batch operations (temp table pattern for GooList UDT)
- FDW integration (cross-database joins)
- Transaction management (rollback behavior)
- Cascade behavior (foreign key cascades)
- End-to-end application workflows
- Performance under load

**Usage:**
```bash
cp templates/test-templates/integration-test-template.sql tests/integration/workflow-tests/test_material_lineage_workflow.sql
# Edit test file to replace [Feature/Workflow Name] with actual workflow
# Customize workflow steps for specific integration scenario
psql -d perseus_dev -f tests/integration/workflow-tests/test_material_lineage_workflow.sql
```

## Test Execution Guidelines

### Running Unit Tests
```bash
# Single test
psql -d perseus_dev -f tests/unit/views/test_upstream_view.sql

# All tests in a directory
for test in tests/unit/views/*.sql; do
    echo "Running $test..."
    psql -d perseus_dev -f "$test"
done
```

### Running Integration Tests
```bash
# Integration tests should be run in isolation
psql -d perseus_dev -f tests/integration/workflow-tests/test_material_lineage_workflow.sql
```

### Test Result Interpretation

**✓ PASSED** - Test assertion succeeded
**✗ FAILED** - Test assertion failed (investigate immediately)
**⚠ WARNING** - Test passed but with caveats (review recommended)

## Test Coverage Requirements

Per `specs/001-tsql-to-pgsql/spec.md`:
- **P0 objects:** 100% test coverage required
- **P1 objects:** 90% test coverage required
- **P2/P3 objects:** 80% test coverage required

### Coverage Calculation
Coverage = (Number of test scenarios executed) / (Total number of scenarios identified in analysis)

## Integration with Validation Scripts

These test templates complement the validation scripts in `scripts/validation/`:
- `syntax-check.sh` - Validates SQL syntax
- `performance-test.sql` - Compares performance with SQL Server baseline
- `data-integrity-check.sql` - Validates row counts and checksums
- `dependency-check.sql` - Validates dependency order

## Best Practices

1. **Always use transactions** - Wrap tests in BEGIN/ROLLBACK to prevent test data pollution
2. **Use test ID ranges** - Use specific ID ranges (e.g., 9000-9999 for goo_id) to isolate test data
3. **Clean up test data** - Even though transactions rollback, explicitly cleanup for clarity
4. **Test both success and failure paths** - Don't just test happy path
5. **Compare with SQL Server baseline** - For critical objects, validate result sets match exactly
6. **Measure performance** - Include execution time checks to catch performance regressions
7. **Test edge cases** - NULL values, empty results, large datasets, concurrent access
8. **Document test assumptions** - Add comments explaining what each test validates

## Customization Guidelines

When adapting templates:
1. Replace all `[placeholders]` with actual values
2. Update object names (perseus.[object_name])
3. Adjust test data ranges (9000-9999 for goo_id, etc.)
4. Customize assertions based on object-specific behavior
5. Add/remove test cases based on complexity
6. Update expected values from SQL Server baseline
7. Adjust performance thresholds based on object type

## Example: Creating a Unit Test for a View

```bash
# 1. Copy template
cp templates/test-templates/unit-test-template.sql tests/unit/views/test_upstream.sql

# 2. Replace placeholders
sed -i '' 's/\[object_name\]/upstream/g' tests/unit/views/test_upstream.sql

# 3. Customize test cases for upstream view specifics
# - Add tests for recursive CTE depth limits
# - Add tests for parent_goo_id NULL handling
# - Add tests for circular reference detection

# 4. Run test
psql -d perseus_dev -f tests/unit/views/test_upstream.sql
```

## Continuous Integration

These tests can be integrated into CI/CD pipelines:
```yaml
# .github/workflows/migration-tests.yml
name: Migration Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup PostgreSQL
        run: |
          sudo apt-get install postgresql
          sudo -u postgres createdb perseus_test
      - name: Run Unit Tests
        run: |
          for test in tests/unit/**/*.sql; do
            psql -d perseus_test -f "$test" || exit 1
          done
      - name: Run Integration Tests
        run: |
          for test in tests/integration/**/*.sql; do
            psql -d perseus_test -f "$test" || exit 1
          done
```

## Troubleshooting

**Test fails with "relation does not exist"**
- Ensure object has been deployed to test database
- Check schema qualification (perseus.object_name)
- Verify dependencies are deployed first

**Test performance warning**
- Review EXPLAIN ANALYZE output
- Check if indexes are created
- Verify statistics are up to date (ANALYZE command)
- Compare with SQL Server execution plan

**Test result mismatch with SQL Server**
- Check data type conversions (MONEY → NUMERIC, etc.)
- Verify NULL handling differences
- Compare sort order (collation differences)
- Check floating-point precision tolerance

---

**Last Updated:** 2026-01-23
**Maintained By:** Perseus Migration Team
