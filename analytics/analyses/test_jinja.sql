/* 
The analyses/ folder is for exploratory queries. 
It is compiled via `dbt compile` and previewed via `dbt show`; 
however, it is absolutely ignored by `dbt build` and `dbt run`
*/

SELECT
    COUNT(*) AS postings
FROM
    {{ ref('staging_job_postings') }};
-- Run `dbt compile`, then check target/compiled/analytics/analyses/ to see the pure SQL translation.
-- To view the result, run: dbt show --inline "SELECT QUERY (Remove semicolon at the end of the query if you want to run it in dbt show)"


-- Below is a Jinja Statement tag, used for loops, logic, and variable assignment.
-- '-' removes whitespace from the end of the line.
{% set roles = ['data analyst', 'data engineer', 'data scientist'] -%}

{% for role in roles -%}
SELECT
    search_term,
    COUNT(*) AS postings
FROM
    {{ ref('staging_job_postings') }}
WHERE
    search_term = '{{ role | title}}'
GROUP BY
    search_term;
{{ 'UNION ALL' if not loop.last else '' }}; -- if this is not the last item
{%- endfor %}
-- To view the result, run: dbt show --inline "SELECT QUERY (Remove semicolon at the end of the query if you want to run it in dbt show)"


-- Below is a Jinja filter that will convert the string to uppercase and replace spaces with underscores.
SELECT '{{ "data analyst" | upper | replace(" ", "_") }}' AS formatted_string;


-- Conditional Statements
{% set number = 3 -%}
{{ 'number is even' if number % 2 == 0 else 'number is odd' }}