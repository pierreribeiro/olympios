#!/usr/bin/env python3
"""
compare-versions.py - SQL Server vs PostgreSQL Version Comparison Tool

Purpose:
    Side-by-side comparison of SQL Server original vs PostgreSQL converted database
    objects. Highlights syntax transformations, logic differences, and conversion
    quality. Supports batch comparison with comprehensive reporting.

Usage:
    # Compare a procedure
    python compare-versions.py procedure addarc

    # Compare with custom paths
    python compare-versions.py function mcgetupstream \
        --sqlserver source/original/sqlserver/mcgetupstream.sql \
        --postgresql source/building/pgsql/refactored/19.create-function/mcgetupstream.sql

    # Batch comparison with report
    python compare-versions.py --batch procedures.txt --output comparison-report.md

    # Side-by-side terminal view
    python compare-versions.py view translated --side-by-side

    # JSON output for automation
    python compare-versions.py procedure addarc --format json

Features:
    - Line-by-line unified diff with color highlighting
    - Side-by-side comparison mode
    - Structural comparison (signatures, schemas, indexes)
    - Transformation analysis (data types, syntax conversions)
    - Quality assessment with statistics
    - Multiple output formats (terminal, markdown, HTML, JSON)

Exit Codes:
    0 = Files are identical
    1 = Differences found (normal)
    2 = Invalid arguments
    3 = File not found

Author: Pierre Ribeiro (DBA/DBRE)
Created: 2026-01-25
Version: 1.0
"""

import argparse
import difflib
import json
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from enum import Enum


# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

class ObjectType(Enum):
    """Supported database object types"""
    PROCEDURE = "procedure"
    FUNCTION = "function"
    VIEW = "view"
    TABLE = "table"


class OutputFormat(Enum):
    """Output format options"""
    TERMINAL = "terminal"
    MARKDOWN = "markdown"
    HTML = "html"
    JSON = "json"


# ANSI color codes for terminal output
class Colors:
    RESET = "\033[0m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    DIM = "\033[2m"


# T-SQL to PostgreSQL transformation patterns
TRANSFORMATION_PATTERNS = {
    # Data type conversions
    r'\bNVARCHAR\b': ('VARCHAR', 'Data type conversion'),
    r'\bDATETIME\b': ('TIMESTAMP', 'Data type conversion'),
    r'\bMONEY\b': ('NUMERIC(19,4)', 'Data type conversion'),
    r'\bUNIQUEIDENTIFIER\b': ('UUID', 'Data type conversion'),
    r'\bIMAGE\b': ('BYTEA', 'Data type conversion'),
    r'\bTEXT\b': ('TEXT', 'Data type conversion'),

    # Identity columns
    r'\bIDENTITY\s*\(\s*\d+\s*,\s*\d+\s*\)': ('GENERATED ALWAYS AS IDENTITY', 'Identity column syntax'),

    # String concatenation
    r'\+\s*(?=[\'\"])': ('||', 'String concatenation operator'),

    # Functions
    r'\bGETDATE\s*\(\s*\)': ('CURRENT_TIMESTAMP', 'Function replacement'),
    r'\bISNULL\s*\(': ('COALESCE(', 'Function replacement'),
    r'\bLEN\s*\(': ('LENGTH(', 'Function replacement'),
    r'\bDATEADD\s*\(': ('+ INTERVAL', 'Date arithmetic'),

    # Conditional logic
    r'\bIIF\s*\(': ('CASE WHEN', 'Conditional expression'),

    # Transaction syntax
    r'\bBEGIN\s+TRAN\b': ('BEGIN', 'Transaction syntax'),
    r'\bCOMMIT\s+TRAN\b': ('COMMIT', 'Transaction syntax'),
    r'\bROLLBACK\s+TRAN\b': ('ROLLBACK', 'Transaction syntax'),

    # Error handling
    r'\bRAISERROR\b': ('RAISE EXCEPTION', 'Error handling'),

    # Temp tables
    r'CREATE\s+TABLE\s+#': ('CREATE TEMPORARY TABLE tmp_', 'Temporary table syntax'),
    r'#\w+': ('tmp_*', 'Temp table reference'),

    # Top clause
    r'\bSELECT\s+TOP\s+\d+\b': ('SELECT ... LIMIT', 'Row limiting'),

    # Null comparison
    r'=\s*NULL': ('IS NULL', 'Null comparison'),
    r'<>\s*NULL': ('IS NOT NULL', 'Null comparison'),
}

# Constitution principles (from POSTGRESQL-PROGRAMMING-CONSTITUTION.md)
CONSTITUTION_PRINCIPLES = [
    "I. ANSI-SQL Primacy",
    "II. Strict Typing & Explicit Casting",
    "III. Set-Based Execution",
    "IV. Atomic Transaction Management",
    "V. Idiomatic Naming & Scoping",
    "VI. Structured Error Resilience",
    "VII. Modular Logic Separation"
]


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class FileInfo:
    """Information about a SQL file"""
    path: Path
    content: str
    lines: List[str]
    line_count: int

    @classmethod
    def from_file(cls, filepath: Path) -> 'FileInfo':
        """Load file information"""
        content = filepath.read_text(encoding='utf-8')
        lines = content.splitlines()
        return cls(
            path=filepath,
            content=content,
            lines=lines,
            line_count=len(lines)
        )


@dataclass
class DiffStats:
    """Difference statistics"""
    lines_added: int = 0
    lines_removed: int = 0
    lines_changed: int = 0
    total_changes: int = 0
    percent_changed: float = 0.0


@dataclass
class Transformation:
    """Detected transformation"""
    pattern: str
    description: str
    count: int
    examples: List[Tuple[str, str]] = field(default_factory=list)


@dataclass
class ComparisonResult:
    """Complete comparison result"""
    object_name: str
    object_type: str
    sqlserver_file: FileInfo
    postgresql_file: FileInfo
    diff_stats: DiffStats
    transformations: List[Transformation]
    unified_diff: str
    side_by_side: Optional[str] = None
    are_identical: bool = False
    quality_score: float = 0.0
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())


# ============================================================================
# FILE DISCOVERY
# ============================================================================

def find_sqlserver_file(object_type: str, object_name: str, base_dir: Path) -> Optional[Path]:
    """
    Find SQL Server original file for an object.

    Searches in source/original/sqlserver/ directory structure.
    SQL Server files use PascalCase naming (e.g., AddArc, GetMaterial).
    """
    search_dirs = [
        base_dir / "source/original/sqlserver/11. create-routine",
        base_dir / "source/original/sqlserver/14. create-table",
        base_dir / "source/original/sqlserver/15. create-view",
        base_dir / "source/original/sqlserver",
    ]

    # Normalize search name to lowercase for case-insensitive matching
    search_name_lower = object_name.lower().replace('_', '')

    for search_dir in search_dirs:
        if not search_dir.exists():
            continue

        # List all SQL files and filter case-insensitively
        all_files = list(search_dir.glob("*.sql"))

        for file in all_files:
            # Normalize filename for comparison (remove extension, dots, lowercase)
            file_name_normalized = file.stem.lower().replace('.', '').replace('_', '')

            # Check if search name is in the filename
            if search_name_lower in file_name_normalized:
                # Exclude drop files
                if 'drop-' not in str(file):
                    return file

    return None


def find_postgresql_file(object_type: str, object_name: str, base_dir: Path) -> Optional[Path]:
    """
    Find PostgreSQL converted file for an object.

    Searches in source/building/pgsql/refactored/ directory structure.
    PostgreSQL files use snake_case naming (e.g., addarc, get_material).
    """
    type_dirs = {
        'procedure': '20. create-procedure',
        'function': '19. create-function',
        'view': '15. create-view',
        'table': '14. create-table'
    }

    search_dirs = [
        base_dir / "source/building/pgsql/refactored" / type_dirs.get(object_type, ''),
        base_dir / "source/building/pgsql/refactored",
    ]

    # Normalize to lowercase for PostgreSQL
    normalized_name = object_name.lower().replace('_', '')

    patterns = [
        f"*{object_name.lower()}*.sql",
        f"*{normalized_name}*.sql",
        f"*{object_name}*.sql",
    ]

    for search_dir in search_dirs:
        if not search_dir.exists():
            continue
        for pattern in patterns:
            matches = list(search_dir.rglob(pattern))
            if matches:
                return matches[0]

    return None


# ============================================================================
# DIFF GENERATION
# ============================================================================

def generate_unified_diff(file1: FileInfo, file2: FileInfo, context_lines: int = 3) -> str:
    """Generate unified diff between two files"""
    diff = difflib.unified_diff(
        file1.lines,
        file2.lines,
        fromfile=f"SQL Server: {file1.path.name}",
        tofile=f"PostgreSQL: {file2.path.name}",
        lineterm='',
        n=context_lines
    )
    return '\n'.join(diff)


def colorize_diff_line(line: str) -> str:
    """Add ANSI color codes to diff line for terminal display"""
    if line.startswith('+++') or line.startswith('---'):
        return f"{Colors.BOLD}{line}{Colors.RESET}"
    elif line.startswith('@@'):
        return f"{Colors.CYAN}{line}{Colors.RESET}"
    elif line.startswith('+'):
        return f"{Colors.GREEN}{line}{Colors.RESET}"
    elif line.startswith('-'):
        return f"{Colors.RED}{line}{Colors.RESET}"
    else:
        return line


def generate_side_by_side(file1: FileInfo, file2: FileInfo, width: int = 80) -> str:
    """Generate side-by-side comparison"""
    half_width = (width - 3) // 2

    output = []
    output.append("=" * width)
    output.append(f"{Colors.BOLD}SQL Server{Colors.RESET}".ljust(half_width) + " | " +
                  f"{Colors.BOLD}PostgreSQL{Colors.RESET}")
    output.append("=" * width)

    max_lines = max(len(file1.lines), len(file2.lines))

    for i in range(max_lines):
        left = file1.lines[i] if i < len(file1.lines) else ""
        right = file2.lines[i] if i < len(file2.lines) else ""

        # Truncate if needed
        left_display = left[:half_width].ljust(half_width)
        right_display = right[:half_width]

        # Color differences
        if left != right:
            if not left:
                right_display = f"{Colors.GREEN}{right_display}{Colors.RESET}"
            elif not right:
                left_display = f"{Colors.RED}{left_display}{Colors.RESET}"
            else:
                left_display = f"{Colors.YELLOW}{left_display}{Colors.RESET}"
                right_display = f"{Colors.YELLOW}{right_display}{Colors.RESET}"

        output.append(f"{left_display} | {right_display}")

    output.append("=" * width)
    return '\n'.join(output)


# ============================================================================
# STATISTICS & ANALYSIS
# ============================================================================

def calculate_diff_stats(file1: FileInfo, file2: FileInfo) -> DiffStats:
    """Calculate difference statistics"""
    differ = difflib.Differ()
    diff = list(differ.compare(file1.lines, file2.lines))

    stats = DiffStats()
    stats.lines_added = sum(1 for line in diff if line.startswith('+ '))
    stats.lines_removed = sum(1 for line in diff if line.startswith('- '))
    stats.lines_changed = min(stats.lines_added, stats.lines_removed)
    stats.total_changes = stats.lines_added + stats.lines_removed

    total_lines = max(file1.line_count, file2.line_count)
    if total_lines > 0:
        stats.percent_changed = (stats.total_changes / total_lines) * 100

    return stats


def detect_transformations(file1: FileInfo, file2: FileInfo) -> List[Transformation]:
    """Detect T-SQL to PostgreSQL transformations"""
    transformations = {}

    for pattern, (replacement, description) in TRANSFORMATION_PATTERNS.items():
        count = 0
        examples = []

        # Find occurrences in SQL Server file
        for i, line in enumerate(file1.lines):
            matches = re.finditer(pattern, line, re.IGNORECASE)
            for match in matches:
                count += 1
                if len(examples) < 3:  # Keep up to 3 examples
                    # Try to find corresponding PostgreSQL line
                    pg_line = file2.lines[i] if i < len(file2.lines) else ""
                    examples.append((line.strip(), pg_line.strip()))

        if count > 0:
            key = description
            if key not in transformations:
                transformations[key] = Transformation(
                    pattern=pattern,
                    description=description,
                    count=0,
                    examples=[]
                )
            transformations[key].count += count
            transformations[key].examples.extend(examples[:3])

    return sorted(transformations.values(), key=lambda x: x.count, reverse=True)


def estimate_quality_score(stats: DiffStats, transformations: List[Transformation]) -> float:
    """
    Estimate conversion quality score (0-10).

    Factors:
    - Lower change percentage = higher score
    - More documented transformations = higher score
    - Minimal additions/deletions = higher score
    """
    base_score = 10.0

    # Penalize excessive changes
    if stats.percent_changed > 50:
        base_score -= 2.0
    elif stats.percent_changed > 30:
        base_score -= 1.0
    elif stats.percent_changed > 20:
        base_score -= 0.5

    # Reward documented transformations (shows systematic conversion)
    transformation_bonus = min(len(transformations) * 0.2, 1.0)
    base_score += transformation_bonus

    # Penalize large net additions (potential over-engineering)
    net_additions = stats.lines_added - stats.lines_removed
    if net_additions > 50:
        base_score -= 1.0
    elif net_additions > 100:
        base_score -= 2.0

    return max(0.0, min(10.0, base_score))


# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

def format_terminal_output(result: ComparisonResult, show_diff: bool = True,
                          side_by_side: bool = False) -> str:
    """Format comparison result for terminal display"""
    output = []

    # Header
    output.append(f"\n{Colors.BOLD}{'=' * 80}{Colors.RESET}")
    output.append(f"{Colors.BOLD}Comparison: {result.object_name} ({result.object_type}){Colors.RESET}")
    output.append(f"{Colors.BOLD}{'=' * 80}{Colors.RESET}\n")

    # File info
    output.append(f"{Colors.CYAN}SQL Server:{Colors.RESET}  {result.sqlserver_file.path}")
    output.append(f"  Lines: {result.sqlserver_file.line_count}")
    output.append(f"\n{Colors.CYAN}PostgreSQL:{Colors.RESET} {result.postgresql_file.path}")
    output.append(f"  Lines: {result.postgresql_file.line_count}\n")

    # Statistics
    if result.are_identical:
        output.append(f"{Colors.GREEN}{Colors.BOLD}✓ FILES ARE IDENTICAL{Colors.RESET}\n")
        return '\n'.join(output)

    output.append(f"{Colors.YELLOW}Statistics:{Colors.RESET}")
    output.append(f"  Lines added:   {Colors.GREEN}+{result.diff_stats.lines_added}{Colors.RESET}")
    output.append(f"  Lines removed: {Colors.RED}-{result.diff_stats.lines_removed}{Colors.RESET}")
    output.append(f"  Lines changed: {Colors.YELLOW}~{result.diff_stats.lines_changed}{Colors.RESET}")
    output.append(f"  Total changes: {result.diff_stats.total_changes}")
    output.append(f"  Percent changed: {result.diff_stats.percent_changed:.1f}%")
    output.append(f"  Quality score: {Colors.BOLD}{result.quality_score:.1f}/10.0{Colors.RESET}\n")

    # Transformations
    if result.transformations:
        output.append(f"{Colors.YELLOW}Transformations Applied:{Colors.RESET}")
        for trans in result.transformations:
            output.append(f"  • {trans.description}: {Colors.BOLD}{trans.count}{Colors.RESET} occurrence(s)")
            if trans.examples:
                for sql_line, pg_line in trans.examples[:2]:
                    output.append(f"    {Colors.DIM}SQL Server: {sql_line[:60]}{Colors.RESET}")
                    output.append(f"    {Colors.DIM}PostgreSQL: {pg_line[:60]}{Colors.RESET}")
        output.append("")

    # Diff or side-by-side
    if show_diff:
        if side_by_side and result.side_by_side:
            output.append(f"{Colors.YELLOW}Side-by-Side Comparison:{Colors.RESET}\n")
            output.append(result.side_by_side)
        else:
            output.append(f"{Colors.YELLOW}Unified Diff:{Colors.RESET}\n")
            for line in result.unified_diff.splitlines():
                output.append(colorize_diff_line(line))

    output.append(f"\n{Colors.BOLD}{'=' * 80}{Colors.RESET}\n")
    return '\n'.join(output)


def format_markdown_output(result: ComparisonResult) -> str:
    """Format comparison result as Markdown"""
    output = []

    # Header
    output.append(f"# Comparison: {result.object_name}")
    output.append(f"\n**Object Type:** {result.object_type}")
    output.append(f"**Date:** {result.timestamp}")
    output.append(f"**Status:** {'✅ Identical' if result.are_identical else '⚠️ Differences Found'}\n")

    # File info
    output.append("## Files")
    output.append(f"\n**SQL Server:** `{result.sqlserver_file.path}`")
    output.append(f"- Lines: {result.sqlserver_file.line_count}")
    output.append(f"\n**PostgreSQL:** `{result.postgresql_file.path}`")
    output.append(f"- Lines: {result.postgresql_file.line_count}\n")

    if result.are_identical:
        return '\n'.join(output)

    # Statistics
    output.append("## Statistics")
    output.append(f"\n| Metric | Value |")
    output.append(f"|--------|-------|")
    output.append(f"| Lines added | +{result.diff_stats.lines_added} |")
    output.append(f"| Lines removed | -{result.diff_stats.lines_removed} |")
    output.append(f"| Lines changed | ~{result.diff_stats.lines_changed} |")
    output.append(f"| Total changes | {result.diff_stats.total_changes} |")
    output.append(f"| Percent changed | {result.diff_stats.percent_changed:.1f}% |")
    output.append(f"| Quality score | **{result.quality_score:.1f}/10.0** |\n")

    # Transformations
    if result.transformations:
        output.append("## Transformations Applied")
        output.append(f"\n| Transformation | Count | Examples |")
        output.append(f"|---------------|-------|----------|")
        for trans in result.transformations:
            examples = " / ".join([f"`{ex[0][:30]}...`" for ex in trans.examples[:2]])
            output.append(f"| {trans.description} | {trans.count} | {examples} |")
        output.append("")

    # Diff
    output.append("## Unified Diff")
    output.append("\n```diff")
    output.append(result.unified_diff)
    output.append("```\n")

    return '\n'.join(output)


def format_json_output(result: ComparisonResult) -> str:
    """Format comparison result as JSON"""
    data = {
        "object_name": result.object_name,
        "object_type": result.object_type,
        "timestamp": result.timestamp,
        "are_identical": result.are_identical,
        "files": {
            "sqlserver": {
                "path": str(result.sqlserver_file.path),
                "lines": result.sqlserver_file.line_count
            },
            "postgresql": {
                "path": str(result.postgresql_file.path),
                "lines": result.postgresql_file.line_count
            }
        },
        "statistics": {
            "lines_added": result.diff_stats.lines_added,
            "lines_removed": result.diff_stats.lines_removed,
            "lines_changed": result.diff_stats.lines_changed,
            "total_changes": result.diff_stats.total_changes,
            "percent_changed": round(result.diff_stats.percent_changed, 2)
        },
        "quality_score": round(result.quality_score, 1),
        "transformations": [
            {
                "description": trans.description,
                "count": trans.count,
                "examples": [{"sqlserver": ex[0], "postgresql": ex[1]}
                           for ex in trans.examples[:3]]
            }
            for trans in result.transformations
        ],
        "unified_diff": result.unified_diff
    }

    return json.dumps(data, indent=2)


def format_html_output(result: ComparisonResult) -> str:
    """Format comparison result as HTML"""
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Comparison: {result.object_name}</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }}
        h1 {{ color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 30px; }}
        .file-info {{ background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 10px 0; }}
        .stats {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }}
        .stat-card {{ background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }}
        .stat-value {{ font-size: 24px; font-weight: bold; color: #4CAF50; }}
        .transformation {{ background: #fff3cd; padding: 10px; margin: 5px 0; border-left: 4px solid #ffc107; }}
        .diff {{ background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }}
        .diff pre {{ margin: 0; font-family: 'Courier New', monospace; font-size: 12px; }}
        .added {{ background: #d4edda; color: #155724; }}
        .removed {{ background: #f8d7da; color: #721c24; }}
        .changed {{ background: #fff3cd; color: #856404; }}
        table {{ border-collapse: collapse; width: 100%; margin: 15px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
    </style>
</head>
<body>
    <h1>Comparison: {result.object_name}</h1>
    <p><strong>Object Type:</strong> {result.object_type}</p>
    <p><strong>Date:</strong> {result.timestamp}</p>
    <p><strong>Status:</strong> {'✅ Identical' if result.are_identical else '⚠️ Differences Found'}</p>

    <h2>Files</h2>
    <div class="file-info">
        <p><strong>SQL Server:</strong> <code>{result.sqlserver_file.path}</code></p>
        <p>Lines: {result.sqlserver_file.line_count}</p>
    </div>
    <div class="file-info">
        <p><strong>PostgreSQL:</strong> <code>{result.postgresql_file.path}</code></p>
        <p>Lines: {result.postgresql_file.line_count}</p>
    </div>
"""

    if not result.are_identical:
        html += f"""
    <h2>Statistics</h2>
    <div class="stats">
        <div class="stat-card">
            <div>Lines Added</div>
            <div class="stat-value" style="color: #28a745;">+{result.diff_stats.lines_added}</div>
        </div>
        <div class="stat-card">
            <div>Lines Removed</div>
            <div class="stat-value" style="color: #dc3545;">-{result.diff_stats.lines_removed}</div>
        </div>
        <div class="stat-card">
            <div>Quality Score</div>
            <div class="stat-value">{result.quality_score:.1f}/10.0</div>
        </div>
    </div>

    <table>
        <tr><th>Metric</th><th>Value</th></tr>
        <tr><td>Lines changed</td><td>~{result.diff_stats.lines_changed}</td></tr>
        <tr><td>Total changes</td><td>{result.diff_stats.total_changes}</td></tr>
        <tr><td>Percent changed</td><td>{result.diff_stats.percent_changed:.1f}%</td></tr>
    </table>
"""

        if result.transformations:
            html += """
    <h2>Transformations Applied</h2>
"""
            for trans in result.transformations:
                html += f"""
    <div class="transformation">
        <strong>{trans.description}:</strong> {trans.count} occurrence(s)
    </div>
"""

        html += f"""
    <h2>Unified Diff</h2>
    <div class="diff">
        <pre>{result.unified_diff}</pre>
    </div>
"""

    html += """
</body>
</html>
"""
    return html


# ============================================================================
# MAIN COMPARISON LOGIC
# ============================================================================

def compare_objects(object_type: str, object_name: str,
                   sqlserver_path: Optional[Path] = None,
                   postgresql_path: Optional[Path] = None,
                   base_dir: Optional[Path] = None) -> ComparisonResult:
    """
    Compare SQL Server and PostgreSQL versions of a database object.

    Args:
        object_type: Type of object (procedure, function, view, table)
        object_name: Name of the object
        sqlserver_path: Optional explicit path to SQL Server file
        postgresql_path: Optional explicit path to PostgreSQL file
        base_dir: Base directory for file discovery

    Returns:
        ComparisonResult with all analysis data
    """
    if base_dir is None:
        base_dir = Path.cwd()

    # Find files
    if sqlserver_path is None:
        sqlserver_path = find_sqlserver_file(object_type, object_name, base_dir)
        if sqlserver_path is None:
            raise FileNotFoundError(f"SQL Server file not found for {object_name}")

    if postgresql_path is None:
        postgresql_path = find_postgresql_file(object_type, object_name, base_dir)
        if postgresql_path is None:
            raise FileNotFoundError(f"PostgreSQL file not found for {object_name}")

    # Load files
    sqlserver_file = FileInfo.from_file(sqlserver_path)
    postgresql_file = FileInfo.from_file(postgresql_path)

    # Check if identical
    are_identical = sqlserver_file.content == postgresql_file.content

    # Generate diff
    unified_diff = generate_unified_diff(sqlserver_file, postgresql_file)

    # Calculate statistics
    diff_stats = calculate_diff_stats(sqlserver_file, postgresql_file)

    # Detect transformations
    transformations = detect_transformations(sqlserver_file, postgresql_file)

    # Estimate quality score
    quality_score = estimate_quality_score(diff_stats, transformations)

    result = ComparisonResult(
        object_name=object_name,
        object_type=object_type,
        sqlserver_file=sqlserver_file,
        postgresql_file=postgresql_file,
        diff_stats=diff_stats,
        transformations=transformations,
        unified_diff=unified_diff,
        are_identical=are_identical,
        quality_score=quality_score
    )

    return result


def batch_compare(batch_file: Path, output_file: Optional[Path] = None,
                 output_format: str = "markdown", base_dir: Optional[Path] = None) -> List[ComparisonResult]:
    """
    Compare multiple objects from a batch file.

    Batch file format (one per line):
        object_type object_name
        procedure addarc
        function mcgetupstream
        view translated
    """
    results = []

    with batch_file.open('r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            parts = line.split()
            if len(parts) != 2:
                print(f"Warning: Invalid format at line {line_num}: {line}", file=sys.stderr)
                continue

            object_type, object_name = parts

            try:
                result = compare_objects(object_type, object_name, base_dir=base_dir)
                results.append(result)
                print(f"✓ Compared {object_type} {object_name}")
            except Exception as e:
                print(f"✗ Failed to compare {object_type} {object_name}: {e}", file=sys.stderr)

    # Generate batch report
    if output_file and results:
        with output_file.open('w') as f:
            if output_format == "markdown":
                f.write(f"# Batch Comparison Report\n\n")
                f.write(f"**Generated:** {datetime.now().isoformat()}\n")
                f.write(f"**Total Objects:** {len(results)}\n\n")
                f.write("---\n\n")
                for result in results:
                    f.write(format_markdown_output(result))
                    f.write("\n---\n\n")
            elif output_format == "json":
                f.write(json.dumps([
                    json.loads(format_json_output(r)) for r in results
                ], indent=2))
        print(f"\nBatch report written to: {output_file}")

    return results


# ============================================================================
# CLI INTERFACE
# ============================================================================

def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Compare SQL Server and PostgreSQL database object versions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Compare a procedure
  %(prog)s procedure addarc

  # Compare with custom paths
  %(prog)s function mcgetupstream \\
      --sqlserver source/original/sqlserver/mcgetupstream.sql \\
      --postgresql source/building/pgsql/refactored/19.create-function/mcgetupstream.sql

  # Batch comparison
  %(prog)s --batch procedures.txt --output comparison-report.md

  # Side-by-side view
  %(prog)s view translated --side-by-side

  # JSON output
  %(prog)s procedure addarc --format json

Exit Codes:
  0 = Files are identical
  1 = Differences found (normal)
  2 = Invalid arguments
  3 = File not found
        """
    )

    # Positional arguments for single comparison
    parser.add_argument('object_type', nargs='?',
                       choices=['procedure', 'function', 'view', 'table'],
                       help='Type of database object')
    parser.add_argument('object_name', nargs='?',
                       help='Name of the object to compare')

    # File path overrides
    parser.add_argument('--sqlserver', type=Path,
                       help='Explicit path to SQL Server file')
    parser.add_argument('--postgresql', type=Path,
                       help='Explicit path to PostgreSQL file')

    # Batch mode
    parser.add_argument('--batch', type=Path,
                       help='Batch file with list of objects to compare')

    # Output options
    parser.add_argument('--output', '-o', type=Path,
                       help='Output file for comparison report')
    parser.add_argument('--format', '-f',
                       choices=['terminal', 'markdown', 'html', 'json'],
                       default='terminal',
                       help='Output format (default: terminal)')
    parser.add_argument('--side-by-side', '-s', action='store_true',
                       help='Show side-by-side comparison (terminal only)')
    parser.add_argument('--no-diff', action='store_true',
                       help='Hide diff output, show only statistics')

    # Base directory
    parser.add_argument('--base-dir', type=Path, default=Path.cwd(),
                       help='Base directory for file discovery (default: current directory)')

    args = parser.parse_args()

    # Validate arguments
    if args.batch:
        # Batch mode
        if not args.batch.exists():
            print(f"Error: Batch file not found: {args.batch}", file=sys.stderr)
            return 3

        try:
            results = batch_compare(
                args.batch,
                args.output,
                args.format,
                args.base_dir
            )

            # Summary
            print(f"\n{'=' * 80}")
            print(f"Batch Comparison Summary")
            print(f"{'=' * 80}")
            print(f"Total objects compared: {len(results)}")
            print(f"Identical: {sum(1 for r in results if r.are_identical)}")
            print(f"Different: {sum(1 for r in results if not r.are_identical)}")
            print(f"Average quality score: {sum(r.quality_score for r in results) / len(results):.1f}/10.0")

            return 0 if all(r.are_identical for r in results) else 1

        except Exception as e:
            print(f"Error during batch comparison: {e}", file=sys.stderr)
            return 1

    else:
        # Single object mode
        if not args.object_type or not args.object_name:
            parser.print_help()
            return 2

        try:
            result = compare_objects(
                args.object_type,
                args.object_name,
                args.sqlserver,
                args.postgresql,
                args.base_dir
            )

            # Generate side-by-side if requested
            if args.side_by_side and args.format == 'terminal':
                result.side_by_side = generate_side_by_side(
                    result.sqlserver_file,
                    result.postgresql_file
                )

            # Format output
            if args.format == 'terminal':
                output_text = format_terminal_output(
                    result,
                    show_diff=not args.no_diff,
                    side_by_side=args.side_by_side
                )
                print(output_text)
            elif args.format == 'markdown':
                output_text = format_markdown_output(result)
                if args.output:
                    args.output.write_text(output_text)
                    print(f"Markdown report written to: {args.output}")
                else:
                    print(output_text)
            elif args.format == 'html':
                output_text = format_html_output(result)
                if args.output:
                    args.output.write_text(output_text)
                    print(f"HTML report written to: {args.output}")
                else:
                    print(output_text)
            elif args.format == 'json':
                output_text = format_json_output(result)
                if args.output:
                    args.output.write_text(output_text)
                    print(f"JSON report written to: {args.output}")
                else:
                    print(output_text)

            return 0 if result.are_identical else 1

        except FileNotFoundError as e:
            print(f"Error: {e}", file=sys.stderr)
            return 3
        except Exception as e:
            print(f"Error during comparison: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
            return 1


if __name__ == "__main__":
    sys.exit(main())
