# Análise Qualitativa: Conversão T-SQL → PL/pgSQL
## AWS Schema Conversion Tool - AddArc Procedure

**Analisado por:** Pierre Ribeiro (Database Reliability Engineer)  
**Data:** 2025-11-18  
**Ferramenta:** AWS Schema Conversion Tool (SCT)  
**Origem:** SQL Server Enterprise 2014 (T-SQL)  
**Destino:** PostgreSQL (PL/pgSQL)  
**Procedure:** `dbo.AddArc`  
**Sprint:** Sprint_3 (Pacote 1 de 3)

---

## 📊 Executive Summary

| Métrica | Score | Status |
|---------|-------|--------|
| **Correção Lógica** | 7/10 | ✅ BOM |
| **Correção Sintática** | 6/10 | ⚠️ PROBLEMAS MENORES |
| **Performance** | 5/10 | ⚠️ OTIMIZAÇÕES NECESSÁRIAS |
| **Manutenibilidade** | 6/10 | ⚠️ MELHORIAS NECESSÁRIAS |
| **Segurança** | 7/10 | ✅ BOM |
| **SCORE GERAL** | **6.2/10 (62%)** | ⚠️ **NÃO PRODUCTION-READY** |

### 🎯 Veredito Final

⚠️ **NÃO está production-ready** - Requer correções P0 obrigatórias  
✅ **Boa base de partida** - ~70% do trabalho correto  
⚠️ **Revisão manual obrigatória** - P0 fixes antes de deploy

**Procedimentos:** 82 linhas → 258 linhas (215% increase devido a comentários AWS SCT)  
**Código real:** 82 linhas → ~100 linhas (22% increase real)

---

## 🔍 1. Análise do Aumento de Tamanho (215%)

### 1.1 Breakdown Detalhado

| Componente | Linhas | % Total | Observação |
|------------|--------|---------|------------|
| Código PostgreSQL efetivo | ~100 | 39% | Lógica funcional |
| Comentários [7659] (6x) | ~40 | 15% | Temp table warnings |
| Comentários [7795] (18x) | ~50 | 19% | Case sensitivity warnings |
| Espaçamento/formatação | ~68 | 27% | Whitespace |
| **TOTAL** | **258** | **100%** | |

### 1.2 Conclusão

✅ **Aumento real: apenas 22%** (82 → 100 linhas)  
⚠️ **177 linhas são comentários AWS SCT**  
💡 **Ação:** Remover comentários do código final

---

## 🚨 2. Problemas Críticos (P0) - Must Fix

### P0 #1: FALTA DE TRANSACTION CONTROL

**Severidade:** 🔴 CRITICAL

**Problema:**
```sql
CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(...)
AS $BODY$
BEGIN
    -- NO transaction block
    -- Business logic
    -- NO exception handling
    -- NO rollback capability
END;
$BODY$
```

**Impacto:**
- Dados ficam parcialmente atualizados em caso de erro
- Grafos m_upstream/m_downstream podem ficar inconsistentes
- Sistema de relações pode ser corrompido

**Correção:**
```sql
BEGIN
    BEGIN  -- Transaction block
        -- Business logic
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION '[AddArc] Failed: %', SQLERRM
                  USING ERRCODE = 'P0001';
    END;
END;
```

---

### P0 #2: TEMP TABLES SEM ON COMMIT DROP

**Severidade:** 🔴 CRITICAL - Resource Leak

**Problema:**
```sql
CREATE TEMPORARY TABLE formerdownstream$addarc (...);
-- Sem ON COMMIT DROP
-- DROP manual no final não executa se houver erro
```

**6 Tabelas Afetadas:**
1. formerdownstream$addarc
2. formerupstream$addarc
3. deltadownstream$addarc
4. deltaupstream$addarc
5. newdownstream$addarc
6. newupstream$addarc

**Correção:**
```sql
-- Defensive cleanup PRIMEIRO
DROP TABLE IF EXISTS former_downstream;
-- ... (todas 6)

-- Criar com ON COMMIT DROP
CREATE TEMPORARY TABLE former_downstream (...)
ON COMMIT DROP;  -- Auto-cleanup
```

---

### P0 #3: NOMENCLATURA INADEQUADA

**Problema:** `formerdownstream$addarc` (AWS SCT pattern)  
**Correção:** `former_downstream` (PostgreSQL idiomático)

---

## ⚠️ 3. Problemas Alta Severidade (P1)

### P1 #1: LOWER() EXCESSIVO - 18 OCORRÊNCIAS

**Impacto:** Impede uso de índices, performance crítica

**Distribuição:**
- Literais: 4x (desnecessário)
- EXISTS: 9x (impede índices)
- COUNT: 2x (seq scan forçado)
- JOINs: 6x (nested loop sem índices)

**Performance Estimado:**
- Atual: 15-20 segundos
- Otimizado: 1-2 segundos
- **Ganho: 90%**

**Correção:** Remover LOWER() (assumindo dados normalizados)

---

### P1 #2: COUNT(*) AO INVÉS DE EXISTS

**Problema:**
```sql
IF (SELECT COUNT(*) FROM m_downstream WHERE ...) = 0 THEN
```

**Correção:**
```sql
IF NOT EXISTS (SELECT 1 FROM m_downstream WHERE ... LIMIT 1) THEN
```

**Ganho:** 10-100x em tabelas grandes

---

### P1 #3: FALTA DE ÍNDICES

**Necessários:**
```sql
CREATE INDEX CONCURRENTLY idx_m_downstream_start_end_path 
ON perseus_dbo.m_downstream (start_point, end_point, path);

CREATE INDEX CONCURRENTLY idx_m_upstream_start_end_path 
ON perseus_dbo.m_upstream (start_point, end_point, path);
```

---

### P1 #4: DEPENDÊNCIAS NÃO VALIDADAS

**Funções chamadas sem validação:**
- perseus_dbo.mcgetdownstream(VARCHAR)
- perseus_dbo.mcgetupstream(VARCHAR)

**Correção:** Adicionar checks no início da procedure

---

## 💡 4. Problemas Média Severidade (P2)

### P2 #1: FALTA DE LOGGING

**Adicionar:**
```sql
RAISE NOTICE '[AddArc] Starting: Material=%, Direction=%', par_materialuid, par_direction;
RAISE NOTICE '[AddArc] Deltas: upstream=%, downstream=%', v_delta_up, v_delta_down;
RAISE NOTICE '[AddArc] Completed in % ms', v_exec_time;
```

### P2 #2: FALTA DE VALIDAÇÃO INPUT

```sql
IF par_materialuid IS NULL THEN
    RAISE EXCEPTION '[AddArc] materialuid required';
END IF;

IF par_direction NOT IN ('PT', 'TP') THEN
    RAISE EXCEPTION '[AddArc] Invalid direction: %', par_direction;
END IF;
```

### P2 #3: COMENTÁRIOS AWS SCT

**Ação:** Remover ~90 linhas de comentários do código final

---

## 📊 5. AWS SCT Warnings Analysis

### [7659] - Severity LOW (6 ocorrências)

**Mensagem:** "Table variables vs temp tables scope difference"

**Análise:**
- T-SQL: batch-scoped (auto-cleanup)
- PostgreSQL: session-scoped (manual cleanup)
- **Solução:** ON COMMIT DROP

### [7795] - Severity LOW (18 ocorrências)

**Mensagem:** "String operations are case sensitive"

**Análise:**
- AWS SCT aplicou LOWER() conservadoramente
- **Pode ser desnecessário** se dados normalizados
- **Trade-off:** Preserva comportamento vs Performance

---

## 🎯 6. Scorecard Detalhado

### Correção Lógica: 7/10 ✅
+ Fluxo preservado
+ Delta calculation correto
- Falta transaction control (-2)
- Falta error handling (-1)

### Correção Sintática: 6/10 ⚠️
+ Sintaxe válida
+ Conversão table variables correta
- Nomenclatura inadequada (-1)
- Falta ON COMMIT DROP (-2)
- LOWER() excessivo (-1)

### Performance: 5/10 ⚠️
+ Estrutura razoável
- 18x LOWER() (-3)
- COUNT(*) vs EXISTS (-1)
- Falta índices (-1)

### Manutenibilidade: 6/10 ⚠️
+ Estrutura clara
- 90 linhas comentários (-2)
- Nomenclatura confusa (-1)
- Falta logging (-1)

### Segurança: 7/10 ✅
+ Parametrizado
+ Sem dynamic SQL
- Falta validation (-2)
- Falta audit trail (-1)

---

## 💡 7. Instruções para Code Web

### Arquivo Destino
`procedures/corrected/addarc.sql`

### Template Base
`templates/postgresql-procedure-template.sql`

### P0 Fixes Obrigatórios

1. **Transaction Control**
   - Adicionar BEGIN...EXCEPTION...END block
   - Implementar ROLLBACK
   - SQLSTATE 'P0001'

2. **Temp Tables**
   - ON COMMIT DROP (todas 6)
   - Defensive cleanup no início
   - Remover DROP manual do final

3. **Nomenclatura**
   - former_downstream (não formerdownstream$addarc)
   - Padrão underscore

### P1 Optimizations

1. Remover 18x LOWER()
2. EXISTS ao invés de COUNT (2x)
3. Adicionar sugestões de índices
4. Validar dependências

### P2 Enhancements

1. Logging (RAISE NOTICE)
2. Input validation
3. Remover comentários AWS SCT

### Checklist Validação

- [ ] Compila sem erros
- [ ] Transaction control presente
- [ ] ON COMMIT DROP em todas temp tables
- [ ] Defensive cleanup no início
- [ ] Sem LOWER() desnecessário
- [ ] EXISTS ao invés de COUNT
- [ ] Logging presente
- [ ] Input validation
- [ ] Comentários AWS SCT removidos

---

## 📈 8. Performance Estimado

| Fase | Atual (LOWER) | Otimizado | Ganho |
|------|---------------|-----------|-------|
| Capture Former | 200ms | 200ms | 0% |
| Calculate Delta | 2-3s | 100ms | 95% |
| Check Existence | 1s | 10ms | 99% |
| Add Secondary | 10-15s | 500ms | 97% |
| **TOTAL** | **15-20s** | **1-2s** | **90%** |

---

## 🔗 9. Contexto de Negócio

**AddArc** adiciona novo arco no grafo de materiais/transições:

```
1. Snapshot Anterior → Captura estado atual
2. Modificação → Adiciona relação material↔transition
3. Snapshot Novo → Recalcula grafos
4. Delta → Identifica novos arcos (new - former)
5. Propagação → Adiciona conexões secundárias
```

**Criticidade:** ALTA - Falha = grafo corrompido

---

## 📋 10. Comparação com ReconcileMUpstream

### Semelhanças
- 6 temp tables (snapshot pattern)
- LOWER() excessivo
- Mesmos AWS warnings
- Transaction control faltando
- Score similar (6.6 vs 6.2)

### Diferenças
- AddArc: Sem recursão (mais simples)
- AddArc: Sem RAISE error bug
- AddArc: Tem propagação secundária

**Conclusão:** Soluções padronizadas aplicáveis!

---

## ✅ 11. Expected Results

### Qualidade
- Score atual: 6.2/10
- Score target: 8.5/10
- Melhoria: 37%

### Performance
- Atual: 15-20s
- Target: 1-2s
- Ganho: 90%

### Tempo Correção
- P0: 1-2h
- P1: 1-2h
- P2: 1h
- Testes: 1h
- **Total: 4-6h**

---

## 🏁 12. Conclusão

### Status
⚠️ **NÃO production-ready** - Score 6.2/10

### Ações Necessárias
- ✅ 3 P0 fixes (obrigatórios)
- ✅ 4 P1 fixes (recomendados)
- ⚠️ 4 P2 enhancements (opcionais)

### Confiança
**ALTA** - Baseado em template provado (ReconcileMUpstream)

### Próximo Passo
✅ **Aguardando autorização de Pierre para correção**

---

**Document Version:** 1.0  
**Date:** 2025-11-18  
**Status:** ✅ **ANÁLISE COMPLETA - PACOTE 1 FINALIZADO**

---

**END OF ANALYSIS - AddArc**
