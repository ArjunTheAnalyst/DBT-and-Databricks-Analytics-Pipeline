{% set extension_keywords = ['No degree mentioned', 'Paid time off', 'Dental insurance', 'Health insurance'] -%}

WITH source AS
(SELECT
    *
FROM
    {{ source('jobs', 'raw_job_postings') }}
WHERE
    error IS NULL
AND
    job_id IS NOT NULL),

parsed AS
(SELECT
    *,
     -- Parse the raw JSON text into a Spark array of strings only once
    FROM_JSON(job_extensions_raw, 'ARRAY<STRING>') AS job_extensions
FROM
    source),

cleaned AS
(SELECT
    job_id,
    job_title,
    TRIM(company_name) AS company_name,
    job_location,
    REGEXP_REPLACE(job_via, '^via ', '') AS source_platform,
    job_posted_at,
    job_salary,

    -- Clean the 'job_salary' column
    -- 1. LOWER BOUND OF THE SALARY RANGE
    {{ parse_salary('min') }} AS salary_min,

    -- 2. UPPER BOUND OF THE SALARY RANGE
    {{ parse_salary('max') }} AS salary_max,

    ({{ parse_salary('min') }} + {{ parse_salary('max') }}) / 2 AS salary_avg,

    -- 3. SALARY PERIOD
    NULLIF(
    REGEXP_EXTRACT(job_salary, 'an? (year|month|week|day|hour)', 1), 
    '') AS salary_period,

    -- 4. SALARY CURRENCY
    COALESCE(
    NULLIF(
    TRIM(
    REGEXP_EXTRACT(job_salary, '^([^0-9]+)', 1)),
    ''), 'USD') AS salary_currency,

    job_schedule_type,
    job_work_from_home,
    -- job_extensions_raw,
    search_time AS searched_at,
    search_date,
    search_term,
    search_location,
    {% for keyword in extension_keywords -%}
    
    ARRAY_CONTAINS(
    -- Converts the raw JSON text into a structured Spark array of strings
        -- FROM_JSON(job_extensions_raw, 'ARRAY<STRING>'),
        job_extensions,
    '{{ keyword }}') AS has_{{ clean_text(keyword) }}
    {{ ',' if not loop.last else ''}}
    {%- endfor -%}
FROM
    parsed)

SELECT
    *
FROM
    cleaned;