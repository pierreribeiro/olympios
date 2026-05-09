Core Principles: T-SQL to PostgreSQL Refactoring
------------------------------------------------

1. **ANSI-SQL Primacy**: Prioritize standard ANSI SQL syntax over vendor-specific extensions. The goal is to minimize dialect coupling and ensure business logic is portable and readable.

2. **Strict Typing & Explicit Casting**: Unlike SQL Server, PostgreSQL is strictly typed. All data conversions must be explicit (using `CAST` or `::`) to prevent runtime errors and ensure query plan stability.

3. **Set-Based Execution**: Eliminate RBAR (Row-By-Agonizing-Row) patterns, such as `WHILE` loops and cursors. Refactoring must favor set-based operations to fully leverage the PostgreSQL query optimizer.

4. **Atomic Transaction Management**: Explicitly manage transaction boundaries. Refactored code must account for PostgreSQL’s unique function/procedure transaction behavior and block-level error handling.

5. **Idiomatic Naming & Scoping**: Adopt `snake_case` and lowercase for all identifiers. Avoid double-quoting objects by following native PostgreSQL naming conventions to ensure seamless CLI and tool integration.

6. **Structured Error Resilience**: Implement standardized `EXCEPTION` blocks. Every procedure or function must provide meaningful telemetry via `RAISE` levels or log tables to ensure migration issues are traceable.

7. **Modular Logic Separation**: Maintain a "Clean Schema" architecture. Separate data storage from procedural logic and ensure all object calls are schema-qualified to prevent `search_path` vulnerabilities.


