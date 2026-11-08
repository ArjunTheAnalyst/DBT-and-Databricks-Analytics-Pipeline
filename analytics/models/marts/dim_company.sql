WITH job_postings AS
(SELECT
    *
FROM
    {{ ref('fact_job_postings') }})

SELECT
    company_name,
    COUNT(*) AS total_job_postings,
    AVG(CASE WHEN salary_currency LIKE 'USD' AND salary_period LIKE 'year'
    THEN salary_avg END) AS salary_year_avg 
FROM
    job_postings
WHERE
    company_name IS NOT NULL
GROUP BY
    company_name;