{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'job_id'
    )
}}

WITH job_postings AS
(SELECT
    *
FROM
    {{ ref('staging_job_postings') }}),

deduplicated AS
(SELECT
    job_id,
    job_title,
    search_term,
    company_name,
    job_location,
    source_platform,
    job_schedule_type,
    job_work_from_home,
    search_date,
    salary_min,
    salary_max,
    salary_avg,
    salary_period,
    salary_currency,
    has_health_insurance,
    has_dental_insurance,
    has_paid_time_off,
    has_no_degree_mentioned,
    ROW_NUMBER() OVER(PARTITION BY job_id ORDER BY searched_at DESC) AS RN
FROM
    job_postings)

SELECT
    job_id,
    job_title,
    search_term,
    company_name,
    job_location,
    source_platform,
    job_schedule_type,
    job_work_from_home,
    search_date,
    salary_min,
    salary_max,
    salary_avg,
    salary_period,
    salary_currency,
    has_health_insurance,
    has_dental_insurance,
    has_paid_time_off,
    has_no_degree_mentioned
FROM
    deduplicated
WHERE
-- To satisfy the unique test, we are only keeping the most recent job so older values 
-- at a later 'searched_at' date that have the same 'job_id' are going to get filtered out
    RN = 1

-- is_incremental() adds a filter to only process rows newer than the max search_date in the existing table
{% if is_incremental() %}
AND search_date > (SELECT MAX(search_date) FROM {{ this }})
{% endif %};