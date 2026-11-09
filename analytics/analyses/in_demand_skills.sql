WITH job_postings AS
(SELECT
    job_id
FROM
    {{ ref('fact_job_postings') }}

-- Filters data only if 'job_title' var is provided; otherwise, returns unfiltered data.
WHERE
    {% if var('job_title', none) %}
    search_term LIKE '{{ var("job_title") }}'
    {% endif %}),

bridge AS
(SELECT
    *
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
    COUNT(DISTINCT job_postings.job_id) AS demand_count,
    ROUND(COUNT(DISTINCT job_postings.job_id) / (SELECT COUNT(DISTINCT job_postings.job_id) FROM job_postings) * 100, 1) AS demand_percentage
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
ORDER BY
    demand_percentage DESC;