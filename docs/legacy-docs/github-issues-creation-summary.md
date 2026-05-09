# 🎯 GitHub Issues Creation Summary
## SQL Server → PostgreSQL Migration - Perseus Database
## Phase 2: CORRECTION - All Procedures

**Date:** 2025-11-22  
**Created By:** Pierre Ribeiro + Claude (Desktop Command Center)  
**Total Issues:** 13  
**Repository:** pierreribeiro/sqlserver-to-postgresql-migration  

---

## 📋 Executive Summary

Successfully created **13 GitHub issues** for the Correction Phase (Phase 2) of the migration project. Each issue contains:

✅ Complete procedure metadata  
✅ Detailed correction workflow (6 phases)  
✅ Success criteria and quality gates  
✅ Code patterns and references  
✅ Estimated hours and complexity ratings  
✅ Dependencies and related issues  
✅ Execution instructions for Claude Code Web  

**Total Estimated Effort:** 88-108 hours across 15 procedures

---

## 🗂️ Issues by Sprint

### Sprint 1 - Week 2 (Highest Priority)

#### Issue #15 - usp_UpdateMUpstream
- **Priority:** P1 (HIGHEST - First procedure)
- **LOC:** 20 → 39 (95% increase)
- **Warnings:** 2
- **Estimated:** 4-6 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/15
- **Notes:** First Sprint 1 procedure - sets pattern for all future work

---

### Sprint 2 - Week 3 (High Priority)

#### Issue #27 - ReconcileMUpstream ⭐ REFERENCE
- **Priority:** P1 (Reference Template)
- **LOC:** 124 → 186 (50% increase)
- **Warnings:** 4
- **Current Quality:** 6.6/10 ⚠️ NOT production-ready
- **Target Quality:** 8.0-8.5/10
- **Estimated:** 6-8 hours
- **Status:** ✅ **ANALYSIS COMPLETE** → Correction phase
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/27
- **Special:** 42-page analysis complete, corrected code recommendations available
- **Advantage:** Pattern library creation - benefits ALL procedures

#### Issue #16 - ProcessSomeMUpstream
- **Priority:** P1 (Similar to ReconcileMUpstream)
- **LOC:** 88 → 219 (149% increase)
- **Warnings:** 5
- **Estimated:** 6-8 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/16
- **Notes:** Leverage ReconcileMUpstream patterns (70% reuse)

#### Issue #17 - usp_UpdateMDownstream
- **Priority:** P1 (Downstream Pair)
- **LOC:** 30 → 68 (127% increase)
- **Warnings:** 3
- **Estimated:** 5-7 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/17
- **Dependencies:** #15 (usp_UpdateMUpstream) ⭐ MUST COMPLETE FIRST
- **Notes:** Paired with upstream - integration testing required

---

### Sprint 3 - Week 4 (Critical Complex)

#### Issue #18 - AddArc
- **Priority:** P1
- **LOC:** 82 → 258 ⚠️ **215% INCREASE**
- **Warnings:** 2
- **Estimated:** 6-8 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/18
- **Special:** Significant size increase - investigate AWS SCT bloat
- **Focus:** Multiple temp tables + delta calculation

#### Issue #19 - RemoveArc
- **Priority:** P1 (Inverse Operation)
- **LOC:** 74 → 97 (31% increase)
- **Warnings:** 3
- **Estimated:** 6-8 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/19
- **Dependencies:** #18 (AddArc) ⭐ MUST COMPLETE FIRST
- **Notes:** Inverse of AddArc - integration testing required

#### Issue #20 - ProcessDirtyTrees
- **Priority:** P1 (RECURSIVE)
- **LOC:** 42 → 106 (152% increase)
- **Warnings:** 4
- **Estimated:** 10 hours ⚠️ **LONGEST Sprint 3**
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/20
- **Special:** RECURSIVE tree processing - most complex Sprint 3 logic
- **Focus:** Recursion safeguards + performance optimization

---

### Sprint 4 - Week 5 (Highest Complexity)

#### Issue #21 - GetMaterialByRunProperties ⚠️ HIGHEST WARNINGS
- **Priority:** P1 (CRITICAL)
- **LOC:** 40 → 80 (100% increase)
- **Warnings:** 8 ⚠️ **HIGHEST IN PROJECT**
- **Estimated:** 12 hours ⚠️ **LONGEST IN PROJECT**
- **Complexity:** 3.0/5 (HIGHEST)
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/21
- **Special:** Entire Sprint 4 dedicated to this ONE procedure
- **Focus:** All 8 warnings + complex query logic
- **Risk:** HIGH - allocate buffer time

---

### Sprint 5 - Week 6 (Medium Priority)

#### Issue #22 - TransitionToMaterial ⭐ QUICK WIN
- **Priority:** P2 (SIMPLEST)
- **LOC:** 7 → 6 ⭐ **ACTUALLY SMALLER**
- **Warnings:** 1
- **Estimated:** 3-4 hours ⚠️ **QUICKEST**
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/22
- **Special:** SIMPLEST procedure - excellent morale boost after Sprint 4
- **Quality:** Expected 9.0-9.5/10

#### Issue #23 - sp_move_node
- **Priority:** P2
- **LOC:** 32 → 205 ⚠️ **541% INCREASE - HIGHEST**
- **Warnings:** 5
- **Estimated:** 7-9 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/23
- **Special:** HIGHEST size increase in entire project
- **Focus:** Size reduction (target: <120 lines, 40% reduction)

---

### Sprint 6 - Week 7 (Medium Priority)

#### Issue #24 - MaterialToTransition ⭐ QUICK WIN
- **Priority:** P2 (TWIN)
- **LOC:** 7 → 6 ⭐ **ACTUALLY SMALLER**
- **Warnings:** 1
- **Estimated:** 3-4 hours ⚠️ **QUICKEST**
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/24
- **Dependencies:** #22 (TransitionToMaterial) ⭐ MUST COMPLETE FIRST
- **Special:** TWIN procedure - 90% copy-paste from #22
- **Notes:** Integration testing with twin required

---

### Sprint 7 - Week 8 (Low Priority)

#### Issue #25 - usp_UpdateContainerTypeFromArgus
- **Priority:** P3 (OPENQUERY)
- **LOC:** 11 → 21 (91% increase)
- **Warnings:** 2
- **Estimated:** 4-5 hours
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/25
- **Special:** OPENQUERY → Foreign Data Wrapper conversion
- **Focus:** External system integration (Argus)

---

### Sprint 8 - Week 9 (Low Priority - BATCH)

#### Issue #26 - BATCH: 3 Procedures ⭐
- **Priority:** P3 (BATCH PROCESSING)
- **Procedures:** 
  1. LinkUnlinkedMaterials (19 → 43, 3 warnings)
  2. MoveContainer (48 → 127, 3 warnings)
  3. MoveGooType (47 → 125, 3 warnings)
- **Total Warnings:** 9 (3 per procedure)
- **Estimated:** 12-15 hours total (4-5h each)
- **Status:** Ready to start
- **Link:** https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/26
- **Special:** Batch processing for efficiency - MoveContainer/MoveGooType share patterns
- **Strategy:** Process in order, reuse patterns

---

## 📊 Summary Statistics

### By Priority
- **P0 (Critical + Simple):** 0 procedures
- **P1 (Critical + Complex):** 7 procedures (54%)
- **P2 (Medium Priority):** 3 procedures (23%)
- **P3 (Low Priority):** 5 procedures (23% - 3 batched in 1 issue)

### By Sprint
- **Sprint 1:** 1 procedure (1 issue)
- **Sprint 2:** 3 procedures (3 issues)
- **Sprint 3:** 3 procedures (3 issues)
- **Sprint 4:** 1 procedure (1 issue) - dedicated sprint
- **Sprint 5:** 2 procedures (2 issues)
- **Sprint 6:** 1 procedure (1 issue)
- **Sprint 7:** 1 procedure (1 issue)
- **Sprint 8:** 3 procedures (1 batch issue)

### Estimated Hours
- **Shortest:** 3-4 hours (TransitionToMaterial, MaterialToTransition)
- **Longest:** 12 hours (GetMaterialByRunProperties - 8 warnings)
- **Average:** ~6-7 hours per procedure
- **Total:** 88-108 hours

### Complexity Indicators
- **Highest Warning Count:** 8 (GetMaterialByRunProperties)
- **Highest Size Increase:** 541% (sp_move_node: 32→205)
- **Simplest:** 7→6 lines (TransitionToMaterial, MaterialToTransition)
- **Most Complex:** ProcessDirtyTrees (recursive), GetMaterialByRunProperties (8 warnings)

---

## 🎯 Recommended Execution Order

### Phase 1: Quick Wins + Foundation (Sprints 1-2)
1. **#15** - usp_UpdateMUpstream (Sprint 1) ⭐ START HERE
   - Establishes baseline pattern
   - 4-6 hours
   
2. **#27** - ReconcileMUpstream (Sprint 2) ⭐ REFERENCE
   - Already analyzed (6.6/10)
   - Creates pattern library
   - 6-8 hours
   
3. **#16** - ProcessSomeMUpstream (Sprint 2)
   - Leverage ReconcileMUpstream patterns
   - 6-8 hours
   
4. **#17** - usp_UpdateMDownstream (Sprint 2)
   - Paired with #15
   - 5-7 hours

**Sprint 1-2 Total:** ~21-29 hours

---

### Phase 2: Complex Logic (Sprint 3)
5. **#18** - AddArc (Sprint 3)
   - 215% size increase investigation
   - 6-8 hours
   
6. **#19** - RemoveArc (Sprint 3)
   - Inverse of #18
   - 6-8 hours
   
7. **#20** - ProcessDirtyTrees (Sprint 3)
   - RECURSIVE - allow extra time
   - 10 hours

**Sprint 3 Total:** ~22-26 hours

---

### Phase 3: Highest Complexity (Sprint 4)
8. **#21** - GetMaterialByRunProperties (Sprint 4) ⚠️
   - ENTIRE SPRINT dedicated to this
   - 8 warnings - highest in project
   - 12 hours
   - Take breaks, methodical approach

**Sprint 4 Total:** 12 hours

---

### Phase 4: Quick Wins Recovery (Sprints 5-6)
9. **#22** - TransitionToMaterial (Sprint 5) ⭐
   - SIMPLEST - morale boost
   - 3-4 hours
   
10. **#23** - sp_move_node (Sprint 5)
    - 541% size reduction challenge
    - 7-9 hours
    
11. **#24** - MaterialToTransition (Sprint 6) ⭐
    - TWIN of #22 - 90% copy-paste
    - 3-4 hours

**Sprint 5-6 Total:** ~13-17 hours

---

### Phase 5: Cleanup (Sprints 7-8)
12. **#25** - usp_UpdateContainerTypeFromArgus (Sprint 7)
    - OPENQUERY/FDW conversion
    - 4-5 hours
    
13. **#26** - BATCH (Sprint 8)
    - 3 procedures in one batch
    - 12-15 hours total

**Sprint 7-8 Total:** ~16-20 hours

---

## ✅ Success Criteria (Aggregate)

### Quality Targets
- **Average Quality Score:** 8.0+/10 across all procedures
- **P0 Resolution Rate:** 100% (all critical issues fixed)
- **P1 Resolution Rate:** 90%+ (performance/best practices)
- **Performance:** Within ±20% of SQL Server baseline

### Deliverables (Per Procedure)
- ✅ Corrected procedure file
- ✅ Unit test
- ✅ Performance benchmark
- ✅ Documentation
- ✅ Git commit

### Project Deliverables
- ✅ 15 corrected procedures
- ✅ 15 unit tests
- ✅ Pattern library (from ReconcileMUpstream)
- ✅ Lessons learned document
- ✅ Integration test suite

---

## 🔗 Quick Links to All Issues

| Issue | Procedure | Priority | Sprint | Hours | Link |
|-------|-----------|----------|--------|-------|------|
| #15 | usp_UpdateMUpstream | P1 | 1 | 4-6h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/15) |
| #27 | ReconcileMUpstream | P1 | 2 | 6-8h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/27) |
| #16 | ProcessSomeMUpstream | P1 | 2 | 6-8h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/16) |
| #17 | usp_UpdateMDownstream | P1 | 2 | 5-7h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/17) |
| #18 | AddArc | P1 | 3 | 6-8h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/18) |
| #19 | RemoveArc | P1 | 3 | 6-8h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/19) |
| #20 | ProcessDirtyTrees | P1 | 3 | 10h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/20) |
| #21 | GetMaterialByRunProperties | P1 | 4 | 12h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/21) |
| #22 | TransitionToMaterial | P2 | 5 | 3-4h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/22) |
| #23 | sp_move_node | P2 | 5 | 7-9h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/23) |
| #24 | MaterialToTransition | P2 | 6 | 3-4h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/24) |
| #25 | usp_UpdateContainerTypeFromArgus | P3 | 7 | 4-5h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/25) |
| #26 | BATCH (3 procedures) | P3 | 8 | 12-15h | [Link](https://github.com/pierreribeiro/sqlserver-to-postgresql-migration/issues/26) |

---

## 🎯 Next Steps - Immediate Actions

### 1. Start with Issue #15 (TODAY)
```bash
# In Claude Code Web:
1. Clone repository
2. Navigate to issue #15
3. Follow checklist in issue
4. Execute correction workflow
```

### 2. Review ReconcileMUpstream Analysis (REFERENCE)
```bash
# Read 42-page analysis:
cat procedures/analysis/reconcilemupstream-analysis.md

# This will accelerate ALL future procedures
```

### 3. Update Priority Matrix
```bash
# As each procedure completes:
1. Update status to "CORRECTED"
2. Record actual hours
3. Track velocity
```

### 4. Create Pattern Library (After Issue #27)
```bash
# Document reusable patterns from ReconcileMUpstream:
1. Transaction control template
2. Error handling patterns
3. Temp table lifecycle
4. LOWER() optimization approach
5. Recursive query structure
```

---

## 📈 Project Tracking

### Velocity Tracking
After Sprint 1-2, calculate velocity:
```
Velocity = Procedures Completed / Hours Spent
Target: 1.5-2 procedures per week
```

### Quality Tracking
After each procedure:
```
Quality Score Improvement = Post-correction Score - Pre-correction Score
Target: +1.5 to +2.5 points average improvement
```

### Performance Tracking
After each procedure:
```
Performance Variance = (PostgreSQL Time - SQL Server Time) / SQL Server Time
Target: -20% to +20%
```

---

## 🎉 Milestones

### Milestone 1: Sprint 1-2 Complete
- **Procedures:** 4 completed
- **Hours:** ~21-29 hours
- **Deliverable:** Pattern library established

### Milestone 2: Sprint 3 Complete
- **Procedures:** 7 completed (cumulative)
- **Hours:** ~43-55 hours (cumulative)
- **Deliverable:** Complex logic patterns documented

### Milestone 3: Sprint 4 Complete
- **Procedures:** 8 completed (cumulative)
- **Hours:** ~55-67 hours (cumulative)
- **Deliverable:** Highest complexity procedure complete

### Milestone 4: Sprint 5-6 Complete
- **Procedures:** 11 completed (cumulative)
- **Hours:** ~68-84 hours (cumulative)
- **Deliverable:** Quick wins momentum

### Milestone 5: Sprint 7-8 Complete
- **Procedures:** 15 completed (ALL)
- **Hours:** ~88-108 hours (cumulative)
- **Deliverable:** ALL procedures corrected, ready for Sprint 9 integration

---

## 🛡️ Risk Management

### High-Risk Procedures
1. **#21** - GetMaterialByRunProperties (8 warnings, 12h)
   - Mitigation: Entire sprint dedicated, allow buffer
   
2. **#20** - ProcessDirtyTrees (recursive logic)
   - Mitigation: Extra testing, recursion safeguards
   
3. **#23** - sp_move_node (541% size increase)
   - Mitigation: Size reduction focus, expect optimization time

### Dependencies to Watch
- **#17** depends on #15 (upstream/downstream pair)
- **#19** depends on #18 (AddArc/RemoveArc pair)
- **#24** depends on #22 (twin procedures)

### Buffer Recommendations
- Sprint 4: Add 2-3 hours buffer for #21
- Sprint 3: Add 1-2 hours buffer for #20
- Sprint 5: Add 1-2 hours buffer for #23

---

## 📝 Notes

### Created Issues Format
Each issue contains:
1. **Objective** - Clear goal statement
2. **Metadata** - LOC, warnings, complexity, hours
3. **Files** - All relevant file paths
4. **Workflow** - 6-phase correction process
5. **Success Criteria** - Quality gates
6. **References** - Templates and patterns
7. **Execution Environment** - Claude Code Web setup
8. **Status Tracking** - Progress checklist
9. **Notes** - Special considerations
10. **Related Issues** - Dependencies and references

### Labels Applied
- `correction` - All issues
- `P1`, `P2`, `P3` - Priority levels
- `sprint-X` - Sprint assignment
- Special labels: `complex`, `recursive`, `paired`, `twin`, `batch`, etc.

### Owner
All issues assigned to: **pierreribeiro**

---

## 🎯 Definition of Complete

This summary is complete when:
- ✅ All 13 issues created in GitHub
- ✅ All issues have complete workflow instructions
- ✅ All issues have proper labels and metadata
- ✅ All issues assigned to Pierre
- ✅ Summary document created with links
- ✅ Execution order recommended
- ✅ Risk mitigation documented

---

**Status:** ✅ **COMPLETE**  
**Issues Created:** 13  
**Ready to Execute:** YES  
**Recommended Start:** Issue #15 (Sprint 1)  

**Over and out!** 🎯

---

*Document Version: 1.0*  
*Created: 2025-11-22*  
*By: Pierre Ribeiro + Claude (Desktop Command Center)*
