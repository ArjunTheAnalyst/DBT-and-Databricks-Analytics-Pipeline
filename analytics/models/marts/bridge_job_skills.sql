WITH job_skills AS
(SELECT
    *
FROM
    {{ ref('staging_job_skills') }}),

job_postings AS
(SELECT
    *
FROM
    {{ ref('fact_job_postings') }})

SELECT
    job_skills.job_id,
    job_skills.skill_id,
    job_skills.skill_keyword
FROM
    job_skills
INNER JOIN
    job_postings
ON
    job_skills.job_id = job_postings.job_id;