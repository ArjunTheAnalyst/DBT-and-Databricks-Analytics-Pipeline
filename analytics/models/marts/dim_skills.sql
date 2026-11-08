WITH skill_categories AS
(SELECT
    *
FROM
    {{ ref('skill_categories') }}),

observations AS
(SELECT
    *
FROM
    {{ ref('int_skill_observations') }})

SELECT
    skill_categories.skill_id,
    skill_categories.display_name,
    skill_categories.category,
    skill_categories.subcategory,
    COALESCE(observations.total_postings, 0) AS total_postings
FROM
    skill_categories
LEFT JOIN
    observations
ON
    skill_categories.skill_id = observations.skill_id;