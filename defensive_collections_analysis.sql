/*
================================================================================
DEFENSIVE SQL QUERY WITH CTEs FOR COLLECTIONS ANALYSIS
================================================================================

Author: Iván A. Jarpa Manríquez
Purpose: Identify debtors with collection efforts but no recorded payments
Strategy: Use CTEs to prevent record multiplication in consecutive JOINs

Business Case:
- Detect accounts with active collections but zero payment results
- Identify collection-resistant debtors requiring strategic intervention
- Optimize resource allocation in collections department

================================================================================
*/

-- =============================================================================
-- CTE 1: DEBTORS PREPROCESSING
-- =============================================================================
-- Purpose: Ensure unique debtor records at the base level
-- Defensive Logic: GROUP BY prevents duplicates from source data quality issues
-- Cardinality: 1 record per debtor
-- =============================================================================

WITH preproc_deudores AS (
    SELECT
        deudor_id,
        nombre,
        apellido
    FROM deudores
    GROUP BY deudor_id, nombre, apellido
),

-- =============================================================================
-- CTE 2: DEBTS PREPROCESSING
-- =============================================================================
-- Purpose: Establish clean debtor-to-debt relationship
-- Defensive Logic: Simple projection maintaining one-to-many relationship
-- Cardinality: 1 record per debt
-- =============================================================================

preproc_deuda AS (
    SELECT
        deudor_id,
        deuda_id
    FROM deudas
),

-- =============================================================================
-- CTE 3: COLLECTIONS PREPROCESSING (CRITICAL AGGREGATION)
-- =============================================================================
-- Purpose: Aggregate multiple collection efforts per debt into single metric
-- Defensive Logic: COUNT collapses N collection records into 1 aggregated value
-- Cardinality: 1 record per debt (PREVENTS MULTIPLICATION)
-- Output: Total count of collection efforts per debt
-- =============================================================================

preproc_gestiones AS (
    SELECT
        deuda_id,
        COUNT(gestion_id) AS conteo_gestiones
    FROM gestiones
    GROUP BY deuda_id
),

-- =============================================================================
-- CTE 4: PAYMENTS PREPROCESSING (CRITICAL AGGREGATION)
-- =============================================================================
-- Purpose: Aggregate multiple payments per debt into single total
-- Defensive Logic: SUM collapses N payment records into 1 aggregated value
-- Cardinality: 1 record per debt (PREVENTS MULTIPLICATION)
-- Output: Total payment amount per debt
-- =============================================================================

preproc_pagos AS (
    SELECT
        deuda_id,
        SUM(monto_pagado) AS pagos
    FROM pagos
    GROUP BY deuda_id
)

-- =============================================================================
-- FINAL SELECT: CONTROLLED JOIN STRATEGY
-- =============================================================================
-- Join Flow:
--   preproc_deudores (1 per debtor)
--       ↓ LEFT JOIN
--   preproc_deuda (N per debtor)
--       ↓ LEFT JOIN
--   preproc_gestiones (1 per debt - AGGREGATED)
--       ↓ LEFT JOIN
--   preproc_pagos (1 per debt - AGGREGATED)
--
-- Result: No cartesian explosion due to pre-aggregated CTEs
-- =============================================================================

SELECT
    pd.nombre,
    pd.apellido,
    pg.conteo_gestiones,
    pp.pagos
FROM preproc_deudores pd
LEFT JOIN preproc_deuda pde
    ON pd.deudor_id = pde.deudor_id
LEFT JOIN preproc_gestiones pg
    ON pde.deuda_id = pg.deuda_id
LEFT JOIN preproc_pagos pp
    ON pg.deuda_id = pp.deuda_id

-- =============================================================================
-- FILTERING LOGIC
-- =============================================================================
-- Business Rule: Find debts with collections but no payments
-- - conteo_gestiones IS NOT NULL: At least one collection effort exists
-- - pagos IS NULL: No payments recorded for this debt
-- =============================================================================

WHERE conteo_gestiones IS NOT NULL
    AND pagos IS NULL;

/*
================================================================================
PERFORMANCE NOTES:
================================================================================

Recommended Indexes:
    CREATE INDEX idx_deudas_deudor ON deudas(deudor_id, deuda_id);
    CREATE INDEX idx_gestiones_deuda ON gestiones(deuda_id);
    CREATE INDEX idx_pagos_deuda ON pagos(deuda_id);

Query Execution Benefits:
    - Pre-aggregation reduces intermediate result sets
    - No cartesian product formation
    - Each JOIN adds maximum 1 record per debt
    - Debuggable: Each CTE can be tested independently

Testing Individual CTEs:
    -- SELECT * FROM preproc_deudores LIMIT 10;
    -- SELECT * FROM preproc_gestiones ORDER BY conteo_gestiones DESC LIMIT 10;
    -- SELECT * FROM preproc_pagos ORDER BY pagos DESC LIMIT 10;

================================================================================
*/
