WITH job_postings AS
(SELECT
    job_id,
    CASE
        WHEN salary_currency LIKE 'USD' AND salary_period LIKE 'year'
        THEN salary_avg
    ELSE NULL
    END AS salary_year_usd

-- Rationale for using CASE instead of WHERE:
-- The demand_percentage calculation will require the denominator to include ALL jobs. 
-- Using a WHERE clause would filter the CTE down to only USD/yearly jobs, 
-- shrinking the denominator and inflating the percentage. 
-- The CASE statement keeps all jobs in the CTE (for accurate counting) but 
-- only assigns a salary value to USD/yearly jobs, keeping the AVG() clean.
FROM
    {{ ref('fact_job_postings') }}),

bridge AS
(SELECT DISTINCT
    job_id,
    skill_id

-- Deduplication is required here. 
-- Duplicates occur because a job posting can mention the same skill in different formats 
-- (e.g., "SQL" and "sql"), which map to the same skill_id. 
-- Because we will be calculating an AVG(), these duplicate bridge rows would join to the
-- fact table multiple times, duplicating the salary values and skewing the average.
FROM
    {{ ref('bridge_job_skills') }}),

skills AS
(SELECT
    *
FROM
    {{ ref('dim_skills') }})

SELECT
    skills.display_name,
    skills.category,
    COUNT(DISTINCT bridge.job_id) AS demand_count,
    ROUND(
    COUNT(DISTINCT bridge.job_id) / (SELECT COUNT(DISTINCT job_id) FROM job_postings) * 100, 1) AS demand_percentage,
    ROUND(AVG(salary_year_usd), 0) AS salary_year_avg
FROM
    job_postings
INNER JOIN
    bridge
ON
    job_postings.job_id = bridge.job_id
INNER JOIN
    skills
ON
    bridge.skill_id = skills.skill_id
GROUP BY
    skills.display_name,
    skills.category
HAVING
    COUNT(DISTINCT bridge.job_id) >= 100
-- AND
--     AVG(salary_year_usd) IS NOT NULL
ORDER BY
    salary_year_avg DESC,
    demand_count DESC;