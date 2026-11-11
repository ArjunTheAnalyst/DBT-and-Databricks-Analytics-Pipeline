WITH job_postings AS
(SELECT
    job_id,
    salary_avg
FROM
    {{ ref('fact_job_postings') }}

-- Rationale for using WHERE instead of CASE:
-- In this query, we are only interested in the top skills by salary. 
-- Filtering the fact table down to strictly USD/yearly salaries using a WHERE clause 
-- is exactly what we want here. There is no denominator to protect (like demand_percentage), 
-- so filtering out non-USD jobs early reduces the data size and speeds up the joins.
WHERE
    salary_currency LIKE 'USD' 
AND 
    salary_period LIKE 'year'
AND
    salary_avg IS NOT NULL),

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
    bridge.skill_id,
    skills.display_name,
    skills.category,
    ROUND(AVG(job_postings.salary_avg), 0) AS salary_year_avg,
    COUNT(*) AS salaried_postings
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
    bridge.skill_id,
    skills.display_name,
    skills.category
ORDER BY
    salary_year_avg DESC;