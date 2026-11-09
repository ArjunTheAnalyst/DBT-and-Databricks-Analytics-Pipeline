-- Singular Test: Warns if any USD annual salaries are unusually high (>= $1M)
{{ config(severity = 'warn') }}

SELECT
    job_id,
    search_term,
    job_title,
    salary_min,
    salary_max,
    salary_period,
    salary_currency
FROM
    {{ ref('staging_job_postings') }}
WHERE
    salary_period LIKE 'year'
AND
    (
        salary_min >= 1000000
    OR
        salary_max >= 1000000
    )
AND
    salary_currency LIKE 'USD'