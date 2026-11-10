-- BACKFILL: Compresses a year's worth of `dbt snapshot` runs into one query.

CREATE OR REPLACE TABLE dev.snapshots.job_postings_snapshot AS

WITH deduplicated AS
(SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY job_id, search_date ORDER BY searched_at DESC) AS RN
FROM
    dev.staging.staging_job_postings),

-- STEP 1: Keep only latest scrape for a job on any given day to avoid duplicate daily rows
latest_daily_scrape AS
(SELECT
    * EXCEPT(RN)
FROM
    deduplicated
WHERE
    RN = 1),

-- STEP 2: Create a unique fingerprint for each row of the 13 watched columns
row_fingerprints AS
(SELECT
    *,
    MD5(
    CONCAT_WS('||',
        -- For 'NULL' values, replace with '~' to prevent strings from breaking
        COALESCE(job_title, '~'),
        COALESCE(company_name, '~'),
        COALESCE(job_location, '~'),
        COALESCE(job_schedule_type, '~'),
        COALESCE(CAST(job_work_from_home AS STRING), '~'),
        COALESCE(CAST(salary_min AS STRING), '~'),
        COALESCE(CAST(salary_max AS STRING), '~'),
        COALESCE(salary_period, '~'),
        COALESCE(salary_currency, '~'),
        COALESCE(CAST(has_health_insurance AS STRING), '~'),
        COALESCE(CAST(has_dental_insurance AS STRING), '~'),
        COALESCE(CAST(has_paid_time_off AS STRING), '~'),
        COALESCE(CAST(has_no_degree_mentioned AS STRING), '~')
        )
    ) AS row_hash
FROM
    latest_daily_scrape),

-- STEP 3: Find the previous day's fingerprint for each job for the purposes of comparison
compared_to_previous AS
(SELECT
    *,
    LAG(row_hash) OVER(PARTITION BY job_id ORDER BY searched_at) AS previous_row_hash
FROM
    row_fingerprints),

-- STEP 4: Keep only first time (NULL) or changed rows
changed_versions AS
(SELECT
    *
FROM
    compared_to_previous
WHERE
    previous_row_hash IS NULL
OR
    row_hash <> previous_row_hash)

-- STEP 5: Format output as per the requirements
SELECT
    * EXCEPT(row_hash, previous_row_hash),
    MD5(CONCAT_WS('|', job_id, CAST(searched_at AS STRING))) AS dbt_scd_id, -- scd: slowly changing dimensions
    searched_at AS dbt_updated_at, -- exact timestamp of the change
    searched_at AS dbt_valid_from, -- when this version became active

    -- Looks ahead to the next change to close out the old version. 
    -- Returns NULL if this is the current active version.
    LEAD(searched_at) OVER(PARTITION BY job_id ORDER BY searched_at) AS dbt_valid_to
FROM
    changed_versions;