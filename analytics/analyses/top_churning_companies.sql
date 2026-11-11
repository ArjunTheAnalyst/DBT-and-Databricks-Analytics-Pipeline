-- Identify companies with the highest job posting churn (closed/updated roles)

SELECT
    company_name,
    COUNT(DISTINCT job_id) AS unique_jobs_changed
FROM
    {{ ref('job_postings_snapshot') }}
WHERE
    dbt_valid_to IS NOT NULL
GROUP BY
    company_name
ORDER BY
    unique_jobs_changed DESC
LIMIT 10;

/*
┌───────────────────────┬─────────────────────┐
│ company_name          ┆ unique_jobs_changed │
╞═══════════════════════╪═════════════════════╡
│ Meta                  ┆ 415                 │
│ Capital One           ┆ 387                 │
│ The Hertz Corporation ┆ 228                 │
│ SynergisticIT         ┆ 157                 │
│ PwC                   ┆ 144                 │
│ EY                    ┆ 139                 │
│ beBeeData             ┆ 137                 │
│ Canonical             ┆ 110                 │
│ Walmart               ┆ 108                 │
│ Jobs via Dice         ┆ 100                 │
└───────────────────────┴─────────────────────┘
*/