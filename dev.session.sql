DESCRIBE raw.jobs.raw_job_postings;

-- Row Count for staging_job_postings
SELECT
    'staging_job_postings' AS table_name,
    COUNT(*) AS row_count
FROM
    dev.default_staging.staging_job_postings

UNION ALL

-- Row Count for staging_job_skills
SELECT
    'staging_job_skills' AS table_name,
    COUNT(*) AS row_count
FROM
    dev.default_staging.staging_job_skills;

-- Verify column descriptions for the staging_job_postings table
SELECT
    column_name,
    comment
FROM
    dev.information_schema.columns
WHERE
    table_name LIKE 'staging_job_postings';

-- Drop the staging schema and all its tables/views
DROP SCHEMA dev.default_staging CASCADE;

-- Clean the 'job_salary' column
SELECT
    job_salary,
    
    -- 1. LOWER BOUND OF THE SALARY RANGE
    TRY_CAST(
    REPLACE(
    REGEXP_EXTRACT(
    SPLIT(job_salary, '–')[0], '([0-9][0-9,.]*)', 1), -- '–' en-dash
    ',', '') AS DECIMAL(15, 2))

    *

    CASE UPPER(
    REGEXP_EXTRACT(
    SPLIT(job_salary, '–')[0], '[0-9][0-9,.]*([KkMm])', 1))
    WHEN 'K' THEN 1000
    WHEN 'M' THEN 1000000
    ELSE 1
    END AS salary_min,

    -- UPPER BOUND OF THE SALARY RANGE
    TRY_CAST(
    REPLACE(
    REGEXP_EXTRACT(    
    ELEMENT_AT(SPLIT(job_salary, '–'), -1), '([0-9][0-9,.]*)', 1),
    ',', '') AS DECIMAL(15, 2))

    *

    CASE UPPER(
    REGEXP_EXTRACT(
    ELEMENT_AT(SPLIT(job_salary, '–'), -1), '[0-9][0-9,.]*([KkMm])', 1))
    WHEN 'K' THEN 1000
    WHEN 'M' THEN 1000000
    ELSE 1
    END AS salary_max,

    -- 3. SALARY PERIOD
    NULLIF(
    REGEXP_EXTRACT(job_salary, 'an? (year|month|week|day|hour)', 1), 
    '') AS salary_period,

    -- 4. SALARY CURRENCY
    COALESCE(
    NULLIF(
    TRIM(
    REGEXP_EXTRACT(job_salary, '^([^0-9]+)', 1)),
    ''), 'USD') AS salary_currency
FROM
    dev.staging.staging_job_postings;

-- Verify the cleansed salary values
SELECT
    job_salary,
    salary_min,
    salary_max,
    salary_avg,
    salary_period,
    salary_currency
FROM
    dev.staging.staging_job_postings
WHERE
    job_salary IS NOT NULL;

-- Verify 'int_skill_observations' row count
SELECT
    COUNT(*)
FROM
    dev.intermediate.int_skill_observations;

-- Verify 'fact_job_postings' row count
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT job_id) AS distinct_job_cnt
FROM
    dev.marts.fact_job_postings;

-- Drop 'seeds' table from default schema
DROP TABLE IF EXISTS dev.default.skill_categories;

-- EDA: Identify abnormally high annual salaries (>= $1M USD)
SELECT
    job_id,
    search_term,
    job_title,
    salary_min,
    salary_max,
    salary_period,
    salary_currency
FROM
    dev.staging.staging_job_postings
WHERE
    salary_period LIKE 'year'
AND
    (
        salary_min >= 1000000
    OR
        salary_max >= 1000000
    )
AND
    salary_currency LIKE 'USD';

-- Find the minimum 'searched_at' date to establish the backfill baseline
SELECT
    searched_at
FROM
    dev.staging.staging_job_postings
ORDER BY
    searched_at;

-- Inspect historical job versions that have since been updated
SELECT
    job_id,
    job_title,
    salary_min,
    salary_max,
    dbt_valid_from,
    dbt_valid_to
FROM
    dev.snapshots.job_postings_snapshot
WHERE
    dbt_valid_to IS NOT NULL;

-- Verify specific job history after the July 1–4, 2025 snapshot runs
SELECT
    *
FROM
    dev.snapshots.job_postings_snapshot
WHERE
    job_id = '11ea4e57e124886fa823d8281d684a9a';


-- Identify which companies have the most frequently updated job postings
SELECT
    company_name,
    COUNT(DISTINCT job_id) AS jobs_changed
FROM
    dev.snapshots.job_postings_snapshot
WHERE
    dbt_valid_to IS NOT NULL
GROUP BY
    company_name
ORDER BY
    jobs_changed DESC;

-- Identify updated/expired jobs
SELECT
    *
FROM
    dev.snapshots.job_postings_snapshot
WHERE
    dbt_valid_to IS NOT NULL;


-- Verify 'job_postings_snapshot' row count
SELECT
    COUNT(*)
FROM
    dev.snapshots.job_postings_snapshot;

-- Track rows updated vs. inserted across recent MERGE operations
SELECT
    operation,
    operationMetrics['numOutputRows'] AS rows_written,
    operationMetrics['numSourceRows'] AS rows_merged_in,
    operationMetrics['numTargetRowsUpdated'] rows_updated,
    operationMetrics['numTargetRowsInserted'] rows_inserted
FROM
    (DESCRIBE HISTORY dev.marts.fact_job_postings)
WHERE
    operation IN ('CREATE OR REPLACE TABLE AS SELECT', 'MERGE')
ORDER BY
    version DESC;

-- Simulate an incremental update by deleting the latest date's rows
DELETE FROM dev.marts.fact_job_postings
WHERE search_date = '2026-06-30';

-- Note: Run `dbt run --full-refresh --select fact_job_postings` 
-- to rebuild this table from scratch, bypassing the incremental logic.