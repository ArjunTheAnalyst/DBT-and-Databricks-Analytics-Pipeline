-- Job Postings with the Largest Salary Swings

SELECT
    job_title,
    company_name,
    MIN(salary_max) AS lowest_posted,
    MAX(salary_max) AS highest_posted,
    MAX(salary_max) - MIN(salary_max) AS salary_swing
FROM
    {{ ref('job_postings_snapshot') }}
WHERE
    salary_currency LIKE 'USD'
GROUP BY
    job_id,
    job_title,
    company_name
ORDER BY
    salary_swing DESC
LIMIT 10;

/*
┌────────────────────────────────────────┬─────────────────────────────┬───────────────┬────────────────┬──────────────┐
│ job_title                              ┆ company_name                ┆ lowest_posted ┆ highest_posted ┆ salary_swing │
╞════════════════════════════════════════╪═════════════════════════════╪═══════════════╪════════════════╪══════════════╡
│ PMO Analyst/Associate                  ┆ Leading Edge                ┆ 60000.00      ┆ 1000000.00     ┆ 940000.00    │
│ Decision Sciences Analyst              ┆ Kobie Marketing, Inc        ┆ 110000.00     ┆ 1000000.00     ┆ 890000.00    │
│ Senior Work Force Management Analyst   ┆ Abu Dhabi Islamic Bank PJSC ┆ 120000.00     ┆ 1000000.00     ┆ 880000.00    │
│ Data Analyst (Local only, 100  onsite) ┆ Ledgent Technology          ┆ 150000.00     ┆ 1000000.00     ┆ 850000.00    │
│ Linux System Engineer                  ┆ Canonical                   ┆ 180000.00     ┆ 1000000.00     ┆ 820000.00    │
│ Technical Lead I, Data Engineering     ┆ KPMG                        ┆ 120000.00     ┆ 700000.00      ┆ 580000.00    │
│ Technical Lead I, Data Engineering     ┆ KPMG                        ┆ 150000.00     ┆ 700000.00      ┆ 550000.00    │
│ Technical Lead I, Data Engineering     ┆ KPMG                        ┆ 150000.00     ┆ 700000.00      ┆ 550000.00    │
│ Technical Lead I, Data Engineering     ┆ KPMG                        ┆ 150000.00     ┆ 700000.00      ┆ 550000.00    │
└────────────────────────────────────────┴─────────────────────────────┴───────────────┴────────────────┴──────────────┘
*/