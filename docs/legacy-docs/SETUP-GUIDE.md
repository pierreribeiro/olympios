# Setup Guide - Environment Configuration

## 📋 Overview

This guide helps you set up the development environment for the SQL Server → PostgreSQL migration project.

**Estimated Time:** 15-30 minutes
**Last Updated:** 2025-11-25

---

## ✅ Prerequisites Checklist

Before starting, verify you have:

- [ ] PostgreSQL 16+ installed
- [ ] Python 3.10+ installed
- [ ] Git installed
- [ ] psql CLI accessible
- [ ] Internet connection (for package downloads)

---

## 🐍 Python Automation Setup

### 1. Verify Python Version

```bash
python3 --version
# Required: Python 3.10 or higher
```

### 2. Create Virtual Environment

```bash
# Navigate to project root
cd sqlserver-to-postgresql-migration

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
# Linux/Mac:
source .venv/bin/activate

# Windows:
.venv\Scripts\activate

# Verify activation (should show .venv path)
which python
```

### 3. Install Automation Dependencies

```bash
# Install all required packages
pip install -r scripts/automation/requirements.txt

# Verify installation
pip list | grep -E "sqlparse|click|pandas|rich"
```

**Expected Output:**
```
click            8.1.7
pandas           2.1.0
rich             13.6.0
sqlparse         0.4.3
```

### 4. Test Python Setup

```bash
# Quick test
python -c "import sqlparse, click, pandas, rich; print('✅ All packages installed')"
```

---

## 🔧 GitHub CLI Setup (Optional but Recommended)

The GitHub CLI (`gh`) enables automation for issues, PRs, and releases.

**Status:** Optional (but useful for GitHub integration)

### Installation Methods

#### Linux (Debian/Ubuntu)

```bash
# Option 1: Official Repository
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Option 2: Snap (simpler)
sudo snap install gh
```

#### macOS

```bash
# Using Homebrew
brew install gh

# Using MacPorts
sudo port install gh
```

#### Windows

```powershell
# Using Winget
winget install --id GitHub.cli

# Using Scoop
scoop install gh

# Using Chocolatey
choco install gh
```

#### Alternative: Manual Binary Installation (Network Restrictions Workaround)

If you're working in a restricted environment (e.g., Claude Code Web, Docker containers, or behind corporate firewalls) where package managers fail, use this manual installation method:

**This method successfully overcomes:**
- ❌ Blocked apt/yum repositories
- ❌ Failed .deb/.rpm package installations
- ❌ Network redirects to error pages
- ❌ Missing package manager dependencies

**Installation Steps:**

```bash
# 1. Download the latest GitHub CLI tarball
# Using wget (works even with network restrictions)
wget --no-check-certificate -O /tmp/gh_linux_amd64.tar.gz \
  https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_linux_amd64.tar.gz

# 2. Verify download
file /tmp/gh_linux_amd64.tar.gz
# Should show: gzip compressed data

# 3. Extract the tarball
cd /tmp
tar -xzf gh_linux_amd64.tar.gz

# 4. Install to system path
sudo cp gh_*/bin/gh /usr/local/bin/gh
sudo chmod +x /usr/local/bin/gh

# 5. Verify installation
/usr/local/bin/gh version
# Expected: gh version 2.83.1 (2025-11-13)

# 6. Optional: Create alias for convenience
echo 'alias gh=/usr/local/bin/gh' >> ~/.bashrc
source ~/.bashrc
```

**For other architectures, replace the download URL:**

```bash
# ARM64 (Apple Silicon, ARM servers)
wget --no-check-certificate -O /tmp/gh_linux_arm64.tar.gz \
  https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_linux_arm64.tar.gz

# macOS AMD64
wget --no-check-certificate -O /tmp/gh_macos_amd64.zip \
  https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_macOS_amd64.zip

# macOS ARM64 (Apple Silicon)
wget --no-check-certificate -O /tmp/gh_macos_arm64.zip \
  https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_macOS_arm64.zip
```

**Check latest releases at:** https://github.com/cli/cli/releases/latest

**Usage Notes:**

In restricted environments, you may need to use the full path:

```bash
# If 'gh' command is sandboxed/restricted:
/usr/local/bin/gh issue list
/usr/local/bin/gh pr create
/usr/local/bin/gh repo view

# With alias configured:
gh issue list  # Uses /usr/local/bin/gh
```

**Why This Works:**

1. **wget with --no-check-certificate** bypasses SSL verification issues
2. **Tarball extraction** doesn't require package manager dependencies
3. **Manual binary installation** bypasses system package restrictions
4. **Statically linked binary** has no external dependencies
5. **/usr/local/bin** is typically in PATH and writable by root

**Troubleshooting:**

```bash
# If download fails, try curl instead:
curl -L -o /tmp/gh_linux_amd64.tar.gz \
  https://github.com/cli/cli/releases/download/v2.83.1/gh_2.83.1_linux_amd64.tar.gz

# If extraction shows "Permission denied":
sudo chown $USER /tmp/gh_linux_amd64.tar.gz
tar -xzf /tmp/gh_linux_amd64.tar.gz

# If /usr/local/bin doesn't exist:
sudo mkdir -p /usr/local/bin
sudo chmod 755 /usr/local/bin

# Verify the binary works:
/usr/local/bin/gh --version
/usr/local/bin/gh --help
```

### Verify Installation

```bash
gh --version
# Expected: gh version 2.x.x or higher

# If the above fails in restricted environments, try:
/usr/local/bin/gh --version
```

### Authenticate with GitHub

```bash
# Interactive authentication
gh auth login
# Or in restricted environments:
/usr/local/bin/gh auth login

# Follow the prompts:
# 1. Select: GitHub.com
# 2. Select: HTTPS
# 3. Select: Login with a web browser
# 4. Copy the one-time code and press Enter
# 5. Paste code in browser and authorize
```

### Test GitHub CLI

```bash
# Test authentication
gh auth status

# Test issue listing (from project directory)
gh issue list

# Test PR listing
gh pr list

# If using manual installation, use full path:
/usr/local/bin/gh auth status
/usr/local/bin/gh issue list
/usr/local/bin/gh pr list
```

### GitHub CLI in Proxy Environments (Claude Code Web Workaround)

**Problem:**

In proxy environments like Claude Code Web, Docker containers, or corporate networks with Git proxies, the `gh` CLI may fail with:

```
none of the git remotes configured for this repository point to a known GitHub host
```

This happens because Git remotes use proxy URLs instead of direct GitHub URLs:

```bash
# Example proxy remote (doesn't work with gh CLI)
origin: http://local_proxy@127.0.0.1:18276/git/pierreribeiro/sqlserver-to-postgresql-migration
```

**Solution: Add Direct GitHub Remote + Use --repo Flag**

1. **Add a direct GitHub remote** (in addition to the proxy remote):

```bash
# Add direct GitHub remote (replace with your repo)
git remote add github https://github.com/pierreribeiro/sqlserver-to-postgresql-migration.git

# Verify both remotes exist
git remote -v
# Expected output:
# origin    http://local_proxy@... (proxy, used for push/pull)
# github    https://github.com/... (direct URL for gh CLI)
```

2. **Use the --repo flag** with all `gh` commands:

```bash
# Creating Pull Requests
gh pr create --repo pierreribeiro/sqlserver-to-postgresql-migration \
  --title "Your PR Title" \
  --body "Your PR Description"

# Managing Issues
gh issue close 21 --repo pierreribeiro/sqlserver-to-postgresql-migration \
  --comment "Completed in Sprint 4"

gh issue list --repo pierreribeiro/sqlserver-to-postgresql-migration

# Viewing Repository Info
gh repo view --repo pierreribeiro/sqlserver-to-postgresql-migration
```

**Important Notes:**

- **Don't use the `github` remote for git operations** (push/pull/fetch) - continue using `origin`
- The `github` remote is ONLY for `gh` CLI to recognize the repository
- Always specify `--repo owner/repo-name` when running `gh` commands
- This workaround is specific to environments where Git operations go through proxies

**Complete Example Workflow:**

```bash
# 1. Add GitHub remote (one-time setup)
git remote add github https://github.com/pierreribeiro/sqlserver-to-postgresql-migration.git

# 2. Continue using origin for Git operations
git push -u origin claude/feature-branch

# 3. Use --repo flag for GitHub CLI operations
gh pr create --repo pierreribeiro/sqlserver-to-postgresql-migration \
  --title "feat: Add new procedure correction" \
  --body "$(cat <<'EOF'
## Summary
- Corrected GetMaterialByRunProperties procedure
- Resolved 13 AWS SCT warnings
- Added comprehensive unit tests

## Test Plan
- [x] Syntax validation
- [x] Unit tests created
- [ ] Integration testing pending
EOF
)"

# 4. Close related issue
gh issue close 21 --repo pierreribeiro/sqlserver-to-postgresql-migration \
  --comment "Completed in PR #32"
```

**Verification:**

Test that the workaround is working:

```bash
# This should work now (shows repo info)
gh repo view --repo pierreribeiro/sqlserver-to-postgresql-migration

# This should also work (lists issues)
gh issue list --repo pierreribeiro/sqlserver-to-postgresql-migration
```

**When This Workaround Is Needed:**

- ✅ Claude Code Web environment
- ✅ Docker containers with Git proxy configuration
- ✅ Corporate networks with proxy Git servers
- ✅ Any environment where `git remote -v` shows proxy URLs (127.0.0.1, local_proxy, etc.)
- ❌ Standard local development (direct GitHub access)
- ❌ GitHub Codespaces (has built-in GitHub integration)

---

## 🗄️ PostgreSQL Setup Verification

### 1. Verify PostgreSQL Installation

```bash
# Check PostgreSQL version
psql --version
# Required: PostgreSQL 16 or higher

# Check if server is running
pg_isready
```

### 2. Test Database Connection

```bash
# Connect to your database
psql -U your_username -d perseus_dev

# Or if using default:
psql -d postgres

# Once connected, verify version:
SELECT version();
```

### 3. Verify Required Extensions

```sql
-- Check if plpgsql is available
SELECT * FROM pg_available_extensions
WHERE name = 'plpgsql';

-- Create test function to verify
CREATE OR REPLACE FUNCTION test_setup()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN 'PostgreSQL setup OK';
END;
$$;

-- Test it
SELECT test_setup();
-- Expected: "PostgreSQL setup OK"

-- Clean up
DROP FUNCTION test_setup();
```

---

## 📦 Project Structure Validation

### Verify Directory Structure

```bash
# Run from project root
ls -la procedures/original/
ls -la procedures/aws-sct-converted/
ls -la procedures/corrected/
ls -la procedures/analysis/
ls -la scripts/automation/
ls -la tests/unit/
ls -la tracking/

# Check for key files
ls -la docs/PROJECT-PLAN.md
ls -la templates/postgresql-procedure-template.sql
ls -la tracking/priority-matrix.csv
ls -la scripts/automation/requirements.txt
ls -la scripts/automation/automation-config.json
```

---

## 🧪 Complete Setup Test

### Run Full Environment Check

```bash
#!/bin/bash
# Save as: scripts/validation/check-setup.sh

echo "🔍 Checking environment setup..."

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo "✅ Python $PYTHON_VERSION"
else
    echo "❌ Python not found"
fi

# Check Virtual Environment
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "✅ Virtual environment activated"
else
    echo "⚠️  Virtual environment not activated"
fi

# Check Python packages
if python3 -c "import sqlparse" 2>/dev/null; then
    echo "✅ Python automation packages installed"
else
    echo "❌ Python automation packages missing"
fi

# Check PostgreSQL
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | awk '{print $3}')
    echo "✅ PostgreSQL $PSQL_VERSION"
else
    echo "❌ PostgreSQL not found"
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n1 | awk '{print $3}')
    echo "✅ GitHub CLI $GH_VERSION"
else
    echo "⚠️  GitHub CLI not installed (optional)"
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo "✅ Git $GIT_VERSION"
else
    echo "❌ Git not found"
fi

echo ""
echo "🎯 Setup validation complete!"
```

### Run the Check

```bash
# Make script executable
chmod +x scripts/validation/check-setup.sh

# Run validation
./scripts/validation/check-setup.sh
```

**Expected Output:**
```
🔍 Checking environment setup...
✅ Python 3.11.14
✅ Virtual environment activated
✅ Python automation packages installed
✅ PostgreSQL 16.x
✅ GitHub CLI 2.x.x
✅ Git 2.x.x

🎯 Setup validation complete!
```

---

## 🔧 Troubleshooting

### Python Issues

**Problem:** `python3: command not found`
```bash
# Linux/Ubuntu
sudo apt update && sudo apt install python3 python3-pip python3-venv

# macOS
brew install python3

# Verify
python3 --version
```

**Problem:** `pip install` fails
```bash
# Upgrade pip
python3 -m pip install --upgrade pip

# Retry installation
pip install -r scripts/automation/requirements.txt
```

**Problem:** Permission denied
```bash
# Don't use sudo! Use virtual environment instead
python3 -m venv .venv
source .venv/bin/activate
pip install -r scripts/automation/requirements.txt
```

### PostgreSQL Issues

**Problem:** `psql: command not found`
```bash
# Add PostgreSQL to PATH
export PATH=/usr/lib/postgresql/16/bin:$PATH

# Or install PostgreSQL client
sudo apt install postgresql-client-16
```

**Problem:** Connection refused
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start if stopped
sudo systemctl start postgresql

# Enable auto-start
sudo systemctl enable postgresql
```

### GitHub CLI Issues

**Problem:** `gh: command not found` (Linux)
```bash
# If installed via snap, add to PATH
export PATH=/snap/bin:$PATH

# Or use full path
/snap/bin/gh --version
```

**Problem:** Authentication fails
```bash
# Logout and retry
gh auth logout
gh auth login

# Check status
gh auth status
```

---

## 📝 Configuration Files

### Create logs directory

```bash
mkdir -p logs
touch logs/.gitkeep
```

### Verify Configuration Files

```bash
# Check automation config
cat scripts/automation/automation-config.json | jq .

# Check requirements
cat scripts/automation/requirements.txt
```

---

## 🎯 Next Steps

After completing setup:

1. **Verify Everything Works**
   ```bash
   ./scripts/validation/check-setup.sh
   ```

2. **Read the Project Plan**
   ```bash
   cat docs/PROJECT-PLAN.md
   ```

3. **Review Priority Matrix**
   ```bash
   cat tracking/priority-matrix.csv
   ```

4. **Start with Analysis Phase**
   - Select a procedure from priority matrix
   - Use automation scripts (when implemented)
   - Follow the template in `templates/`

---

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/16/)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Python Virtual Environments](https://docs.python.org/3/tutorial/venv.html)
- [Project Plan](PROJECT-PLAN.md)

---

## ✅ Setup Complete Checklist

Mark each item when complete:

- [ ] Python 3.10+ installed and verified
- [ ] Virtual environment created and activated
- [ ] All Python packages installed successfully
- [ ] PostgreSQL 16+ accessible via psql
- [ ] Can connect to Perseus database
- [ ] GitHub CLI installed (optional)
- [ ] GitHub CLI authenticated (if installed)
- [ ] Git configured with username/email
- [ ] All project directories present
- [ ] Configuration files created
- [ ] Setup validation script runs without errors

**Once all items are checked, you're ready to begin Sprint 1! 🚀**

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)
**Last Updated:** 2025-11-24
**Version:** 1.0
