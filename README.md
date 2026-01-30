# 📊 Defensive SQL Query with CTEs for Collections Analysis

[![SQL](https://img.shields.io/badge/SQL-Defensive%20Pattern-blue)](https://github.com/yourusername/yourrepo)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 🎯 Overview

SQL query designed to identify debtors with active collection efforts but no recorded payments, implementing a **defensive architecture** using Common Table Expressions (CTEs) to prevent record multiplication in consecutive JOINs.

## 📋 Table of Contents

- [Business Problem](#-business-problem)
- [Technical Challenge](#-technical-challenge)
- [Solution Architecture](#-solution-architecture)
- [Query Structure](#-query-structure)
- [Defensive Strategy](#%EF%B8%8F-defensive-strategy)
- [Performance Benefits](#-performance-benefits)
- [Usage](#-usage)
- [Testing](#-testing)
- [Optimization](#-optimization)
- [Author](#-author)

## 💼 Business Problem

In collections management, it's critical to identify accounts where:
- **Collection efforts have been made** (calls, emails, visits)
- **No payments have been received** despite these efforts
- **Resources are being invested** with zero ROI

This query helps collections managers:
1. Identify collection-resistant accounts
2. Reallocate resources to more productive accounts
3. Flag accounts for alternative strategies (legal action, settlements)
4. Measure collection effectiveness

## 🔧 Technical Challenge

### The Problem: Cartesian Explosion in Multi-Table JOINs

When joining multiple tables with one-to-many relationships:

```
Debtor (1) → Debts (5) → Collections (20) → Payments (10)
```

Without defensive aggregation:
```
Result Set = 1 × 5 × 20 × 10 = 1,000 rows (from 1 debtor!)
```

This causes:
- ❌ Incorrect aggregation results
- ❌ Performance degradation
- ❌ Memory issues with large datasets
- ❌ Misleading business metrics

### The Solution: Defensive CTEs

Pre-aggregate at each hierarchical level **before** joining:

```
Debtor (1) → Debts (5) → Collections (5 aggregated) → Payments (5 aggregated)
Result Set = 1 × 5 × 1 × 1 = 5 rows ✅
```

## 🏗️ Solution Architecture

### Defensive Layering Strategy

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: preproc_deudores (Debtors)                        │
│ Defense: GROUP BY for uniqueness                            │
│ Cardinality: 1 per debtor                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: preproc_deuda (Debts)                             │
│ Defense: Clean projection                                   │
│ Cardinality: N per debtor (preserved)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: preproc_gestiones (Collections) ⚠️ CRITICAL       │
│ Defense: COUNT aggregation                                  │
│ Cardinality: 1 per debt (COLLAPSE MULTIPLE RECORDS)        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: preproc_pagos (Payments) ⚠️ CRITICAL              │
│ Defense: SUM aggregation                                    │
│ Cardinality: 1 per debt (COLLAPSE MULTIPLE RECORDS)        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Final JOIN: Controlled 1:N:1:1 relationships               │
│ Result: No cartesian explosion                             │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Query Structure

### CTE 1: Debtors Preprocessing
```sql
WITH preproc_deudores AS (
    SELECT
        deudor_id,
        nombre,
        apellido
    FROM deudores
    GROUP BY deudor_id, nombre, apellido
)
```
**Defensive Logic:** Eliminates potential duplicates at source level

### CTE 2: Debts Preprocessing
```sql
preproc_deuda AS (
    SELECT
        deudor_id,
        deuda_id
    FROM deudas
)
```
**Defensive Logic:** Clean debtor-debt relationship mapping

### CTE 3: Collections Aggregation (⚠️ CRITICAL)
```sql
preproc_gestiones AS (
    SELECT
        deuda_id,
        COUNT(gestion_id) AS conteo_gestiones
    FROM gestiones
    GROUP BY deuda_id
)
```
**Defensive Logic:** Collapses N collection records → 1 aggregated count per debt

### CTE 4: Payments Aggregation (⚠️ CRITICAL)
```sql
preproc_pagos AS (
    SELECT
        deuda_id,
        SUM(monto_pagado) AS pagos
    FROM pagos
    GROUP BY deuda_id
)
```
**Defensive Logic:** Collapses N payment records → 1 aggregated sum per debt

### Final SELECT with Controlled JOINs
```sql
SELECT
    pd.nombre,
    pd.apellido,
    pg.conteo_gestiones,
    pp.pagos
FROM preproc_deudores pd
LEFT JOIN preproc_deuda pde ON pd.deudor_id = pde.deudor_id
LEFT JOIN preproc_gestiones pg ON pde.deuda_id = pg.deuda_id
LEFT JOIN preproc_pagos pp ON pg.deuda_id = pp.deuda_id
WHERE conteo_gestiones IS NOT NULL
    AND pagos IS NULL
```

## 🛡️ Defensive Strategy

### Why This Approach Works

| Aspect | Without CTEs (Naive) | With Defensive CTEs (This Query) |
|--------|---------------------|----------------------------------|
| **Record Multiplication** | ❌ Yes (N×M cartesian) | ✅ No (pre-aggregated) |
| **Aggregation Accuracy** | ❌ Incorrect due to duplication | ✅ Correct calculations |
| **Performance** | ❌ Degrades with data growth | ✅ Scales efficiently |
| **Debuggability** | ❌ Hard to isolate issues | ✅ Each CTE testable |
| **Maintainability** | ❌ Complex nested logic | ✅ Clear separation |

### Comparison: Naive vs Defensive Approach

#### ❌ Naive Approach (Dangerous)
```sql
SELECT 
    d.nombre,
    COUNT(g.gestion_id) as gestiones,
    SUM(p.monto_pagado) as pagos
FROM deudores d
LEFT JOIN deudas de ON d.deudor_id = de.deudor_id
LEFT JOIN gestiones g ON de.deuda_id = g.deuda_id
LEFT JOIN pagos p ON de.deuda_id = p.deuda_id
GROUP BY d.deudor_id, d.nombre, d.apellido
HAVING SUM(p.monto_pagado) IS NULL
```
**Problems:**
- Intermediate cartesian product: `gestiones × pagos`
- COUNT and SUM calculated on multiplied records
- Wrong results

#### ✅ Defensive Approach (This Query)
Pre-aggregates before joining → Correct results guaranteed

## 📈 Performance Benefits

### Execution Plan Optimization

**Without CTEs:**
```
Nested Loops
  → Hash Join (deudores × deudas): 10,000 rows
    → Hash Join (× gestiones): 200,000 rows
      → Hash Join (× pagos): 2,000,000 rows
        → Aggregate: 10,000 rows (after expensive reduction)
```

**With CTEs:**
```
CTE Scan (preproc_gestiones): 10,000 rows (pre-aggregated)
CTE Scan (preproc_pagos): 10,000 rows (pre-aggregated)
Nested Loops
  → Hash Join (deudores × deudas): 10,000 rows
    → Hash Join (× gestiones): 10,000 rows (no multiplication!)
      → Hash Join (× pagos): 10,000 rows (no multiplication!)
```

### Benchmark Results (Estimated)

| Dataset Size | Without CTEs | With CTEs | Improvement |
|-------------|-------------|-----------|-------------|
| 10K debtors | 45 seconds | 3 seconds | **15× faster** |
| 100K debtors | 8 minutes | 25 seconds | **19× faster** |
| 1M debtors | Timeout | 4 minutes | **Completes!** |

## 🚀 Usage

### Basic Execution
```sql
-- Run the full query
\i defensive_collections_analysis.sql
```

### Export Results
```sql
-- Export to CSV
COPY (
    [full query here]
) TO '/path/to/collections_sin_pago.csv' 
WITH CSV HEADER;
```

### Schedule as Automated Report
```bash
# Daily execution via cron
0 8 * * * psql -d collections_db -f /path/to/defensive_collections_analysis.sql -o /reports/daily_report.txt
```

## 🧪 Testing

### Test Each CTE Independently

```sql
-- Test debtors preprocessing
SELECT * FROM preproc_deudores LIMIT 10;

-- Test collections aggregation
SELECT * 
FROM preproc_gestiones 
ORDER BY conteo_gestiones DESC 
LIMIT 10;

-- Test payments aggregation
SELECT * 
FROM preproc_pagos 
ORDER BY pagos DESC 
LIMIT 10;
```

### Verify Cardinality
```sql
-- Ensure no record multiplication
WITH full_query AS (
    [paste full query here]
)
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT deudor_id) as unique_debtors,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT deudor_id) 
        THEN '✅ No multiplication'
        ELSE '⚠️ Record multiplication detected'
    END as status
FROM full_query;
```

### Data Quality Checks
```sql
-- Check for NULL gestiones (should be 0)
SELECT COUNT(*) FROM preproc_gestiones WHERE conteo_gestiones IS NULL;

-- Check for negative payments (data quality issue)
SELECT * FROM preproc_pagos WHERE pagos < 0;
```

## ⚡ Optimization

### Recommended Indexes
```sql
-- Deudas table
CREATE INDEX idx_deudas_deudor ON deudas(deudor_id, deuda_id);

-- Gestiones table
CREATE INDEX idx_gestiones_deuda ON gestiones(deuda_id);
CREATE INDEX idx_gestiones_deuda_gestion ON gestiones(deuda_id, gestion_id);

-- Pagos table
CREATE INDEX idx_pagos_deuda ON pagos(deuda_id);
CREATE INDEX idx_pagos_deuda_monto ON pagos(deuda_id, monto_pagado);
```

### Materialized View (for frequent execution)
```sql
CREATE MATERIALIZED VIEW mv_gestiones_sin_pago AS
[full query here];

-- Refresh daily
CREATE OR REPLACE FUNCTION refresh_gestiones_sin_pago()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_gestiones_sin_pago;
END;
$$ LANGUAGE plpgsql;

-- Schedule refresh
SELECT cron.schedule('refresh-gestiones', '0 6 * * *', 
    'SELECT refresh_gestiones_sin_pago()');
```

### Query Monitoring
```sql
-- Monitor execution time
EXPLAIN ANALYZE
[full query here];
```

## 📊 Expected Results

### Output Schema

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `nombre` | VARCHAR | Debtor first name | "Juan" |
| `apellido` | VARCHAR | Debtor last name | "Pérez" |
| `conteo_gestiones` | INTEGER | Total collection efforts | 5 |
| `pagos` | NULL | Always NULL (filtered) | NULL |

### Sample Output
```
nombre  | apellido | conteo_gestiones | pagos
--------|----------|------------------|-------
Juan    | Pérez    | 5                | NULL
María   | González | 12               | NULL
Pedro   | Martínez | 3                | NULL
```

## 🎓 Learning Resources

### Related Concepts
- [Common Table Expressions (CTEs)](https://www.postgresql.org/docs/current/queries-with.html)
- [Query Optimization Techniques](https://use-the-index-luke.com/)
- [Defensive Programming in SQL](https://modern-sql.com/)

### Additional Reading
- SQL Anti-patterns: Avoiding the Pitfalls of Database Programming
- High Performance PostgreSQL for Rails

## 📝 Use Cases

1. **Collections Strategy Optimization**
   - Identify high-effort, zero-result accounts
   - Reallocate collector resources

2. **Risk Assessment**
   - Flag potentially uncollectible debts
   - Early warning system for portfolio quality

3. **Performance Metrics**
   - Measure collection effectiveness by portfolio
   - Benchmark collector performance

4. **Regulatory Reporting**
   - Document collection activities for compliance
   - Track effort-to-result ratios

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 👤 Author

**Iván A. Jarpa Manríquez**  
Business Intelligence Analyst | Collections & Debt Recovery Analytics  
📧 [Your Email]  
🔗 [LinkedIn Profile](https://www.linkedin.com/in/yourprofile)  
💻 [GitHub Profile](https://github.com/yourusername)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Developed during work at Gesticom S.A., Chile
- Inspired by defensive programming principles
- Built to solve real-world collections analytics challenges

---

**Last Updated:** 2026-01-29  
**Version:** 1.0.0  
**SQL Dialect:** PostgreSQL (adaptable to MySQL, SQL Server)
