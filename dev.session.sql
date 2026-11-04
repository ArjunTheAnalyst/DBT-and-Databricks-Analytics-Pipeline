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