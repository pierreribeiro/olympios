#!/usr/bin/env bash
# =============================================================================
# Phase Gate Check Script Runner
# =============================================================================
# Purpose: Execute the phase gate check validation script
# Usage: ./scripts/validation/run-phase-gate-check.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_SCRIPT="${SCRIPT_DIR}/phase-gate-check.sql"

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-perseus_dev}"
DB_USER="${DB_USER:-perseus_admin}"

echo "========================================================================="
echo "Phase Gate Check - Phase 2 Foundational"
echo "========================================================================="
echo ""
echo "Database: ${DB_NAME}"
echo "Host: ${DB_HOST}:${DB_PORT}"
echo "User: ${DB_USER}"
echo ""

# Check if SQL script exists
if [[ ! -f "${SQL_SCRIPT}" ]]; then
    echo -e "${RED}ERROR: SQL script not found: ${SQL_SCRIPT}${NC}"
    exit 1
fi

# Check if Docker container is running (for local development)
if command -v docker &> /dev/null; then
    if docker ps --format '{{.Names}}' | grep -q "perseus-postgres-dev"; then
        echo "Running against Docker container: perseus-postgres-dev"
        echo ""
        docker exec -i perseus-postgres-dev psql -U "${DB_USER}" -d "${DB_NAME}" -f - < "${SQL_SCRIPT}"
        EXIT_CODE=$?
    else
        echo "Docker container not found, trying direct psql connection..."
        echo ""
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${SQL_SCRIPT}"
        EXIT_CODE=$?
    fi
else
    # Direct psql execution
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${SQL_SCRIPT}"
    EXIT_CODE=$?
fi

echo ""
if [[ ${EXIT_CODE} -eq 0 ]]; then
    echo -e "${GREEN}Phase gate check completed successfully${NC}"
    exit 0
else
    echo -e "${RED}Phase gate check failed with exit code: ${EXIT_CODE}${NC}"
    exit ${EXIT_CODE}
fi
