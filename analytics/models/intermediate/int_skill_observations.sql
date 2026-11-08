WITH job_skills AS
(SELECT
    *
FROM
    {{ ref('staging_job_skills') }})

SELECT
    skill_id,
    COUNT(DISTINCT job_id) AS total_postings
FROM
    job_skills
GROUP BY
    skill_id;