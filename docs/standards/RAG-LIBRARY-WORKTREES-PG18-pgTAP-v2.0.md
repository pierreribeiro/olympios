---
document_type: rag_knowledge_library
project: Perseus (DinamoTech)
topic_scope: git-worktrees | postgresql-18 | database-branching | pgtap-tdd | claude-code
created: 2026-04-30
version: 2.0
supersedes: RAG-LIBRARY-WORKTREES-PG18-pgTAP-v1.0.md
v1_status: archived (historical reference only)
total_sources: 38
maintained_by: Pierre Ribeiro + Claude
review_cycle: quarterly
breaking_changes_from_v1:
  - "§ 5.1 (gtr) promoted from 'high' → 'critical' relevance"
  - "§ 3.1–3.13 (repo-manager) demoted from 'critical/high' → 'alternative' relevance"
  - "Reading orders rewritten with gtr-first sequencing"
  - "New entries: § 5.5 (gtr CLAUDE.md), § 5.6 (gtr configuration docs)"
purpose: |
  Curated index of external sources consulted during the Perseus
  worktree+PG18 architecture research, recalibrated after the Phase 2
  spike that confirmed gtr (CodeRabbit) as the recommended orchestrator
  over repo-manager (abs3ntdev) for the DinamoTech gold standard.
usage_pattern: |
  1. Claude scans this file via project_knowledge_search.
  2. Filters entries by `fetch_when` triggers + `relevance_perseus` rating.
  3. Fetches only the URLs whose metadata matches the question scope.
  4. Cites entries in deliverables as: [RAG-LIBRARY-v2 § X.Y].
  5. For historical decisions referencing v1.0, consult v1.0 archive.
---

# 📚 RAG Knowledge Library — Worktrees + PG18 + pgTAP (v2.0)

> **Curated reference library for Project Perseus.**
> Use the YAML frontmatter on each entry as a decision filter before fetching.
> Authority levels: `official-docs` > `vendor-blog` > `technical-blog` > `community-blog`.

## What changed in v2.0

Phase 2 spike (Apr 2026) revealed that **`gtr` (CodeRabbit git-worktree-runner)** is a strictly superior orchestrator for the DinamoTech gold-standard goal versus `repo-manager` (abs3ntdev). Rationale:

- `.gtrconfig` is **commitable** → team-shared standards in version control (the explicit goal)
- 1.4k★ + 25 contributors + Apache 2.0 → reduced abandonment risk
- Native AI-tool integration (`gtr ai my-feature` → Claude Code) → aligned with tactical-executor pattern
- Multi-shell support (bash/zsh/fish + Git Bash on Windows) → broader team compatibility
- Homebrew installation → frictionless onboarding

The trade-off — `gtr` lacks bare-repo lifecycle commands — is resolved with a 15-line one-time bootstrap script. This v2.0 reorganizes the library accordingly.

## Table of Contents

1. [PostgreSQL 18 — Database Cloning & FILE_COPY](#1-postgresql-18--database-cloning--file_copy)
2. [Docker Desktop / macOS / VirtioFS — Known Issues](#2-docker-desktop--macos--virtiofs--known-issues)
3. [repo-manager (abs3ntdev) — Alternative Orchestrator (DEMOTED)](#3-repo-manager-abs3ntdev--alternative-orchestrator-demoted)
4. [Git Worktrees — Concepts & Best Practices](#4-git-worktrees--concepts--best-practices)
5. [gtr (CodeRabbit) — Recommended Orchestrator (PROMOTED)](#5-gtr-coderabbit--recommended-orchestrator-promoted)
6. [Other Worktree Tools & Multi-Branch Implementations](#6-other-worktree-tools--multi-branch-implementations)
7. [Database Branching Patterns (Neon)](#7-database-branching-patterns-neon)
8. [pgTAP & TDD for PostgreSQL](#8-pgtap--tdd-for-postgresql)
9. [Claude Code & AI-Powered Worktree Workflows](#9-claude-code--ai-powered-worktree-workflows)
10. [Reading Order Recommendations (v2.0 — gtr-first)](#10-reading-order-recommendations-v20--gtr-first)

---

## 1. PostgreSQL 18 — Database Cloning & FILE_COPY

> **Status:** Unchanged from v1.0 — the PG18 foundation is independent of the orchestrator choice.

### 1.1 Axial Engineering — Instant per-branch databases with PostgreSQL 18 (FLAGSHIP)

```yaml
url: https://medium.com/axial-engineering/instant-per-branch-databases-with-postgresql-18s-clone-file-copy-and-copy-on-write-filesystems-1b1930bddbaa
title: Instant per-branch databases with PostgreSQL 18's clone, file_copy, and copy-on-write filesystems
author: Bob Ternosky (Axial Engineering)
type: technical-blog
authority: high
freshness: 2026-01
relevance_perseus: critical
fetch_when:
  - explaining the architectural decision
  - quoting concrete benchmarks (90 GB → 1.6 GB, clone time)
  - validating direnv + worktree integration
  - storage drift after template refresh
key_topics: [STRATEGY=FILE_COPY, file_copy_method=clone, APFS clonefile, direnv, storage measurement under CoW]
summary: |
  The blueprint article for the Perseus architecture. Bob Ternosky walks
  through restoring a 90 GB pg_dump as `dev_template`, then cloning it
  into per-branch databases in 2-4 seconds with ~1.6 GB real disk delta
  per branch. Includes direnv integration and discusses RDS limitations.
```

### 1.2 BoringSQL — Instant database clones with PostgreSQL 18

```yaml
url: https://boringsql.com/posts/instant-database-clones/
title: Instant database clones with PostgreSQL 18
type: technical-blog
authority: high
freshness: 2025
relevance_perseus: high
fetch_when:
  - need second-source validation of FILE_COPY syntax
  - quick-reference for benchmark numbers (212 ms / 6 GB)
  - explaining file_copy_method GUC scope
key_topics: [STRATEGY=FILE_COPY, file_copy_method, benchmarks, GUC]
summary: |
  Concise technical walkthrough showing 6 GB DB cloned in 212 ms with
  file_copy_method=clone. Confirms syntax and the requirement that
  STRATEGY must be explicitly FILE_COPY (default WAL_LOG ignores it).
```

### 1.3 pgPedia — file_copy_method

```yaml
url: https://pgpedia.info/f/file_copy_method.html
title: file_copy_method
type: official-docs
authority: high
freshness: 2025
relevance_perseus: high
fetch_when:
  - need authoritative GUC reference
  - syscall-level details (copy_file_range, copyfile)
  - listing of affected commands
key_topics: [file_copy_method, copy vs clone, syscalls, ALTER DATABASE SET TABLESPACE]
summary: |
  Encyclopedia entry covering the GUC's scope: applies to
  `CREATE DATABASE STRATEGY=FILE_COPY` and `ALTER DATABASE SET TABLESPACE`.
  Documents Linux/FreeBSD `copy_file_range()` and macOS `copyfile()` paths.
```

### 1.4 Vonng — Git for Data: Instant PostgreSQL Database Cloning

```yaml
url: https://blog.vonng.com/en/pg/pg-clone/
title: 'Git for Data: Instant PostgreSQL Database Cloning'
type: technical-blog
authority: high
freshness: 2025
relevance_perseus: high
fetch_when:
  - extreme-scale benchmarks (797 GB / 569 ms)
  - "Git for Data" mental-model framing
  - production-grade PostgreSQL on NVMe
key_topics: [database cloning, NVMe benchmarks, CoW filesystems, "Git for Data"]
summary: |
  Vonng (Pigsty creator) frames PG18 cloning as "git for data" with
  extreme benchmarks. Useful for showing upper-bound performance and
  as marketing-grade illustration for stakeholders.
```

### 1.5 Pigsty — Clone Database

```yaml
url: https://pigsty.io/docs/pgsql/backup/database/
title: Clone Database
type: official-docs
authority: high
freshness: 2025
relevance_perseus: medium
fetch_when:
  - listing supported CoW filesystems (xfs, btrfs, zfs, apfs)
  - production opinions on ZFS reliability
  - 18 s → 200 ms benchmark for 30 GB
key_topics: [CoW filesystem support, ZFS warning, FILE_COPY in production]
summary: |
  Pigsty documentation enumerating supported CoW filesystems and
  warning against OpenZFS for production due to historic data
  corruption incidents. Reference for filesystem decision matrix.
```

---

## 2. Docker Desktop / macOS / VirtioFS — Known Issues

> **Status:** Unchanged from v1.0 — these issues motivate "native PG18 on macOS" regardless of orchestrator.

### 2.1 docker/for-mac issue #6243 — VirtioFS permission handling

```yaml
url: https://github.com/docker/for-mac/issues/6243
title: 'VirtioFS is not handling permissions as expected. All mount permissions are owned by root regardless of chown.'
type: github-issue
authority: high
freshness: active
relevance_perseus: medium
fetch_when:
  - justifying "do not bind-mount pgdata over VirtioFS"
  - debugging chown/chmod failures inside containers
key_topics: [VirtioFS, file permissions, bind mounts, macOS]
summary: |
  Open issue documenting VirtioFS bind mounts reporting all files
  as root-owned regardless of `chown`. Direct evidence for the
  "PostgreSQL pgdata should NOT live on VirtioFS" rule.
```

### 2.2 docker/for-mac issue #6812 — VirtioFS permission mapping

```yaml
url: https://github.com/docker/for-mac/issues/6812
title: 'Docker Desktop on macOS with VirtioFS maps file permissions incorrectly'
type: github-issue
authority: high
freshness: active
relevance_perseus: medium
fetch_when:
  - same context as 2.1, complementary thread
key_topics: [VirtioFS, permissions, macOS]
summary: |
  Companion issue to #6243 with additional reproduction steps.
```

### 2.3 docker/for-mac issue #6690 — VirtioFS file corruption

```yaml
url: https://github.com/docker/for-mac/issues/6690
title: 'Docker Desktop for Mac file corruption with VirtioFS with heavy disk activity?'
type: github-issue
authority: high
freshness: active
relevance_perseus: high
fetch_when:
  - justifying "run PG18 natively on macOS, not in Docker"
  - explaining the data-integrity risk of VirtioFS for databases
key_topics: [VirtioFS, file corruption, heavy I/O, data integrity]
summary: |
  Critical issue documenting file corruption under heavy disk activity
  on VirtioFS. Decisive evidence for "native PG18 on macOS APFS".
```

---

## 3. repo-manager (abs3ntdev) — Alternative Orchestrator (DEMOTED)

> **Status change in v2.0:** All entries in this section were **DEMOTED** from `critical`/`high` → `alternative`. Reason: Phase 2 spike confirmed `gtr` is a superior fit for the DinamoTech gold-standard goal. `repo-manager` remains a **valid alternative** when (a) team has strong dependency on the `~/repos/<host>/<owner>/<repo>/<branch>` layout, or (b) bare-repo lifecycle automation is more critical than `.gtrconfig` team-sharing.
>
> All `superseded_by` pointers reference the `gtr` equivalent in § 5.

### 3.1 GitHub repository

```yaml
url: https://github.com/abs3ntdev/repo-manager
title: 'abs3ntdev/repo-manager'
type: github-repo
authority: high
freshness: active (single-maintainer)
relevance_perseus: alternative
superseded_by: § 5.1 (gtr GitHub repo)
fetch_when:
  - evaluating repo-manager as fallback orchestrator
  - bare-repo lifecycle reference
  - confirming hooks.zsh source
key_topics: [ZSH plugin, bare repo layout, post_* hooks, worktree commands]
summary: |
  Source repo for repo-manager ZSH plugin. Demoted in v2.0 because
  gtr offers superior team-sharing (.gtrconfig) and AI integration.
  Still useful when bare-repo automation is the primary requirement.
```

### 3.2 Mintlify wiki — Introduction

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/introduction
title: 'repo-manager — Introduction'
type: official-docs
authority: high
relevance_perseus: alternative
superseded_by: § 5.1 (gtr README)
fetch_when:
  - evaluating repo-manager as fallback
key_topics: [overview, philosophy]
summary: |
  Project introduction. Reference only for fallback evaluation.
```

### 3.3 Mintlify wiki — Installation

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/installation
title: 'repo-manager — Installation'
type: official-docs
authority: high
relevance_perseus: alternative
superseded_by: § 5.1 (gtr Quick Start)
fetch_when:
  - falling back to repo-manager
key_topics: [antidote, oh-my-zsh, zinit, sheldon]
summary: |
  Installation across major ZSH plugin managers. Use only if
  rejecting gtr.
```

### 3.4 Mintlify wiki — Quickstart

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/quickstart
title: 'repo-manager — Quickstart'
type: official-docs
authority: high
relevance_perseus: alternative
superseded_by: § 5.1 (gtr Quick Start)
fetch_when:
  - falling back to repo-manager
key_topics: [getting started, basic commands]
summary: |
  Hands-on quickstart. Demoted; use § 5.1 instead.
```

### 3.5 Mintlify wiki — Worktree Workflow

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/concepts/worktree-workflow
title: 'repo-manager — Worktree Workflow'
type: official-docs
authority: high
relevance_perseus: alternative
superseded_by: § 5.4 (gtr workflow)
fetch_when:
  - reference for the bare-repo + worktree directory model
  - falling back to repo-manager
key_topics: [worktree lifecycle, bare repo, branch isolation]
summary: |
  Conceptual model. Note that gtr does NOT replicate the bare-repo
  layout; the v2.0 architecture replaces it with a manual bootstrap
  script (one-time setup).
```

### 3.6 Mintlify wiki — Directory Layout

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/concepts/directory-layout
title: 'repo-manager — Directory Layout'
type: official-docs
authority: high
relevance_perseus: alternative
fetch_when:
  - inspiration for custom bare-repo layout in gtr setup
key_topics: [directory convention, $REPO_BASE_DIR]
summary: |
  Specification of `~/repos/<host>/<owner>/<repo>/<branch>`.
  In v2.0 architecture, this layout is OPTIONAL and adopted by
  convention via the bootstrap script.
```

### 3.7 Mintlify wiki — Hooks (concept)

```yaml
url: https://mintlify.wiki/abs3ntdev/repo-manager/concepts/hooks
title: 'repo-manager — Hooks'
type: official-docs
authority: high
relevance_perseus: alternative
superseded_by: § 5.6 (gtr configuration docs — hooks section)
fetch_when:
  - falling back to repo-manager
  - comparing hook models (post-only vs declarative)
key_topics: [post_wt_add, post_wt_rm, post_wt_go, post_repo_*]
summary: |
  Conceptual page on the post-only hook system. Important
  comparison reference: gtr offers DECLARATIVE hooks via git config
  (postCreate, postCd) while repo-manager uses ZSH function override.
```

### 3.8–3.13 Other Mintlify wiki pages (consolidated)

```yaml
urls:
  - https://mintlify.wiki/abs3ntdev/repo-manager/worktree/overview
  - https://mintlify.wiki/abs3ntdev/repo-manager/configuration/base-directory
  - https://mintlify.wiki/abs3ntdev/repo-manager/configuration/hooks
  - https://mintlify.wiki/abs3ntdev/repo-manager/guides/migrating-existing-repos
  - https://mintlify.wiki/abs3ntdev/repo-manager/guides/pr-review-workflow
  - https://mintlify.wiki/abs3ntdev/repo-manager/guides/multi-branch-development
type: official-docs
authority: high
relevance_perseus: alternative
fetch_when:
  - falling back to repo-manager
  - migration scenarios from a non-worktree codebase
summary: |
  Remaining repo-manager docs. Consolidated in v2.0 because gtr
  is the recommended path forward. See v1.0 archive for individual
  detailed annotations.
```

---

## 4. Git Worktrees — Concepts & Best Practices

> **Status:** Unchanged from v1.0 — these are tool-agnostic.

### 4.1 safia.rocks — Git worktrees (intro)

```yaml
url: https://blog.safia.rocks/2025/09/03/git-worktrees/
title: Git worktrees
author: Safia Abdalla
type: community-blog
authority: medium
freshness: 2025-09
relevance_perseus: medium
fetch_when:
  - team onboarding to git worktree concept
key_topics: [git worktree basics, mental model]
summary: |
  Beginner-friendly intro. Good for onboarding non-DBA team members.
```

### 4.2 dev.to/metal3d — Git worktree like a boss

```yaml
url: https://dev.to/metal3d/git-worktree-like-a-boss-2j1b
title: 'Git worktree like a boss'
type: community-blog
authority: medium
relevance_perseus: medium
fetch_when:
  - power-user worktree patterns
  - aliases and productivity tips
key_topics: [git worktree, productivity]
summary: |
  Practical productivity-oriented guide.
```

---

## 5. gtr (CodeRabbit) — Recommended Orchestrator (PROMOTED)

> **Status change in v2.0:** All entries in this section were **PROMOTED** to `critical`. Reason: Phase 2 spike confirmed `gtr` aligns with the DinamoTech gold-standard goal (commitable team config, AI integration, broad community).

### 5.1 GitHub repository (FLAGSHIP)

```yaml
url: https://github.com/coderabbitai/git-worktree-runner
title: 'coderabbitai/git-worktree-runner (gtr)'
type: github-repo
authority: high
freshness: active (1.4k★, v2.4.0 Feb 2026, 25 contributors)
relevance_perseus: critical
fetch_when:
  - implementing the v2.0 architecture
  - hook configuration (gtr.hook.postCreate, gtr.hook.postCd)
  - file copying patterns (gtr.copy.include)
  - editor/AI integration syntax
key_topics:
  - bash 3.2+ portable
  - git config-based configuration
  - .gtrconfig team-shared
  - AI tool integration (claude, cursor, aider, codex)
  - Homebrew install (brew install git-gtr)
  - clean --merged with gh/glab
  - shell completions (bash/zsh/fish)
summary: |
  Primary reference for the v2.0 Perseus architecture. README covers
  installation, all commands (new, rm, mv, copy, run, list, clean,
  config, doctor, adapter), and configuration. Critical: gtr ASSUMES
  a standard clone — no bare-repo lifecycle commands. The v2.0
  architecture compensates with a one-time bootstrap script.
caveat: |
  README documents `gtr.hook.postCreate` and `gtr.hook.postCd` but
  does NOT confirm whether `gtr.hook.preRemove` exists. Validate
  during PoC by consulting docs/configuration.md in the repo.
```

### 5.2 gtr Configuration Documentation (NEW in v2.0)

```yaml
url: https://github.com/coderabbitai/git-worktree-runner/blob/main/docs/configuration.md
title: 'gtr — Configuration Reference'
type: official-docs
authority: high
relevance_perseus: critical
fetch_when:
  - exhaustive list of all hooks (validate preRemove existence)
  - file-copy pattern syntax (glob support, includeDirs/excludeDirs)
  - environment variables
  - shell-completion troubleshooting
key_topics: [hooks, copy patterns, env vars, completions]
summary: |
  Authoritative reference for every gtr config key. MUST be consulted
  during the PoC phase to validate pre-remove hook availability and
  full hook event taxonomy.
```

### 5.3 gtr Advanced Usage (NEW in v2.0)

```yaml
url: https://github.com/coderabbitai/git-worktree-runner/blob/main/docs/advanced-usage.md
title: 'gtr — Advanced Usage'
type: official-docs
authority: high
relevance_perseus: high
fetch_when:
  - parallel AI agent development patterns
  - --force + --name for multiple worktrees on same branch
  - .gtr-setup.sh custom workflow scripts
  - CI/CD non-interactive mode
key_topics: [parallel agents, custom workflows, CI/CD]
summary: |
  Patterns for multi-agent parallel development — directly applicable
  to the Perseus Sprint 9 model where Claude Code handles tactical
  procedure migration in parallel branches.
```

### 5.4 gtr Troubleshooting (NEW in v2.0)

```yaml
url: https://github.com/coderabbitai/git-worktree-runner/blob/main/docs/troubleshooting.md
title: 'gtr — Troubleshooting'
type: official-docs
authority: high
relevance_perseus: medium
fetch_when:
  - platform-specific issues (Windows Git Bash, Linux distros)
  - shell completion failures
  - architecture details
key_topics: [troubleshooting, platform-specific]
summary: |
  Reference for platform-specific issues. Consult during onboarding
  of non-macOS developers.
```

### 5.5 gtr CLAUDE.md (NEW in v2.0)

```yaml
url: https://github.com/coderabbitai/git-worktree-runner/blob/main/CLAUDE.md
title: 'gtr — CLAUDE.md (project memory for Claude Code)'
type: project-memory
authority: high
relevance_perseus: high
fetch_when:
  - meta-reference for how a CLAUDE.md should be structured
  - inspiration for Perseus's own root CLAUDE.md
key_topics: [Claude Code project memory, agent guidance]
summary: |
  The gtr project's own CLAUDE.md — useful as a template for how
  Perseus should structure its root and per-branch CLAUDE.md files.
```

---

## 6. Other Worktree Tools & Multi-Branch Implementations

### 6.1 Adam Hancock — devctl multi-worktree development

```yaml
url: https://adamhancock.co.uk/blog/devctl-multi-worktree-development
title: 'devctl multi-worktree development'
type: technical-blog
authority: medium
freshness: 2026-01
relevance_perseus: medium
fetch_when:
  - hash-based deterministic port allocation algorithm
  - Caddy Admin API integration patterns
key_topics: [devctl2, deterministic ports, Caddy, pg_dump cloning]
summary: |
  Inspiration for hash-based port allocation. Demoted vs v1.0 because
  gtr does not need port management for the DB layer (single-instance
  multi-DB), but the algorithm is still useful for app services.
```

### 6.2 AgenticSec/sprout

```yaml
url: https://github.com/AgenticSec/sprout
title: 'AgenticSec/sprout'
type: github-repo
authority: medium
freshness: active (v0.7.0)
relevance_perseus: low
fetch_when:
  - .env.example templating with placeholders ({{ branch() }}, {{ auto_port() }})
key_topics: [Python tool, env templating, branch placeholders]
summary: |
  Python-based worktree manager with env templating. Largely
  superseded by gtr's `gtr.copy.include` directive in v2.0.
```

### 6.3 nwiizo/ccswarm

```yaml
url: https://github.com/nwiizo/ccswarm
title: 'nwiizo/ccswarm'
type: github-repo
authority: low (experimental)
relevance_perseus: low
fetch_when:
  - exploring future multi-agent orchestration
key_topics: [multi-agent, Claude Code, worktree isolation]
summary: |
  Experimental orchestration layer. Aspirational — gtr + Claude
  Code native --worktree covers Perseus's needs in v2.0.
```

---

## 7. Database Branching Patterns (Neon)

> **Status:** Unchanged from v1.0.

### 7.1 Neon — Git worktrees with Neon branching

```yaml
url: https://neon.com/guides/git-worktrees-neon-branching
title: Git worktrees with Neon database branching
type: vendor-blog
authority: high
relevance_perseus: high
fetch_when:
  - canonical pattern reference (worktree → DB branching)
  - post-checkout Git hook recipe
key_topics: [Neon branching, post-checkout hook, worktree-DB binding]
summary: |
  Canonical guide for the worktree → DB binding pattern. v2.0
  adopts the same pattern with local PG18 STRATEGY=FILE_COPY in
  place of the Neon API.
```

### 7.2 Neon — Automating Neon branch creation with githooks

```yaml
url: https://neon.com/blog/automating-neon-branch-creation-with-githooks
title: Automating Neon branch creation with githooks
author: Raouf Chebri
type: vendor-blog
authority: high
freshness: 2023
relevance_perseus: medium
fetch_when:
  - post-checkout heuristics (when gtr's postCreate is not enough)
  - reflog-counting workaround
key_topics: [post-checkout hook, reflog detection, env file generation]
summary: |
  Foundational article. In v2.0, gtr's postCreate replaces the
  fragile post-checkout heuristic, so this is mainly a fallback ref.
```

---

## 8. pgTAP & TDD for PostgreSQL

> **Status:** Unchanged from v1.0 — tool-agnostic.

### 8.1 itissid/pypgTAP

```yaml
url: https://github.com/itissid/pypgTAP
title: 'itissid/pypgTAP'
type: github-repo
authority: medium
relevance_perseus: high
fetch_when:
  - throwaway-server-per-test pattern
  - Python integration for pgTAP
key_topics: [throwaway postgres, ephemeral cluster, Python wrapper]
summary: |
  Conceptually related to the "ephemeral DB per procedure test"
  pattern; operates at cluster level (heavier than per-DB).
```

### 8.2 naiquevin/tapestry

```yaml
url: https://github.com/naiquevin/tapestry
title: 'naiquevin/tapestry'
type: github-repo
authority: medium
relevance_perseus: high
fetch_when:
  - co-generating production SQL + pgTAP tests
  - Jinja-templated SQL workflows
key_topics: [Jinja templates, SQL + pgTAP co-generation, Rust CLI]
summary: |
  Strong fit for Perseus where SQL Server procs are translated to
  PostgreSQL — Jinja templates ensure tests exercise the exact SQL
  the application runs.
```

### 8.3 Vbilopav — Unit Testing and TDD with PostgreSQL is Easy

```yaml
url: https://medium.com/@vbilopav/unit-testing-and-tdd-with-postgresql-is-easy-b6f14623b8cf
title: Unit testing and TDD with PostgreSQL is easy
type: community-blog
authority: medium
relevance_perseus: medium
fetch_when:
  - TDD discipline framing for PostgreSQL
key_topics: [TDD, pgTAP, testing discipline]
summary: |
  Conceptual TDD article. Background reading for team training.
```

### 8.4 Edouard Courty — Master the Art of Data Fixtures

```yaml
url: https://medium.com/@edouard.courty/master-the-art-of-data-fixtures-10c27cdd6f18
title: Master the art of data fixtures
type: community-blog
authority: medium
relevance_perseus: medium
fetch_when:
  - philosophical defense of "fresh fixture per test"
key_topics: [fixtures, test isolation, shared state pitfalls]
summary: |
  Argues for fresh-fixture-per-test discipline that underpins the
  ephemeral-DB pattern in v2.0.
```

---

## 9. Claude Code & AI-Powered Worktree Workflows

> **Status:** Unchanged from v1.0 — Claude Code's native worktree support is independent of orchestrator choice.

### 9.1 Anthropic — Common Workflows (official Claude Code docs)

```yaml
url: https://code.claude.com/docs/en/common-workflows
title: Claude Code — Common Workflows
type: official-docs
authority: high
freshness: active
relevance_perseus: critical
fetch_when:
  - canonical reference for --worktree flag
  - WorktreeCreate / WorktreeRemove hook payload schema
  - subagent isolation: worktree
key_topics: [--worktree flag, hooks, subagent isolation, settings.json]
summary: |
  Authoritative source for Claude Code worktree integration. Always
  check before implementing hook payloads (schema may evolve).
note_v2: |
  In v2.0, prefer using `gtr ai my-feature` over `claude --worktree`
  when working from inside a gtr-managed repo — gtr injects worktree
  context cleanly and handles environment setup via postCreate.
```

### 9.2 Verdent AI — Claude Code Worktree Setup Guide

```yaml
url: https://www.verdent.ai/guides/claude-code-worktree-setup-guide
title: 'Claude Code Worktree Explained: Setup & Parallel Agents'
type: vendor-blog
authority: medium
relevance_perseus: high
fetch_when:
  - parallel agent patterns walkthrough
key_topics: [Claude Code, worktree, parallel agents, setup]
summary: |
  Practical walkthrough complementing official docs.
```

### 9.3 claudefa.st — Claude Code Worktrees: Parallel Sessions

```yaml
url: https://claudefa.st/blog/guide/development/worktree-guide
title: 'Claude Code Worktrees: Parallel Sessions Without Conflicts'
type: community-blog
authority: medium
relevance_perseus: medium
fetch_when:
  - alternative perspective on parallel sessions
key_topics: [Claude Code, parallel sessions, conflict avoidance]
summary: |
  Community guide. Secondary reference; check official docs first.
```

---

## 10. Reading Order Recommendations (v2.0 — gtr-first)

### 10.1 New to the project (onboarding)

```
1. § 4.1 (safia.rocks)         → mental model of git worktree
2. § 5.1 (gtr README)          → recommended orchestrator
3. § 1.1 (Axial flagship)      → why PG18 clone matters
4. § 7.1 (Neon guide)          → conceptual analog
5. § 9.1 (Claude Code docs)    → AI integration
```

### 10.2 Implementing the v2.0 hooks

```
1. § 5.1 (gtr README)          → command surface
2. § 5.2 (gtr config docs)     → exhaustive hook taxonomy
3. § 5.3 (gtr advanced usage)  → custom workflow scripts
4. § 1.1 (Axial)               → SQL provisioning logic
```

### 10.3 Justifying the architecture to leadership

```
1. § 1.1 (Axial benchmarks)    → concrete numbers (90 GB → 1.6 GB)
2. § 1.4 (Vonng)               → extreme-scale validation
3. § 2.3 (Docker corruption)   → why NOT use Docker for pgdata
4. § 5.1 (gtr 1.4k★)           → orchestrator maturity evidence
```

### 10.4 Writing the pgTAP test runner

```
1. § 8.1 (pypgTAP)             → throwaway-server pattern
2. § 8.2 (Tapestry)            → SQL+test co-generation
3. § 8.4 (Edouard Courty)      → fixtures discipline
4. § 8.3 (Vbilopav)            → TDD framing
```

### 10.5 Setting up parallel Claude Code agents

```
1. § 5.1 + § 5.3 (gtr)         → gtr ai integration
2. § 9.1 (Claude Code docs)    → --worktree, WorktreeCreate hook
3. § 9.2 (Verdent)             → practical examples
```

### 10.6 Falling back to repo-manager (rare)

```
1. § 3.1 (repo-manager repo)   → if gtr is rejected
2. § 3.7 (hooks concept)       → ZSH override mechanism
3. § 3.11 (migrating repos)    → bare-repo conversion
```

---

## 📋 Maintenance Log

| Version | Date       | Changes                                                              | Author              |
|---------|-----------|-----------------------------------------------------------------------|---------------------|
| 1.0     | 2026-04-30 | Initial library compiled from Perseus research                       | Pierre + Claude     |
| 2.0     | 2026-04-30 | Phase 2 spike: gtr promoted to critical, repo-manager demoted to alternative; new entries § 5.2-5.5; reading orders rewritten gtr-first | Pierre + Claude     |

---

## 🎯 How Claude uses this library (instruction to future-self, v2.0)

> When asked about git worktrees + PG18 + pgTAP topics in the Perseus project,
> Claude SHOULD:
>
> 1. First call `project_knowledge_search` for this RAG library file (v2.0 baseline).
> 2. Scan entries by `relevance_perseus` and `fetch_when` triggers matching the question.
> 3. **Prefer entries promoted in v2.0** (§ 5.x — gtr) over demoted entries (§ 3.x — repo-manager) unless the user explicitly asks for the alternative path.
> 4. If a `superseded_by` pointer exists, follow it instead of fetching the demoted source.
> 5. Decide whether the YAML metadata + summary is sufficient (skip fetch) OR
>    whether the full content is needed (fetch URL).
> 6. When citing, use format: `[RAG-LIBRARY-v2 § X.Y]` (e.g., `[RAG-LIBRARY-v2 § 5.1]`).
> 7. For historical-context questions ("why did we choose X in v1.0?"), consult v1.0 archive and explain the supersession.
> 8. If the question falls outside the topic_scope, do NOT use this library — fall back to fresh web research.

---

*End of RAG Library v2.0 — Project Perseus*
*Supersedes v1.0 — historical reference preserved in project knowledge*
