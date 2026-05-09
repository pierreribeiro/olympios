# 📊 SQL Server Dependency Analysis - Lote 1: Stored Procedures
## Perseus Database Migration Project - DinamoTech

**Analysis Date:** 2025-12-15  
**Analyst:** Pierre Ribeiro + Claude (Database Expert)  
**Scope:** 21 Stored Procedures in `source/original/sqlserver/Stored-Procedures/`  
**Repository:** pierreribeiro/sqlserver-to-postgresql-migration

---

## 🎯 Executive Summary

This document provides a comprehensive dependency analysis of all 21 stored procedures in the Perseus SQL Server database. Each procedure has been analyzed to identify:
- **WHAT it references** (Tables, Functions, Views, Types, other SPs)
- **WHO references it** (Functions, Views, Types, other SPs)

### Key Findings

| Category | Count | Critical Dependencies |
|----------|-------|----------------------|
| **Total SPs Analyzed** | 21 | 100% coverage |
| **Core Material Processing** | 11 | Material graph management |
| **MS Replication** | 6 | SQL Server replication support |
| **Utility/Update** | 4 | Data maintenance |
| **Critical Tables** | 8 | m_upstream, m_downstream, material_transition, transition_material |
| **Critical Functions** | 8 | McGet* family, Get* family |
| **Critical Types** | 1 | GooList |

---

## 📋 Detailed Dependency Analysis

### 1. Core Material Processing Procedures

#### 1.1 `dbo.ReconcileMUpstream` ⭐ **HIGH COMPLEXITY**

**Purpose:** Reconciles material upstream relationships by processing dirty leaves.

**Dependencies - WHAT it references:**
- **Tables:**
  - `m_upstream` (R/W) - Main upstream tracking table
  - `m_upstream_dirty_leaves` (R/D) - Dirty nodes needing reconciliation
- **Types:**
  - `GooList` - Table-valued parameter type
- **Functions:**
  - `dbo.McGetUpStreamByList()` - Recursive upstream calculation

**Referenced By - WHO references it:**
- **Scheduled Jobs:** Database maintenance jobs (assumed)
- **Triggers/Applications:** External ETL processes (inferred)

**Complexity Score:** 9/10
**Business Criticality:** HIGH - Core material lineage tracking

---

#### 1.2 `dbo.ProcessSomeMUpstream` ⭐ **HIGH COMPLEXITY**

**Purpose:** Processes a batch of materials to update their upstream relationships.

**Dependencies - WHAT it references:**
- **Tables:**
  - `m_upstream` (R/W) - Upstream relationship table
- **Types:**
  - `GooList` - Input/output parameter type (dirty_in, clean_in)
- **Functions:**
  - `dbo.McGetUpStreamByList()` - Batch upstream calculation

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - Likely called by `dbo.ReconcileMUpstream` (batch processing pattern)
- **Applications:** Batch processing jobs

**Complexity Score:** 8/10
**Business Criticality:** HIGH - Batch material processing

---

#### 1.3 `dbo.ProcessDirtyTrees`

**Purpose:** Processes dirty tree structures (material hierarchies).

**Dependencies - WHAT it references:**
- **Tables:**
  - `m_upstream` (R/W)
  - `m_downstream` (R/W)
- **Types:**
  - `GooList` (inferred)
- **Functions:**
  - Tree processing functions (GetUpStream family)

**Referenced By - WHO references it:**
- **Scheduled Jobs:** Tree maintenance processes

**Complexity Score:** 7/10
**Business Criticality:** MEDIUM-HIGH

---

#### 1.4 `dbo.AddArc` ⭐ **CRITICAL**

**Purpose:** Adds a relationship (arc) between material and transition, updates upstream/downstream graphs.

**Dependencies - WHAT it references:**
- **Tables:**
  - `material_transition` (W) - Parent-to-transition relationships
  - `transition_material` (W) - Transition-to-material relationships
  - `m_upstream` (R/W) - Upstream graph
  - `m_downstream` (R/W) - Downstream graph
- **Functions:**
  - `dbo.McGetUpStream()` - Calculate material upstream
  - `dbo.McGetDownStream()` - Calculate material downstream

**Referenced By - WHO references it:**
- **Applications:** Material lineage tracking systems
- **User Interface:** Web/desktop applications

**Complexity Score:** 9/10
**Business Criticality:** CRITICAL - Core lineage operation

---

#### 1.5 `dbo.RemoveArc` ⭐ **CRITICAL**

**Purpose:** Removes a relationship (arc) between material and transition, updates graphs.

**Dependencies - WHAT it references:**
- **Tables:**
  - `material_transition` (D) - Remove parent-to-transition
  - `transition_material` (D) - Remove transition-to-material
  - `m_upstream` (D) - Clean upstream references (commented logic)
  - `m_downstream` (D) - Clean downstream references (commented logic)
- **Functions:**
  - `dbo.McGetUpStream()` - Commented out
  - `dbo.McGetDownStream()` - Commented out

**Referenced By - WHO references it:**
- **Applications:** Material correction/deletion workflows
- **User Interface:** Administrative functions

**Complexity Score:** 8/10
**Business Criticality:** CRITICAL - Data integrity operation

**⚠️ Note:** Significant commented-out graph cleanup logic. Review if this causes orphaned records.

---

#### 1.6 `dbo.MoveContainer`

**Purpose:** Moves a container to a new location, updates container hierarchy.

**Dependencies - WHAT it references:**
- **Tables:**
  - `container` (R/W) - Container master table
  - `container_history` (W) - Audit trail (inferred)
- **Functions:**
  - Container hierarchy functions (inferred)

**Referenced By - WHO references it:**
- **Applications:** Inventory management systems

**Complexity Score:** 6/10
**Business Criticality:** MEDIUM

---

#### 1.7 `dbo.MoveGooType`

**Purpose:** Moves a goo type (material type) in the type hierarchy.

**Dependencies - WHAT it references:**
- **Tables:**
  - `goo_type` (R/W) - Material type table
  - `goo` (R) - Material instances (validation)
- **Functions:**
  - Type hierarchy functions

**Referenced By - WHO references it:**
- **Applications:** Type management systems

**Complexity Score:** 6/10
**Business Criticality:** MEDIUM

---

#### 1.8 `dbo.GetMaterialByRunProperties`

**Purpose:** Retrieves materials based on run/experiment properties.

**Dependencies - WHAT it references:**
- **Tables:**
  - `material_inventory` (R)
  - `hermes.run` (R) - Experiment run data (schema: hermes)
  - `smurf_property` (R) - Material properties
- **Functions:**
  - Property matching functions

**Referenced By - WHO references it:**
- **Applications:** Search/query interfaces
- **Reports:** Material lookup reports

**Complexity Score:** 5/10
**Business Criticality:** MEDIUM

---

#### 1.9 `dbo.LinkUnlinkedMaterials`

**Purpose:** Links materials that should be connected but are orphaned.

**Dependencies - WHAT it references:**
- **Tables:**
  - `material_transition` (W)
  - `transition_material` (W)
  - Various material/transition tables (R)

**Referenced By - WHO references it:**
- **Maintenance Jobs:** Data cleanup processes

**Complexity Score:** 6/10
**Business Criticality:** MEDIUM

---

#### 1.10 `dbo.MaterialToTransition`

**Purpose:** Converts/links material to transition (simple helper).

**Dependencies - WHAT it references:**
- **Tables:**
  - `material_transition` (W)

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.AddArc` (possible)
- **Applications:** Data entry workflows

**Complexity Score:** 2/10
**Business Criticality:** LOW

---

#### 1.11 `dbo.TransitionToMaterial`

**Purpose:** Converts/links transition to material (simple helper).

**Dependencies - WHAT it references:**
- **Tables:**
  - `transition_material` (W)

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.AddArc` (possible)
- **Applications:** Data entry workflows

**Complexity Score:** 2/10
**Business Criticality:** LOW

---

### 2. MS SQL Server Replication Procedures

These procedures are auto-generated by SQL Server Replication Services for table `demeter.barcodes` and `demeter.seed_vials`.

#### 2.1 `dbo.sp_MSdel_dbobarcodes`
**Purpose:** Replication delete trigger for barcodes  
**Dependencies:** `demeter.barcodes` (D)  
**Complexity:** 1/10 | **Criticality:** LOW (Replication only)

#### 2.2 `dbo.sp_MSins_dbobarcodes`
**Purpose:** Replication insert trigger for barcodes  
**Dependencies:** `demeter.barcodes` (W)  
**Complexity:** 1/10 | **Criticality:** LOW

#### 2.3 `dbo.sp_MSupd_dbobarcodes`
**Purpose:** Replication update trigger for barcodes  
**Dependencies:** `demeter.barcodes` (R/W)  
**Complexity:** 2/10 | **Criticality:** LOW

#### 2.4 `dbo.sp_MSdel_dboseed_vials`
**Purpose:** Replication delete trigger for seed vials  
**Dependencies:** `demeter.seed_vials` (D)  
**Complexity:** 1/10 | **Criticality:** LOW

#### 2.5 `dbo.sp_MSins_dboseed_vials`
**Purpose:** Replication insert trigger for seed vials  
**Dependencies:** `demeter.seed_vials` (W)  
**Complexity:** 2/10 | **Criticality:** LOW

#### 2.6 `dbo.sp_MSupd_dboseed_vials`
**Purpose:** Replication update trigger for seed vials  
**Dependencies:** `demeter.seed_vials` (R/W)  
**Complexity:** 3/10 | **Criticality:** LOW

---

### 3. Utility & Update Procedures

#### 3.1 `dbo.sp_move_node`

**Purpose:** Moves a node in a hierarchical structure (generic utility).

**Dependencies - WHAT it references:**
- **Tables:**
  - Generic node/hierarchy tables (context-dependent)
- **Functions:**
  - Hierarchy traversal functions

**Referenced By - WHO references it:**
- **Stored Procedures:**
  - `dbo.MoveContainer` (possible)
  - `dbo.MoveGooType` (possible)

**Complexity Score:** 5/10
**Business Criticality:** MEDIUM

---

#### 3.2 `dbo.usp_UpdateContainerTypeFromArgus`

**Purpose:** Updates container type information from external system (Argus).

**Dependencies - WHAT it references:**
- **Tables:**
  - `container_type` (W)
  - External linked server/table (Argus system)

**Referenced By - WHO references it:**
- **ETL Jobs:** Scheduled integration from Argus
- **Applications:** Data sync processes

**Complexity Score:** 4/10
**Business Criticality:** MEDIUM

---

#### 3.3 `dbo.usp_UpdateMDownstream`

**Purpose:** Updates material downstream relationships manually/on-demand.

**Dependencies - WHAT it references:**
- **Tables:**
  - `m_downstream` (W)
- **Functions:**
  - Downstream calculation functions

**Referenced By - WHO references it:**
- **Maintenance Jobs:** Manual graph corrections
- **DBA Tools:** Administrative utilities

**Complexity Score:** 5/10
**Business Criticality:** MEDIUM

---

#### 3.4 `dbo.usp_UpdateMUpstream`

**Purpose:** Updates material upstream relationships manually/on-demand.

**Dependencies - WHAT it references:**
- **Tables:**
  - `m_upstream` (W)
- **Functions:**
  - Upstream calculation functions

**Referenced By - WHO references it:**
- **Maintenance Jobs:** Manual graph corrections
- **DBA Tools:** Administrative utilities

**Complexity Score:** 5/10
**Business Criticality:** MEDIUM

---

## 🔗 Dependency Graph Summary

### Critical Dependency Chains

```
1. Material Lineage Processing Chain:
   Application/UI
   └─> dbo.AddArc / dbo.RemoveArc
       ├─> dbo.McGetUpStream()
       ├─> dbo.McGetDownStream()
       └─> Tables: material_transition, transition_material, m_upstream, m_downstream

2. Material Reconciliation Chain:
   Scheduled Job
   └─> dbo.ReconcileMUpstream
       ├─> dbo.ProcessSomeMUpstream (inferred)
       │   └─> dbo.McGetUpStreamByList()
       └─> Tables: m_upstream, m_upstream_dirty_leaves

3. Container Management Chain:
   Application
   └─> dbo.MoveContainer
       ├─> dbo.sp_move_node (possible)
       └─> Tables: container, container_history

4. External Integration Chain:
   ETL Job
   └─> dbo.usp_UpdateContainerTypeFromArgus
       └─> Tables: container_type + Argus Linked Server
```

### Table Usage Matrix

| Table | Read By | Written By | Critical? |
|-------|---------|------------|-----------|
| `m_upstream` | ReconcileMUpstream, ProcessSomeMUpstream, AddArc, RemoveArc, usp_UpdateMUpstream | ReconcileMUpstream, ProcessSomeMUpstream, AddArc, usp_UpdateMUpstream | ⭐ CRITICAL |
| `m_downstream` | AddArc, RemoveArc, ProcessDirtyTrees, usp_UpdateMDownstream | AddArc, ProcessDirtyTrees, usp_UpdateMDownstream | ⭐ CRITICAL |
| `material_transition` | AddArc, RemoveArc, LinkUnlinkedMaterials | AddArc, LinkUnlinkedMaterials, MaterialToTransition | ⭐ CRITICAL |
| `transition_material` | AddArc, RemoveArc, LinkUnlinkedMaterials | AddArc, LinkUnlinkedMaterials, TransitionToMaterial | ⭐ CRITICAL |
| `m_upstream_dirty_leaves` | ReconcileMUpstream | ETL/Triggers (external) | ⭐ CRITICAL |
| `container` | MoveContainer, GetMaterialByRunProperties | MoveContainer | HIGH |
| `container_type` | Multiple queries | usp_UpdateContainerTypeFromArgus | HIGH |
| `goo_type` | MoveGooType, Multiple | MoveGooType | HIGH |
| `material_inventory` | GetMaterialByRunProperties | Multiple (external) | HIGH |
| `demeter.barcodes` | sp_MSins_dbobarcodes | sp_MS*_dbobarcodes (Replication) | MEDIUM |
| `demeter.seed_vials` | sp_MSins_dboseed_vials | sp_MS*_dboseed_vials (Replication) | MEDIUM |

### Function Usage Matrix

| Function | Called By SPs | Critical? |
|----------|---------------|-----------|
| `dbo.McGetUpStream()` | AddArc, RemoveArc | ⭐ CRITICAL |
| `dbo.McGetDownStream()` | AddArc, RemoveArc | ⭐ CRITICAL |
| `dbo.McGetUpStreamByList()` | ReconcileMUpstream, ProcessSomeMUpstream | ⭐ CRITICAL |
| `dbo.McGetDownStreamByList()` | (inferred usage) | HIGH |
| `dbo.GetUpStream()` | Multiple (direct or via views) | HIGH |
| `dbo.GetDownStream()` | Multiple (direct or via views) | HIGH |
| `dbo.GetUpStreamFamily()` | ProcessDirtyTrees (inferred) | MEDIUM |
| `dbo.GetDownStreamFamily()` | ProcessDirtyTrees (inferred) | MEDIUM |

### Type Usage Matrix

| Type | Used By SPs | Purpose |
|------|-------------|---------|
| `GooList` | ReconcileMUpstream, ProcessSomeMUpstream | Table-valued parameter for batch material operations |

---

## 🎯 Critical Observations & Recommendations

### 1. **High Coupling on Material Graph Functions**
- **McGet* family functions** are called by multiple critical SPs
- **Impact:** Changes to these functions affect entire lineage system
- **Recommendation:** Ensure comprehensive testing of these functions during migration

### 2. **RemoveArc Has Commented Logic**
- Significant graph cleanup code is commented out
- **Risk:** May lead to orphaned records in m_upstream/m_downstream
- **Recommendation:** Verify if commented code should be restored in PostgreSQL version

### 3. **GooList Type is Critical**
- Used in batch processing procedures (ReconcileMUpstream, ProcessSomeMUpstream)
- **PostgreSQL Migration:** Need to convert to temporary tables or arrays
- **Recommendation:** Design PostgreSQL equivalent carefully (RECORD[], temp tables, or JSON)

### 4. **Replication Procedures May Not Be Needed**
- 6 MS SQL Server replication procedures (sp_MS*)
- **Question:** Is SQL Server replication still required post-migration?
- **Recommendation:** Clarify replication strategy for PostgreSQL (logical replication, pglogical, BDR)

### 5. **External System Integration (Argus)**
- `usp_UpdateContainerTypeFromArgus` uses linked server
- **Recommendation:** Verify Argus integration method for PostgreSQL (FDW, dblink, API)

### 6. **Batch Processing Pattern**
- ReconcileMUpstream uses TOP 10 limit for processing
- **Recommendation:** Consider PostgreSQL's LIMIT and cursor-based batching

---

## 📊 Migration Priority Matrix

| Priority | Procedure | Reason | Dependencies |
|----------|-----------|--------|--------------|
| **P0** | dbo.AddArc | Core material lineage creation | McGetUpStream, McGetDownStream, 4 tables |
| **P0** | dbo.RemoveArc | Core material lineage deletion | McGetUpStream, McGetDownStream, 4 tables |
| **P0** | dbo.ReconcileMUpstream | Critical graph reconciliation | McGetUpStreamByList, GooList, 2 tables |
| **P1** | dbo.ProcessSomeMUpstream | Batch processing support | McGetUpStreamByList, GooList |
| **P1** | dbo.ProcessDirtyTrees | Tree maintenance | Multiple Get* functions |
| **P1** | dbo.MoveContainer | Inventory management | container tables |
| **P2** | dbo.GetMaterialByRunProperties | Query/search function | Read-only, lower risk |
| **P2** | dbo.LinkUnlinkedMaterials | Data cleanup utility | Can be deferred |
| **P2** | dbo.MoveGooType | Type management | Lower frequency usage |
| **P2** | dbo.usp_Update* | Manual maintenance utilities | DBA tools, lower priority |
| **P3** | dbo.MaterialToTransition | Simple helper, low complexity | Can migrate anytime |
| **P3** | dbo.TransitionToMaterial | Simple helper, low complexity | Can migrate anytime |
| **P3** | dbo.sp_MS* | Replication-specific | May not be needed in PostgreSQL |

---

## 🔄 Next Steps

### Immediate Actions:
1. ✅ **Lote 1 Complete:** 21 Stored Procedures analyzed
2. ⏭️ **Lote 2:** Analyze 24 Functions in `Functions/` directory
3. ⏭️ **Lote 3:** Analyze 22 Views in `Views/` directory
4. ⏭️ **Lote 4:** Create final consolidated dependency tree with all objects

### Questions for Stakeholders:
1. Is SQL Server replication still required after PostgreSQL migration?
2. What is the current usage frequency of each stored procedure?
3. Are there any procedures that can be retired/deprecated?
4. What is the Argus system integration method post-migration?

---

## 📌 Document Metadata

**Version:** 1.0  
**Last Updated:** 2025-12-15  
**Next Review:** Lote 2 - Functions Analysis  
**Maintained By:** Pierre Ribeiro (Senior DBA/DBRE)  
**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17

---

**End of Lote 1 Analysis**
