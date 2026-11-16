/*
KSOLUTIONS DATA ANALYST ASSESSMENT
PHASE 1 - Q3 CLIENT PROFITABILITY
Dialect: MySQL (not PostgreSQL)
===============================================================================
*/

-- =============================================================================
-- 1. DATABASE
-- =============================================================================

CREATE DATABASE IF NOT EXISTS ksolutions_assessment
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE ksolutions_assessment;

SELECT DATABASE() AS active_database;
SELECT VERSION() AS mysql_version;

-- =============================================================================
-- 2. RAW STAGING TABLES
--    Keep imported source data as text to preserve the original values.
--    If tables already exist, CREATE TABLE IF NOT EXISTS will not overwrite them.
-- =============================================================================

CREATE TABLE IF NOT EXISTS stg_cloud_compute_logs (
    client_id       VARCHAR(50),
    timestamp_utc   VARCHAR(100),
    server_id       VARCHAR(100),
    cost_usd        VARCHAR(50),
    config_tags     LONGTEXT
);

CREATE TABLE IF NOT EXISTS stg_support_tickets (
    ticket_id        VARCHAR(100),
    client_id        VARCHAR(50),
    created_at_utc   VARCHAR(100),
    resolved_at_utc  VARCHAR(100),
    issue_category   VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS stg_sla_contracts (
    client_id          VARCHAR(50),
    contract_start_date VARCHAR(100),
    contract_end_date   VARCHAR(100),
    sla_hours           VARCHAR(50),
    penalty_rate_pct    VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS stg_daily_fx_rates (
    rate_date       VARCHAR(100),
    currency_pair   VARCHAR(50),
    exchange_rate   VARCHAR(50)
);

-- This is the Phase 2 churn-history file shown in your screenshot.
-- It is included here only to provide a possible revenue proxy for Phase 1.
CREATE TABLE IF NOT EXISTS stg_client_churn_history (
    client_id                VARCHAR(50),
    industry                 VARCHAR(100),
    monthly_spend_usd        VARCHAR(50),
    total_q3_complaints      VARCHAR(50),
    last_system_login_days   VARCHAR(50),
    downgraded_status        VARCHAR(50)
);

SHOW TABLES;

-- =============================================================================
-- 3. IMPORT CHECKS
--    Import each CSV into its matching stg_ table before continuing.
-- =============================================================================

SELECT 'cloud_compute_logs' AS dataset, COUNT(*) AS row_count
FROM stg_cloud_compute_logs
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM stg_support_tickets
UNION ALL
SELECT 'sla_contracts', COUNT(*) FROM stg_sla_contracts
UNION ALL
SELECT 'daily_fx_rates', COUNT(*) FROM stg_daily_fx_rates
UNION ALL
SELECT 'client_churn_history', COUNT(*) FROM stg_client_churn_history;

-- Preview imported records.
SELECT * FROM stg_cloud_compute_logs LIMIT 10;
SELECT * FROM stg_support_tickets LIMIT 10;
SELECT * FROM stg_sla_contracts LIMIT 10;
SELECT * FROM stg_daily_fx_rates LIMIT 10;
SELECT * FROM stg_client_churn_history LIMIT 10;

-- =============================================================================
-- 4. RAW DATA QUALITY CHECKS
--    These checks run before any conversion. Investigate exceptions rather
--    than silently deleting or replacing source records.
-- =============================================================================

-- 4.1 Missing values by dataset.
SELECT
    'cloud_compute_logs' AS dataset,
    COUNT(*) AS total_rows,
    SUM(client_id IS NULL OR TRIM(client_id) = '') AS missing_client_id,
    SUM(timestamp_utc IS NULL OR TRIM(timestamp_utc) = '') AS missing_timestamp,
    SUM(server_id IS NULL OR TRIM(server_id) = '') AS missing_server_id,
    SUM(cost_usd IS NULL OR TRIM(cost_usd) = '') AS missing_cost,
    SUM(config_tags IS NULL OR TRIM(config_tags) = '') AS missing_config_tags
FROM stg_cloud_compute_logs
UNION ALL
SELECT
    'support_tickets',
    COUNT(*),
    SUM(client_id IS NULL OR TRIM(client_id) = ''),
    SUM(created_at_utc IS NULL OR TRIM(created_at_utc) = ''),
    SUM(ticket_id IS NULL OR TRIM(ticket_id) = ''),
    SUM(resolved_at_utc IS NULL OR TRIM(resolved_at_utc) = ''),
    SUM(issue_category IS NULL OR TRIM(issue_category) = '')
FROM stg_support_tickets;

SELECT
    'sla_contracts' AS dataset,
    COUNT(*) AS total_rows,
    SUM(client_id IS NULL OR TRIM(client_id) = '') AS missing_client_id,
    SUM(contract_start_date IS NULL OR TRIM(contract_start_date) = '') AS missing_start_date,
    SUM(contract_end_date IS NULL OR TRIM(contract_end_date) = '') AS missing_end_date,
    SUM(sla_hours IS NULL OR TRIM(sla_hours) = '') AS missing_sla_hours,
    SUM(penalty_rate_pct IS NULL OR TRIM(penalty_rate_pct) = '') AS missing_penalty_rate
FROM stg_sla_contracts;

SELECT
    'daily_fx_rates' AS dataset,
    COUNT(*) AS total_rows,
    SUM(rate_date IS NULL OR TRIM(rate_date) = '') AS missing_rate_date,
    SUM(currency_pair IS NULL OR TRIM(currency_pair) = '') AS missing_currency_pair,
    SUM(exchange_rate IS NULL OR TRIM(exchange_rate) = '') AS missing_exchange_rate
FROM stg_daily_fx_rates;

SELECT
    'client_churn_history' AS dataset,
    COUNT(*) AS total_rows,
    SUM(client_id IS NULL OR TRIM(client_id) = '') AS missing_client_id,
    SUM(industry IS NULL OR TRIM(industry) = '') AS missing_industry,
    SUM(monthly_spend_usd IS NULL OR TRIM(monthly_spend_usd) = '') AS missing_monthly_spend,
    SUM(total_q3_complaints IS NULL OR TRIM(total_q3_complaints) = '') AS missing_complaints,
    SUM(downgraded_status IS NULL OR TRIM(downgraded_status) = '') AS missing_downgrade_status
FROM stg_client_churn_history;

-- 4.2 Duplicate checks. These queries report duplicates; they do not delete them.
SELECT ticket_id, COUNT(*) AS duplicate_count
FROM stg_support_tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;

SELECT client_id, timestamp_utc, server_id, COUNT(*) AS duplicate_count
FROM stg_cloud_compute_logs
GROUP BY client_id, timestamp_utc, server_id
HAVING COUNT(*) > 1;

SELECT client_id, contract_start_date, contract_end_date, COUNT(*) AS duplicate_count
FROM stg_sla_contracts
GROUP BY client_id, contract_start_date, contract_end_date
HAVING COUNT(*) > 1;

SELECT rate_date, currency_pair, COUNT(*) AS duplicate_count
FROM stg_daily_fx_rates
GROUP BY rate_date, currency_pair
HAVING COUNT(*) > 1;

SELECT client_id, COUNT(*) AS duplicate_count
FROM stg_client_churn_history
GROUP BY client_id
HAVING COUNT(*) > 1;

-- 4.3 Numeric format checks.
SELECT *
FROM stg_cloud_compute_logs
WHERE NULLIF(TRIM(cost_usd), '') IS NOT NULL
  AND TRIM(cost_usd) NOT REGEXP '^[0-9]+([.][0-9]+)?$';

SELECT *
FROM stg_sla_contracts
WHERE (NULLIF(TRIM(sla_hours), '') IS NOT NULL
       AND TRIM(sla_hours) NOT REGEXP '^[0-9]+([.][0-9]+)?$')
   OR (NULLIF(TRIM(penalty_rate_pct), '') IS NOT NULL
       AND TRIM(penalty_rate_pct) NOT REGEXP '^[0-9]+([.][0-9]+)?$');

SELECT *
FROM stg_daily_fx_rates
WHERE NULLIF(TRIM(exchange_rate), '') IS NOT NULL
  AND TRIM(exchange_rate) NOT REGEXP '^[0-9]+([.][0-9]+)?$';

SELECT *
FROM stg_client_churn_history
WHERE (NULLIF(TRIM(monthly_spend_usd), '') IS NOT NULL
       AND TRIM(monthly_spend_usd) NOT REGEXP '^[0-9]+([.][0-9]+)?$')
   OR (NULLIF(TRIM(total_q3_complaints), '') IS NOT NULL
       AND TRIM(total_q3_complaints) NOT REGEXP '^[0-9]+$')
   OR (NULLIF(TRIM(last_system_login_days), '') IS NOT NULL
       AND TRIM(last_system_login_days) NOT REGEXP '^[0-9]+$')
   OR (NULLIF(TRIM(downgraded_status), '') IS NOT NULL
       AND TRIM(downgraded_status) NOT REGEXP '^[01]$');

-- 4.4 JSON validation for config_tags.
SELECT
    config_tags,
    JSON_VALID(config_tags) AS is_valid_json
FROM stg_cloud_compute_logs
WHERE config_tags IS NOT NULL
  AND TRIM(config_tags) <> ''
  AND JSON_VALID(config_tags) = 0;

-- 4.5 Date/timestamp parsing checks using the formats visible in your samples:
--     timestamps: M/D/YYYY H:MM
--     dates:      M/D/YYYY
SELECT timestamp_utc
FROM stg_cloud_compute_logs
WHERE NULLIF(TRIM(timestamp_utc), '') IS NOT NULL
  AND STR_TO_DATE(TRIM(timestamp_utc), '%m/%d/%Y %H:%i') IS NULL;

SELECT created_at_utc, resolved_at_utc
FROM stg_support_tickets
WHERE (NULLIF(TRIM(created_at_utc), '') IS NOT NULL
       AND STR_TO_DATE(TRIM(created_at_utc), '%m/%d/%Y %H:%i') IS NULL)
   OR (NULLIF(TRIM(resolved_at_utc), '') IS NOT NULL
       AND STR_TO_DATE(TRIM(resolved_at_utc), '%m/%d/%Y %H:%i') IS NULL);

SELECT client_id, contract_start_date, contract_end_date
FROM stg_sla_contracts
WHERE (NULLIF(TRIM(contract_start_date), '') IS NOT NULL
       AND STR_TO_DATE(TRIM(contract_start_date), '%m/%d/%Y') IS NULL)
   OR (NULLIF(TRIM(contract_end_date), '') IS NOT NULL
       AND STR_TO_DATE(TRIM(contract_end_date), '%m/%d/%Y') IS NULL);

SELECT rate_date
FROM stg_daily_fx_rates
WHERE NULLIF(TRIM(rate_date), '') IS NOT NULL
  AND STR_TO_DATE(TRIM(rate_date), '%m/%d/%Y') IS NULL;

-- 5. CLEAN VIEWS
--    The raw staging tables remain unchanged. Invalid values become NULL in
--    the clean views and can be traced back to the original staging rows.
-- =============================================================================

CREATE OR REPLACE VIEW vw_cloud_compute_clean AS
SELECT
    NULLIF(TRIM(client_id), '') AS client_id,
    STR_TO_DATE(NULLIF(TRIM(timestamp_utc), ''), '%m/%d/%Y %H:%i') AS timestamp_utc,
    NULLIF(TRIM(server_id), '') AS server_id,
    CASE
        WHEN TRIM(cost_usd) REGEXP '^[0-9]+([.][0-9]+)?$'
        THEN CAST(TRIM(cost_usd) AS DECIMAL(18,6))
        ELSE NULL
    END AS cost_usd,
    NULLIF(TRIM(config_tags), '') AS config_tags,
    CASE
        WHEN config_tags IS NULL OR TRIM(config_tags) = '' THEN NULL
        WHEN JSON_VALID(config_tags) = 1 THEN 1
        ELSE 0
    END AS config_tags_valid
FROM stg_cloud_compute_logs;

CREATE OR REPLACE VIEW vw_support_tickets_clean AS
SELECT
    NULLIF(TRIM(ticket_id), '') AS ticket_id,
    NULLIF(TRIM(client_id), '') AS client_id,
    STR_TO_DATE(NULLIF(TRIM(created_at_utc), ''), '%m/%d/%Y %H:%i') AS created_at_utc,
    STR_TO_DATE(NULLIF(TRIM(resolved_at_utc), ''), '%m/%d/%Y %H:%i') AS resolved_at_utc,
    NULLIF(TRIM(issue_category), '') AS issue_category
FROM stg_support_tickets;

CREATE OR REPLACE VIEW vw_sla_contracts_clean AS
SELECT
    NULLIF(TRIM(client_id), '') AS client_id,
    STR_TO_DATE(NULLIF(TRIM(contract_start_date), ''), '%m/%d/%Y') AS contract_start_date,
    STR_TO_DATE(NULLIF(TRIM(contract_end_date), ''), '%m/%d/%Y') AS contract_end_date,
    CASE
        WHEN TRIM(sla_hours) REGEXP '^[0-9]+([.][0-9]+)?$'
        THEN CAST(TRIM(sla_hours) AS DECIMAL(10,2))
        ELSE NULL
    END AS sla_hours,
    CASE
        WHEN TRIM(penalty_rate_pct) REGEXP '^[0-9]+([.][0-9]+)?$'
        THEN CAST(TRIM(penalty_rate_pct) AS DECIMAL(10,4))
        ELSE NULL
    END AS penalty_rate_pct
FROM stg_sla_contracts;

CREATE OR REPLACE VIEW vw_daily_fx_rates_clean AS
SELECT
    STR_TO_DATE(NULLIF(TRIM(rate_date), ''), '%m/%d/%Y') AS rate_date,
    UPPER(NULLIF(TRIM(currency_pair), '')) AS currency_pair,
    CASE
        WHEN TRIM(exchange_rate) REGEXP '^[0-9]+([.][0-9]+)?$'
        THEN CAST(TRIM(exchange_rate) AS DECIMAL(18,6))
        ELSE NULL
    END AS exchange_rate
FROM stg_daily_fx_rates;

CREATE OR REPLACE VIEW vw_client_churn_clean AS
SELECT
    NULLIF(TRIM(client_id), '') AS source_client_id,
    NULLIF(TRIM(industry), '') AS industry,
    CASE
        WHEN TRIM(monthly_spend_usd) REGEXP '^[0-9]+([.][0-9]+)?$'
        THEN CAST(TRIM(monthly_spend_usd) AS DECIMAL(18,2))
        ELSE NULL
    END AS monthly_spend_usd,
    CASE
        WHEN TRIM(total_q3_complaints) REGEXP '^[0-9]+$'
        THEN CAST(TRIM(total_q3_complaints) AS UNSIGNED)
        ELSE NULL
    END AS total_q3_complaints,
    CASE
        WHEN TRIM(last_system_login_days) REGEXP '^[0-9]+$'
        THEN CAST(TRIM(last_system_login_days) AS UNSIGNED)
        ELSE NULL
    END AS last_system_login_days,
    CASE
        WHEN TRIM(downgraded_status) IN ('0', '1')
        THEN CAST(TRIM(downgraded_status) AS UNSIGNED)
        ELSE NULL
    END AS downgraded_status
FROM stg_client_churn_history;

-- Check clean views.
SELECT * FROM vw_cloud_compute_clean LIMIT 10;
SELECT * FROM vw_support_tickets_clean LIMIT 10;
SELECT * FROM vw_sla_contracts_clean ORDER BY client_id, contract_start_date;
SELECT * FROM vw_daily_fx_rates_clean ORDER BY rate_date LIMIT 10;
SELECT * FROM vw_client_churn_clean LIMIT 10;

-- =============================================================================
-- 6. Q3 PERIOD AND COVERAGE
--    Q3 2026 is inclusive of July 1 and exclusive of October 1.
-- =============================================================================

SET @q3_start = CAST('2026-07-01 00:00:00' AS DATETIME);
SET @q3_end   = CAST('2026-10-01 00:00:00' AS DATETIME);

SELECT
    'Cloud compute' AS dataset,
    MIN(timestamp_utc) AS first_timestamp,
    MAX(timestamp_utc) AS last_timestamp,
    COUNT(*) AS total_rows,
    SUM(timestamp_utc >= @q3_start AND timestamp_utc < @q3_end) AS q3_rows
FROM vw_cloud_compute_clean
UNION ALL
SELECT
    'Support tickets',
    MIN(created_at_utc),
    MAX(created_at_utc),
    COUNT(*),
    SUM(created_at_utc >= @q3_start AND created_at_utc < @q3_end)
FROM vw_support_tickets_clean;

SELECT
    currency_pair,
    MIN(rate_date) AS first_rate_date,
    MAX(rate_date) AS last_rate_date,
    COUNT(*) AS rate_rows,
    SUM(rate_date >= DATE(@q3_start) AND rate_date < DATE(@q3_end)) AS q3_rate_rows
FROM vw_daily_fx_rates_clean
GROUP BY currency_pair;

-- =============================================================================
-- 7. Q3 CLOUD COST ANALYSIS
--    Each row's cost_usd is summed once. Confirm from the source specification
--    that each row represents an additive hourly cost observation.
-- =============================================================================

CREATE OR REPLACE VIEW vw_q3_cloud_cost_by_client AS
SELECT
    client_id,
    COUNT(*) AS q3_cloud_log_rows,
    COUNT(DISTINCT server_id) AS distinct_servers,
    SUM(cost_usd) AS q3_cloud_cost_usd,
    SUM(cost_usd IS NULL) AS rows_with_invalid_cost
FROM vw_cloud_compute_clean
WHERE timestamp_utc >= '2026-07-01 00:00:00'
  AND timestamp_utc <  '2026-10-01 00:00:00'
GROUP BY client_id;

SELECT
    client_id,
    q3_cloud_log_rows,
    distinct_servers,
    ROUND(q3_cloud_cost_usd, 2) AS q3_cloud_cost_usd,
    rows_with_invalid_cost
FROM vw_q3_cloud_cost_by_client
ORDER BY q3_cloud_cost_usd DESC;

-- Optional: inspect JSON configuration tags.
SELECT
    client_id,
    server_id,
    timestamp_utc,
    config_tags,
    CASE WHEN config_tags_valid = 1
         THEN JSON_UNQUOTE(JSON_EXTRACT(config_tags, '$.environment'))
         ELSE NULL
    END AS environment_tag,
    CASE WHEN config_tags_valid = 1
         THEN JSON_UNQUOTE(JSON_EXTRACT(config_tags, '$.ENV'))
         ELSE NULL
    END AS env_tag_upper,
    CASE WHEN config_tags_valid = 1
         THEN JSON_UNQUOTE(JSON_EXTRACT(config_tags, '$.project_id'))
         ELSE NULL
    END AS project_id
FROM vw_cloud_compute_clean
WHERE timestamp_utc >= '2026-07-01 00:00:00'
  AND timestamp_utc <  '2026-10-01 00:00:00'
LIMIT 100;

-- =============================================================================
-- 8. Q3 SUPPORT TICKET ANALYSIS
-- =============================================================================

CREATE OR REPLACE VIEW vw_q3_ticket_metrics_by_client AS
SELECT
    client_id,
    COUNT(*) AS q3_ticket_count,
    SUM(resolved_at_utc IS NULL) AS unresolved_ticket_count,
    SUM(
        resolved_at_utc IS NOT NULL
        AND resolved_at_utc < created_at_utc
    ) AS invalid_negative_duration_count,
    ROUND(
        AVG(
            CASE
                WHEN resolved_at_utc >= created_at_utc
                THEN TIMESTAMPDIFF(SECOND, created_at_utc, resolved_at_utc) / 3600.0
                ELSE NULL
            END
        ),
        2
    ) AS avg_resolution_hours,
    ROUND(
        MAX(
            CASE
                WHEN resolved_at_utc >= created_at_utc
                THEN TIMESTAMPDIFF(SECOND, created_at_utc, resolved_at_utc) / 3600.0
                ELSE NULL
            END
        ),
        2
    ) AS max_resolution_hours
FROM vw_support_tickets_clean
WHERE created_at_utc >= '2026-07-01 00:00:00'
  AND created_at_utc <  '2026-10-01 00:00:00'
GROUP BY client_id;

SELECT *
FROM vw_q3_ticket_metrics_by_client
ORDER BY q3_ticket_count DESC;

-- =============================================================================
-- 9. SLA MATCHING AND BREACH ANALYSIS
--    Contract is selected by ticket creation date. The end date is inclusive.
--    A ticket is counted as a breach if elapsed time is greater than sla_hours.
--    Unresolved Q3 tickets are measured up to the Q3 end boundary (Oct 1).
--    Tickets with zero or multiple matching contracts are flagged and excluded
--    from the valid SLA breach calculation until investigated.
-- =============================================================================

CREATE OR REPLACE VIEW vw_q3_ticket_sla_detail AS
WITH q3_tickets AS (
    SELECT
        ticket_id,
        client_id,
        created_at_utc,
        resolved_at_utc,
        issue_category,
        CASE
            WHEN resolved_at_utc IS NULL THEN
                TIMESTAMPDIFF(SECOND, created_at_utc, '2026-10-01 00:00:00')
            WHEN resolved_at_utc >= created_at_utc THEN
                TIMESTAMPDIFF(SECOND, created_at_utc, resolved_at_utc)
            ELSE NULL
        END AS elapsed_seconds_as_at_q3_end
    FROM vw_support_tickets_clean
    WHERE created_at_utc >= '2026-07-01 00:00:00'
      AND created_at_utc <  '2026-10-01 00:00:00'
),
contract_matches AS (
    SELECT
        t.ticket_id,
        t.client_id,
        t.created_at_utc,
        t.resolved_at_utc,
        t.issue_category,
        t.elapsed_seconds_as_at_q3_end,
        COUNT(s.client_id) AS matching_contract_count,
        MAX(s.sla_hours) AS matched_sla_hours,
        MAX(s.penalty_rate_pct) AS matched_penalty_rate_pct
    FROM q3_tickets t
    LEFT JOIN vw_sla_contracts_clean s
        ON s.client_id = t.client_id
       AND DATE(t.created_at_utc) >= s.contract_start_date
       AND DATE(t.created_at_utc) <= s.contract_end_date
    GROUP BY
        t.ticket_id,
        t.client_id,
        t.created_at_utc,
        t.resolved_at_utc,
        t.issue_category,
        t.elapsed_seconds_as_at_q3_end
)
SELECT
    ticket_id,
    client_id,
    created_at_utc,
    resolved_at_utc,
    issue_category,
    elapsed_seconds_as_at_q3_end,
    matching_contract_count,
    matched_sla_hours,
    matched_penalty_rate_pct,
    CASE
        WHEN matching_contract_count <> 1 THEN 'REVIEW_CONTRACT_MATCH'
        WHEN elapsed_seconds_as_at_q3_end IS NULL THEN 'INVALID_DURATION'
        WHEN elapsed_seconds_as_at_q3_end > matched_sla_hours * 3600
            THEN 'BREACH'
        ELSE 'WITHIN_SLA'
    END AS sla_status,
    CASE
        WHEN matching_contract_count = 1
         AND elapsed_seconds_as_at_q3_end > matched_sla_hours * 3600
        THEN 1 ELSE 0
    END AS is_sla_breach
FROM contract_matches;

SELECT *
FROM vw_q3_ticket_sla_detail
ORDER BY client_id, created_at_utc;

CREATE OR REPLACE VIEW vw_q3_sla_metrics_by_client AS
SELECT
    client_id,
    COUNT(*) AS q3_tickets,
    SUM(matching_contract_count = 0) AS tickets_without_contract,
    SUM(matching_contract_count > 1) AS tickets_with_multiple_contracts,
    SUM(matching_contract_count = 1) AS tickets_with_one_contract,
    SUM(sla_status = 'BREACH') AS sla_breaches,
    SUM(sla_status = 'WITHIN_SLA') AS tickets_within_sla,
    SUM(sla_status = 'INVALID_DURATION') AS tickets_with_invalid_duration,
    ROUND(
        100.0 * SUM(sla_status = 'BREACH')
        / NULLIF(SUM(matching_contract_count = 1
                     AND sla_status IN ('BREACH', 'WITHIN_SLA')), 0),
        2
    ) AS sla_breach_rate_pct,
    MAX(
        CASE WHEN is_sla_breach = 1
             THEN matched_penalty_rate_pct
             ELSE NULL
        END
    ) AS highest_penalty_rate_on_breached_tickets_pct
FROM vw_q3_ticket_sla_detail
GROUP BY client_id;

SELECT *
FROM vw_q3_sla_metrics_by_client
ORDER BY sla_breaches DESC;

-- =============================================================================
-- 10. CLIENT ID MAPPING AND REVENUE PROXY
-- =============================================================================

CREATE TABLE IF NOT EXISTS map_client_ids (
    source_client_id   VARCHAR(50) NOT NULL,
    finance_client_id  VARCHAR(50) NOT NULL,
    mapping_note       VARCHAR(255),
    PRIMARY KEY (source_client_id),
    INDEX idx_map_finance_client (finance_client_id)
);

-- Automatically map IDs only where the exact same ID exists in both sources.
-- This does NOT infer that C-0001 equals CLI-001.
INSERT IGNORE INTO map_client_ids
    (source_client_id, finance_client_id, mapping_note)
SELECT DISTINCT
    ch.source_client_id,
    ch.source_client_id,
    'Exact ID match found across churn and operational data'
FROM vw_client_churn_clean ch
WHERE ch.source_client_id IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM vw_support_tickets_clean t
      WHERE t.client_id = ch.source_client_id
  );

-- REVIEW THIS TABLE. Add verified mappings manually where the IDs differ.
SELECT *
FROM map_client_ids
ORDER BY source_client_id;

-- Example only - do not run without confirming the actual mapping:
-- INSERT INTO map_client_ids
--     (source_client_id, finance_client_id, mapping_note)
-- VALUES
--     ('C-0001', 'CLI-001', 'Verified against client master data');

-- Revenue proxy: monthly_spend_usd multiplied by 3.
-- MAX is used only to avoid multiplying revenue because of duplicate rows;
-- duplicates must still be investigated in the QA section.
CREATE OR REPLACE VIEW vw_q3_revenue_proxy_by_client AS
SELECT
    m.finance_client_id AS client_id,
    COUNT(*) AS mapped_churn_rows,
    MAX(ch.monthly_spend_usd) AS monthly_spend_usd,
    MAX(ch.monthly_spend_usd) * 3 AS estimated_q3_revenue_usd
FROM vw_client_churn_clean ch
INNER JOIN map_client_ids m
    ON m.source_client_id = ch.source_client_id
WHERE ch.monthly_spend_usd IS NOT NULL
GROUP BY m.finance_client_id;

SELECT *
FROM vw_q3_revenue_proxy_by_client
ORDER BY estimated_q3_revenue_usd DESC;

-- Show churn records that have no verified client mapping.
SELECT
    ch.source_client_id,
    ch.industry,
    ch.monthly_spend_usd
FROM vw_client_churn_clean ch
LEFT JOIN map_client_ids m
    ON m.source_client_id = ch.source_client_id
WHERE m.source_client_id IS NULL;

-- =============================================================================
-- 11. FX ANALYSIS / COVERAGE
--    No FX conversion is applied to USD cloud costs.
--    This section checks that Q3 rates exist and are usable if a future
--    NGN-denominated revenue/cost source is provided.
-- =============================================================================

SELECT
    currency_pair,
    COUNT(*) AS q3_rate_rows,
    MIN(exchange_rate) AS min_exchange_rate,
    MAX(exchange_rate) AS max_exchange_rate,
    AVG(exchange_rate) AS avg_exchange_rate
FROM vw_daily_fx_rates_clean
WHERE rate_date >= '2026-07-01'
  AND rate_date <  '2026-10-01'
GROUP BY currency_pair;

-- Missing or invalid Q3 FX dates.
SELECT *
FROM vw_daily_fx_rates_clean
WHERE rate_date >= '2026-07-01'
  AND rate_date <  '2026-10-01'
  AND (exchange_rate IS NULL OR exchange_rate <= 0);

-- 12. CLIENT-LEVEL Q3 PROFITABILITY SCENARIO
--
-- Assumptions in this scenario:
--   A. Revenue proxy = monthly_spend_usd * 3.
--   B. Cloud costs = sum of cost_usd records during Q3.
--   C. SLA penalty scenario = Q3 revenue * highest applicable penalty rate
--      among breached tickets, applied ONCE per client for the quarter.
--
-- The assessment does not state this penalty formula. Treat the result as a
-- scenario until the contract's exact penalty calculation rule is confirmed.
-- This is not a fully loaded margin because overtime and other costs are absent.

CREATE OR REPLACE VIEW vw_q3_client_profitability_scenario AS
WITH client_universe AS (
    SELECT client_id FROM vw_q3_cloud_cost_by_client
    UNION
    SELECT client_id FROM vw_q3_sla_metrics_by_client
    UNION
    SELECT client_id FROM vw_q3_revenue_proxy_by_client
),
combined AS (
    SELECT
        u.client_id,
        r.monthly_spend_usd,
        r.estimated_q3_revenue_usd,
        c.q3_cloud_cost_usd,
        c.q3_cloud_log_rows,
        s.q3_tickets,
        s.sla_breaches,
        s.tickets_without_contract,
        s.tickets_with_multiple_contracts,
        s.sla_breach_rate_pct,
        s.highest_penalty_rate_on_breached_tickets_pct
    FROM client_universe u
    LEFT JOIN vw_q3_revenue_proxy_by_client r
        ON r.client_id = u.client_id
    LEFT JOIN vw_q3_cloud_cost_by_client c
        ON c.client_id = u.client_id
    LEFT JOIN vw_q3_sla_metrics_by_client s
        ON s.client_id = u.client_id
),
penalty_calc AS (
    SELECT
        *,
        CASE
            WHEN estimated_q3_revenue_usd IS NULL THEN NULL
            WHEN COALESCE(sla_breaches, 0) = 0 THEN 0
            WHEN highest_penalty_rate_on_breached_tickets_pct IS NULL THEN NULL
            ELSE estimated_q3_revenue_usd
                 * highest_penalty_rate_on_breached_tickets_pct / 100.0
        END AS estimated_sla_penalty_usd
    FROM combined
)
SELECT
    client_id,
    monthly_spend_usd,
    estimated_q3_revenue_usd,
    q3_cloud_cost_usd,
    q3_cloud_log_rows,
    q3_tickets,
    sla_breaches,
    sla_breach_rate_pct,
    highest_penalty_rate_on_breached_tickets_pct,
    estimated_sla_penalty_usd,
    CASE
        WHEN estimated_q3_revenue_usd IS NULL
          OR estimated_sla_penalty_usd IS NULL
        THEN NULL
        ELSE estimated_q3_revenue_usd
             - COALESCE(q3_cloud_cost_usd, 0)
             - estimated_sla_penalty_usd
    END AS scenario_profit_before_other_costs_usd,
    CASE
        WHEN estimated_q3_revenue_usd IS NULL
          OR estimated_q3_revenue_usd = 0
          OR estimated_sla_penalty_usd IS NULL
        THEN NULL
        ELSE 100.0 * (
            estimated_q3_revenue_usd
            - COALESCE(q3_cloud_cost_usd, 0)
            - estimated_sla_penalty_usd
        ) / estimated_q3_revenue_usd
    END AS scenario_true_margin_pct,
    CASE
        WHEN estimated_q3_revenue_usd IS NULL THEN 'MISSING_REVENUE_MAPPING'
        WHEN estimated_sla_penalty_usd IS NULL THEN 'PENALTY_RULE_REQUIRES_REVIEW'
        WHEN estimated_q3_revenue_usd = 0 THEN 'ZERO_REVENUE'
        WHEN (
            estimated_q3_revenue_usd
            - COALESCE(q3_cloud_cost_usd, 0)
            - estimated_sla_penalty_usd
        ) < 0 THEN 'UNPROFITABLE'
        ELSE 'PROFITABLE_BEFORE_OTHER_COSTS'
    END AS profitability_status,
    tickets_without_contract,
    tickets_with_multiple_contracts
FROM penalty_calc;

SELECT
    client_id,
    ROUND(estimated_q3_revenue_usd, 2) AS estimated_q3_revenue_usd,
    ROUND(q3_cloud_cost_usd, 2) AS q3_cloud_cost_usd,
    ROUND(estimated_sla_penalty_usd, 2) AS estimated_sla_penalty_usd,
    ROUND(scenario_profit_before_other_costs_usd, 2)
        AS scenario_profit_before_other_costs_usd,
    ROUND(scenario_true_margin_pct, 2) AS scenario_true_margin_pct,
    profitability_status,
    sla_breaches,
    tickets_without_contract,
    tickets_with_multiple_contracts
FROM vw_q3_client_profitability_scenario
ORDER BY scenario_true_margin_pct ASC;

-- 13. FINAL EXCEPTION / CONTROL REPORT

-- Clients with missing revenue mapping or penalty-rule issues.
SELECT *
FROM vw_q3_client_profitability_scenario
WHERE profitability_status IN (
    'MISSING_REVENUE_MAPPING',
    'PENALTY_RULE_REQUIRES_REVIEW',
    'ZERO_REVENUE'
)
ORDER BY client_id;

-- Tickets requiring contract matching review.
SELECT *
FROM vw_q3_ticket_sla_detail
WHERE matching_contract_count <> 1
   OR sla_status = 'INVALID_DURATION'
ORDER BY client_id, created_at_utc;

-- Cloud records with invalid costs, timestamps, or malformed JSON.
SELECT *
FROM vw_cloud_compute_clean
WHERE client_id IS NULL
   OR timestamp_utc IS NULL
   OR cost_usd IS NULL
   OR config_tags_valid = 0;

-- Duplicate or conflicting churn records that could affect revenue proxy.
SELECT
    source_client_id,
    COUNT(*) AS source_rows,
    MIN(monthly_spend_usd) AS min_monthly_spend,
    MAX(monthly_spend_usd) AS max_monthly_spend
FROM vw_client_churn_clean
GROUP BY source_client_id
HAVING COUNT(*) > 1
    OR MIN(monthly_spend_usd) <> MAX(monthly_spend_usd);

-- END OF PHASE 1 SQL SCRIPT
