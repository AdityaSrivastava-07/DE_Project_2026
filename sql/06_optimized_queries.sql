-- =====================================================================
-- Phase 4: Optimized Query Rewrites (Sargability & Anti-Join Fixes)
-- =====================================================================
SET search_path TO linkedin;

-- @R13 Optimized: Replace NOT IN (nullable column) with NOT EXISTS Anti-Join
SELECT m.member_id, m.first_name, m.last_name
FROM members m
WHERE NOT EXISTS (
    SELECT 1 FROM profile_views v WHERE v.viewer_id = m.member_id
);

-- @R15 Optimized: Replace non-sargable EXTRACT(YEAR) with range predicate
SELECT s.skill_name, count(*) AS jobs
FROM job_skills js
JOIN skills s ON s.skill_id = js.skill_id
JOIN jobs j   ON j.job_id = js.job_id
WHERE j.posted_at >= '2026-01-01' AND j.posted_at < '2027-01-01'
GROUP BY s.skill_name
ORDER BY jobs DESC
LIMIT 20;

-- @R19 Optimized: Replace correlated subqueries with pre-aggregated CTEs
WITH open_job_counts AS (
    SELECT company_id, count(*) AS open_jobs
    FROM jobs
    WHERE status = 'OPEN'
    GROUP BY company_id
),
june_app_counts AS (
    SELECT j.company_id, count(*) AS june_applications
    FROM applications a
    JOIN jobs j ON j.job_id = a.job_id
    WHERE a.applied_at >= '2026-06-01'
    GROUP BY j.company_id
)
SELECT c.company_id, c.company_name,
       coalesce(oj.open_jobs, 0) AS open_jobs,
       coalesce(ja.june_applications, 0) AS june_applications
FROM companies c
LEFT JOIN open_job_counts oj ON oj.company_id = c.company_id
LEFT JOIN june_app_counts ja ON ja.company_id = c.company_id
WHERE c.industry = 'IT Services'
ORDER BY june_applications DESC;

-- @R20 Optimized: Replace non-sargable ::date cast with range predicate
SELECT day, apps, sum(apps) OVER (ORDER BY day) AS running_total
FROM (
    SELECT applied_at::date AS day, count(*) AS apps
    FROM applications
    WHERE applied_at >= '2026-06-01' AND applied_at < '2026-07-01'
    GROUP BY 1
) d
ORDER BY day;

-- @R21 Optimized: Replace full-table ROW_NUMBER() with LATERAL top-1 index lookup
SELECT s.skill_name, top_m.member_id, top_m.endorsements
FROM skills s
CROSS JOIN LATERAL (
    SELECT ms.member_id, ms.endorsements
    FROM member_skills ms
    WHERE ms.skill_id = s.skill_id
    ORDER BY ms.endorsements DESC, ms.member_id ASC
    LIMIT 1
) top_m
ORDER BY top_m.endorsements DESC;

-- @R22 Optimized: Keyset pagination instead of deep OFFSET 100000
SELECT application_id, job_id, member_id, status, applied_at
FROM applications
WHERE applied_at < '2026-06-15 00:00:00+05:30'
ORDER BY applied_at DESC
LIMIT 25;
