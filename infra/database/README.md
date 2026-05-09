# Perseus PG18 Infrastructure

Native macOS PG18 (no Docker) provisioning for Project Perseus.

## Quick Start

```bash
# 1. Prerequisites
brew install postgresql@18

# 2. Configure
cp .env.example .env  # adjust if needed

# 3. Initialize
./init-db.sh init     # prints generated password — add to ~/.pgpass

# 4. Verify
./init-db.sh status
./init-db.sh shell
```

## Role hierarchy

- **`postgres`** — cluster superuser (DBA admin). Connects via local trust (no password on dev machines).
- **`perseus_owner`** — application owner. Owns `perseus_dev` and `perseus*` schemas. Password in `~/.pgpass`.

## Commands

| Command | Purpose |
|---|---|
| `./init-db.sh init` | First-time provisioning |
| `./init-db.sh start` | Start cluster |
| `./init-db.sh stop` | Stop cluster |
| `./init-db.sh restart` | Restart |
| `./init-db.sh status` | Health check |
| `./init-db.sh shell` | psql session as `perseus_owner` |
| `./init-db.sh destroy` | Wipe PGDATA (destructive) |
| `./init-db.sh recreate` | destroy + init + start |

## Configuration

All settings come from `.env`. Never commit `.env` (gitignored).
See `.env.example` for the full list with defaults.

## Layout

- Repository: `infra/database/` (this directory)
- Data directory: `$PERSEUS_PGDATA_DIR` (defaults to `~/workspace/sharing/.../postgres/v18/pgdata`)
- Logs: `$PERSEUS_PGDATA_DIR/pg_log/`
- Password: `~/.pgpass` (generated at init, only for `perseus_owner`)

## Documentation

- Architecture: `docs/architecture/ARCHITECTURE-PERSEUS-v2.1.md`
- Workflow: `docs/architecture/WORKFLOW-PERSEUS-v2.1.md`
- Deployment: `docs/architecture/deployment-perseus-infrastructure.md`