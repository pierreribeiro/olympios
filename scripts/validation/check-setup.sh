#!/bin/bash
# =============================================================================
# Setup Validation Script
# SQL Server → PostgreSQL Migration Project
# =============================================================================
#
# Purpose: Validate development environment setup
# Usage: ./scripts/validation/check-setup.sh
# Author: Pierre Ribeiro
# Created: 2025-11-24
#
# =============================================================================

set -e  # Exit on error

echo "════════════════════════════════════════════════════════════════════════════"
echo "  Environment Setup Validation"
echo "  SQL Server → PostgreSQL Migration Project"
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

ERRORS=0
WARNINGS=0

# Function to check command existence
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to compare versions
version_ge() {
    # Returns 0 if $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

echo "🔍 Checking Prerequisites..."
echo ""

# =============================================================================
# 1. Python Check
# =============================================================================
echo "1️⃣  Python"
if check_command python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 10 ]; then
        echo "   ✅ Python $PYTHON_VERSION (required: 3.10+)"
    else
        echo "   ❌ Python $PYTHON_VERSION (required: 3.10+)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Python not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 2. Virtual Environment Check
# =============================================================================
echo "2️⃣  Python Virtual Environment"
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "   ✅ Virtual environment activated"
    echo "      Path: $VIRTUAL_ENV"
else
    echo "   ⚠️  Virtual environment not activated"
    echo "      Run: source .venv/bin/activate"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# =============================================================================
# 3. Python Packages Check
# =============================================================================
echo "3️⃣  Python Automation Packages"
REQUIRED_PACKAGES=("sqlparse" "click" "pandas" "rich" "jinja2" "yaml")
PACKAGE_DISPLAY=("sqlparse" "click" "pandas" "rich" "jinja2" "pyyaml")
MISSING_PACKAGES=0

for i in "${!REQUIRED_PACKAGES[@]}"; do
    package="${REQUIRED_PACKAGES[$i]}"
    display="${PACKAGE_DISPLAY[$i]}"

    if python3 -c "import $package" 2>/dev/null; then
        # Get package version
        VERSION=$(python3 -c "import $package; print(getattr($package, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
        echo "   ✅ $display ($VERSION)"
    else
        echo "   ❌ $display (not installed)"
        MISSING_PACKAGES=$((MISSING_PACKAGES + 1))
    fi
done

if [ $MISSING_PACKAGES -gt 0 ]; then
    echo ""
    echo "   ⚠️  Install missing packages:"
    echo "      pip install -r scripts/automation/requirements.txt"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 4. PostgreSQL Check
# =============================================================================
echo "4️⃣  PostgreSQL"
if check_command psql; then
    PSQL_VERSION=$(psql --version 2>&1 | awk '{print $3}')
    PSQL_MAJOR=$(echo $PSQL_VERSION | cut -d. -f1)

    if [ "$PSQL_MAJOR" -ge 16 ]; then
        echo "   ✅ PostgreSQL $PSQL_VERSION (required: 16+)"
    else
        echo "   ⚠️  PostgreSQL $PSQL_VERSION (recommended: 16+)"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check if server is reachable
    if pg_isready &> /dev/null; then
        echo "   ✅ PostgreSQL server is running"
    else
        echo "   ⚠️  PostgreSQL server not reachable"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ PostgreSQL (psql) not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 5. GitHub CLI Check (Optional)
# =============================================================================
echo "5️⃣  GitHub CLI (Optional)"
if check_command gh || [ -f /usr/local/bin/gh ]; then
    if [ -f /usr/local/bin/gh ]; then
        GH_VERSION=$(/usr/local/bin/gh version 2>&1 | head -n1 | awk '{print $3}')
    else
        GH_VERSION=$(gh --version 2>&1 | head -n1 | awk '{print $3}')
    fi
    echo "   ✅ GitHub CLI $GH_VERSION"

    # Check authentication
    GH_BIN=$([ -f /usr/local/bin/gh ] && echo "/usr/local/bin/gh" || echo "gh")
    if $GH_BIN auth status &> /dev/null; then
        echo "   ✅ GitHub authenticated"
    else
        echo "   ⚠️  GitHub not authenticated (optional)"
        echo "      Run: $GH_BIN auth login"
    fi
else
    echo "   ⚠️  GitHub CLI not installed (optional)"
    echo "      See: docs/SETUP-GUIDE.md for installation"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# =============================================================================
# 6. Git Check
# =============================================================================
echo "6️⃣  Git"
if check_command git; then
    GIT_VERSION=$(git --version 2>&1 | awk '{print $3}')
    echo "   ✅ Git $GIT_VERSION"

    # Check Git config
    GIT_USER=$(git config user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config user.email 2>/dev/null || echo "")

    if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
        echo "   ✅ Git configured ($GIT_USER <$GIT_EMAIL>)"
    else
        echo "   ⚠️  Git not configured"
        echo "      Run: git config --global user.name 'Your Name'"
        echo "           git config --global user.email 'you@example.com'"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ Git not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 7. Project Structure Check
# =============================================================================
echo "7️⃣  Project Structure"
REQUIRED_DIRS=(
    "procedures/original"
    "procedures/aws-sct-converted"
    "procedures/corrected"
    "procedures/analysis"
    "scripts/automation"
    "scripts/validation"
    "tests/unit"
    "tracking"
    "docs"
    "templates"
)

MISSING_DIRS=0
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir"
    else
        echo "   ❌ $dir (missing)"
        MISSING_DIRS=$((MISSING_DIRS + 1))
    fi
done

if [ $MISSING_DIRS -gt 0 ]; then
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# 8. Configuration Files Check
# =============================================================================
echo "8️⃣  Configuration Files"
REQUIRED_FILES=(
    "README.md"
    "docs/PROJECT-PLAN.md"
    "docs/SETUP-GUIDE.md"
    "scripts/automation/requirements.txt"
    "scripts/automation/automation-config.json"
    "templates/postgresql-procedure-template.sql"
    "tracking/priority-matrix.csv"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (missing)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    ERRORS=$((ERRORS + 1))
fi
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "════════════════════════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 SUCCESS! Environment setup is complete!"
    echo ""
    echo "✅ All prerequisites met"
    echo "✅ All packages installed"
    echo "✅ All directories present"
    echo "✅ All configuration files found"
    echo ""
    echo "🚀 You're ready to start Sprint 1!"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  PARTIAL SUCCESS - Setup complete with warnings"
    echo ""
    echo "✅ 0 errors"
    echo "⚠️  $WARNINGS warnings"
    echo ""
    echo "You can proceed, but consider resolving warnings."
    echo ""
    exit 0
else
    echo "❌ SETUP INCOMPLETE"
    echo ""
    echo "❌ $ERRORS errors"
    echo "⚠️  $WARNINGS warnings"
    echo ""
    echo "Please resolve errors before proceeding."
    echo "See docs/SETUP-GUIDE.md for detailed instructions."
    echo ""
    exit 1
fi
