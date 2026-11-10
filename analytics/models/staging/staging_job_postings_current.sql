{{ config(materialized = 'ephemeral') }}
-- ephemeral model: not built as a table/view here.
-- the physical table will be built in the snapshot schema, 
-- but the core query is still maintained here in the staging schema.

WITH deduplicated AS
(SELECT 
    *,
    ROW_NUMBER() OVER(PARTITION BY job_id ORDER BY searched_at DESC) AS RN
FROM
    {{ ref('staging_job_postings') }}
WHERE
    search_date <= CAST('{{ var('as_of', run_started_at) }}' AS DATE))

SELECT 
    * EXCEPT(RN)
FROM
    deduplicated
WHERE
    RN = 1

/*
To preview the output:
dbt show --select staging_job_postings_current --limit -1 --vars 'as_of: 2025-07-01'

To run the snapshot:
dbt snapshot --vars 'as_of: 2025-07-01'
dbt snapshot --vars 'as_of: 2025-07-02'
dbt snapshot --vars 'as_of: 2025-07-03'
dbt snapshot --vars 'as_of: 2025-07-04'
*/