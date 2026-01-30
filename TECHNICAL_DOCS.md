# Technical Documentation: Defensive CTE Architecture

## 🎯 Design Philosophy

This query implements a **defensive programming pattern** specifically designed to prevent data multiplication issues common in multi-table JOIN operations within collections and debt recovery analytics.

## 🏗️ Architectural Decisions

### 1. CTE-Based Preprocessing

**Decision:** Use separate CTEs for each data entity before joining

**Rationale:**
- **Isolation of Concerns:** Each CTE handles one business entity (debtors, debts, collections, payments)
- **Testability:** Each layer can be validated independently
- **Performance:** Database optimizer can materialize or inline CTEs based on cost
- **Maintainability:** Changes to one entity don't cascade to others

### 2. Pre-Aggregation Strategy

**Decision:** Aggregate metrics (COUNT, SUM) before JOIN operations

**Rationale:**
```
Traditional Approach:
JOIN → JOIN → JOIN → AGGREGATE
Problems: Multiplied intermediate results

Defensive Approach:
AGGREGATE → JOIN (with aggregated data)
Benefits: No multiplication, accurate results
```

**Mathematical Proof:**
```
Without pre-aggregation:
- Debt has 5 gestiones and 3 pagos
- JOIN creates: 5 × 3 = 15 intermediate rows
- SUM(monto_pagado) calculated 5 times = WRONG

With pre-aggregation:
- CTE3: Aggregate gestiones → 1 row (count=5)
- CTE4: Aggregate pagos → 1 row (sum=X)
- JOIN: 1 × 1 = 1 row = CORRECT
```

### 3. LEFT JOIN Progression

**Decision:** Use LEFT JOINs sequentially from parent to child entities

**Rationale:**
- Preserves all debtors even if they lack debts/collections/payments
- Allows filtering at the end rather than prematurely excluding records
- Supports business requirement: "Show me ALL debtors first, then filter"

### 4. Terminal Filtering

**Decision:** Apply WHERE clause at the end, not in CTEs

**Rationale:**
- CTEs remain reusable for different business questions
- Filtering logic clearly separated from data preparation
- Easy to modify business rules without touching data layer

## 🔬 Technical Deep Dive

### Cardinality Analysis

```sql
-- Expected cardinalities at each stage:

-- Stage 1: preproc_deudores
-- Input: deudores table (potentially with duplicates)
-- Output: DISTINCT deudores
-- Cardinality: O(N_debtors)

-- Stage 2: preproc_deuda
-- Input: deudas table
-- Output: All debts with their debtor_id
-- Cardinality: O(N_debts) where N_debts = ~5 × N_debtors (avg)

-- Stage 3: preproc_gestiones (CRITICAL AGGREGATION)
-- Input: gestiones table with M records per debt
-- Output: 1 aggregated record per debt
-- Cardinality: O(N_debts) NOT O(N_debts × M)

-- Stage 4: preproc_pagos (CRITICAL AGGREGATION)
-- Input: pagos table with P records per debt
-- Output: 1 aggregated record per debt
-- Cardinality: O(N_debts) NOT O(N_debts × P)

-- Final JOIN:
-- Cardinality: O(N_debts) maintained throughout
-- NO EXPLOSION: Thanks to pre-aggregation
```

### Join Complexity

```
Without defensive CTEs:
O(N_debtors × avg_debts × avg_gestiones × avg_pagos)
Example: 10,000 × 5 × 20 × 10 = 10,000,000 intermediate rows

With defensive CTEs:
O(N_debtors × avg_debts × 1 × 1)
Example: 10,000 × 5 × 1 × 1 = 50,000 rows
Reduction: 200× fewer intermediate rows
```

## 🎯 Design Patterns Applied

### 1. **Layered Architecture Pattern**
```
Presentation Layer (Final SELECT)
    ↓
Business Logic Layer (WHERE clause)
    ↓
Data Integration Layer (JOINs)
    ↓
Data Preparation Layer (CTEs)
    ↓
Data Source Layer (Base tables)
```

### 2. **Aggregation Before Join Pattern**
- Inspired by MapReduce paradigm
- Reduce data volume before expensive operations
- Similar to denormalization strategies in data warehousing

### 3. **Defensive Programming Pattern**
- Assume data quality issues may exist
- GROUP BY in first CTE handles potential duplicates
- Pre-aggregation prevents cartesian products
- NULL handling in WHERE clause

## 🧮 Performance Characteristics

### Time Complexity

| Operation | Without CTEs | With CTEs | Notes |
|-----------|-------------|-----------|-------|
| **First JOIN** | O(N × M) | O(N × M) | Same |
| **Second JOIN** | O(N × M × K) | O(N × M) | K eliminated by aggregation |
| **Third JOIN** | O(N × M × K × P) | O(N × M) | K,P eliminated |
| **Aggregation** | O(N × M × K × P) | O(K) + O(P) | Done separately in CTEs |

**Overall Improvement:** O(N⁴) → O(N²)

### Space Complexity

| Stage | Without CTEs | With CTEs |
|-------|-------------|-----------|
| **Intermediate Results** | Up to N×M×K×P rows | Max N×M rows |
| **Memory Usage** | High (temp tables) | Moderate (materialized CTEs) |
| **Disk Spillage** | Likely with large datasets | Unlikely |

### I/O Characteristics

```sql
-- Explain plan analysis:

-- Without CTEs:
Seq Scan on gestiones  (cost=0..5000 rows=200000)
  -> Hash Join  (cost=5000..50000 rows=2000000)
    -> Seq Scan on pagos  (cost=0..4000 rows=150000)
Total I/O: Heavy sequential scans on multiplied datasets

-- With CTEs:
CTE Scan on preproc_gestiones  (cost=1000..1500 rows=10000)
  -> Index Scan using idx_gestiones_deuda  (cost=0..800)
CTE Scan on preproc_pagos  (cost=900..1400 rows=10000)
  -> Index Scan using idx_pagos_deuda  (cost=0..700)
Total I/O: Reduced, benefits from indexes
```

## 🔍 Edge Cases Handled

### 1. Debtors with No Debts
```sql
-- LEFT JOIN ensures they appear in intermediate results
-- Filtered out by WHERE clause (conteo_gestiones IS NOT NULL)
```

### 2. Debts with No Collections
```sql
-- preproc_gestiones won't have a record for this debt_id
-- LEFT JOIN results in NULL conteo_gestiones
-- Filtered out by WHERE clause
```

### 3. Debts with Collections but No Payments
```sql
-- ✅ This is our target case!
-- preproc_gestiones: has record
-- preproc_pagos: no record (or sum=0)
-- WHERE clause: conteo_gestiones IS NOT NULL AND pagos IS NULL
```

### 4. Multiple Debtors with Same Name
```sql
-- GROUP BY deudor_id prevents wrong aggregation
-- Each debtor_id treated as unique entity
```

### 5. Negative Payment Amounts (Refunds)
```sql
-- SUM(monto_pagado) correctly handles negatives
-- Business logic: Net payment calculation
```

## 🛠️ Alternative Approaches Considered

### Approach 1: Single Query with DISTINCT
```sql
-- ❌ Rejected
SELECT DISTINCT
    d.nombre,
    COUNT(g.gestion_id),
    SUM(p.monto_pagado)
FROM deudores d
JOIN deudas de ON ...
JOIN gestiones g ON ...
JOIN pagos p ON ...
```
**Problems:**
- DISTINCT doesn't fix underlying multiplication
- Still calculates wrong aggregates
- Performance worse (DISTINCT operation expensive)

### Approach 2: Nested Subqueries
```sql
-- ❌ Rejected
SELECT 
    d.nombre,
    (SELECT COUNT(*) FROM gestiones WHERE ...) as gestiones,
    (SELECT SUM(...) FROM pagos WHERE ...) as pagos
FROM deudores d
```
**Problems:**
- Correlated subqueries = N+1 query problem
- Executes subquery for EACH debtor
- Much slower than CTEs

### Approach 3: Temporary Tables
```sql
-- ⚠️ Valid but less elegant
CREATE TEMP TABLE temp_gestiones AS ...
CREATE TEMP TABLE temp_pagos AS ...
SELECT ... JOIN temp_gestiones ...
```
**Drawbacks:**
- Requires explicit cleanup
- Not transaction-safe
- More boilerplate code
- CTEs are cleaner

### Approach 4: Views
```sql
-- ⚠️ Valid for reusability
CREATE VIEW v_gestiones_agg AS ...
```
**When to use:**
- If aggregations needed by multiple queries
- For this single-use case, CTEs are better

## 📊 Database Engine Optimizations

### PostgreSQL Specific
```sql
-- CTE Materialization Control (PostgreSQL 12+)
WITH preproc_gestiones AS MATERIALIZED (
    -- Forces materialization
)

WITH preproc_gestiones AS NOT MATERIALIZED (
    -- Allows inline expansion
)
```

**When to materialize:**
- CTE used multiple times in query
- CTE result set small enough to fit in work_mem
- CTE computation expensive

### SQL Server Specific
```sql
-- Similar pattern works with:
-- - Temporary tables (#temp)
-- - Table variables (@table)
-- - CTEs (WITH clause)

-- SQL Server doesn't materialize CTEs by default
-- May need to use temp tables for large datasets
```

### MySQL Specific (8.0+)
```sql
-- MySQL 8.0+ supports CTEs
-- Earlier versions: Use derived tables or temp tables
-- Optimization: STRAIGHT_JOIN hint if needed
```

## 🎓 Learning from This Pattern

### Key Takeaways

1. **Always aggregate before joining** when dealing with one-to-many relationships
2. **Use CTEs for readability** and maintainability
3. **Test each layer independently** before combining
4. **Monitor query plans** to verify optimization
5. **Document defensive decisions** for future maintainers

### When to Apply This Pattern

✅ **Use this pattern when:**
- Multiple one-to-many relationships exist
- Aggregations needed from child tables
- Data quality might have duplicates
- Query needs to be maintainable

❌ **Don't use this pattern when:**
- Single JOIN with one-to-one relationship
- No aggregations needed
- Query is already simple and fast
- Overhead of CTEs outweighs benefits

## 📚 References

### SQL Optimization Resources
1. "Use The Index, Luke" - Markus Winand
2. "SQL Performance Explained" - Markus Winand
3. PostgreSQL Documentation: Query Planning
4. "SQL Antipatterns" - Bill Karwin

### Design Patterns
1. "Refactoring SQL Applications" - John P. Diedrich
2. "The Art of SQL" - Stéphane Faroult

### Related Techniques
- Window Functions (alternative for some aggregations)
- LATERAL JOINs (PostgreSQL-specific)
- APPLY operator (SQL Server)

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-29  
**Maintained By:** Iván A. Jarpa Manríquez
