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