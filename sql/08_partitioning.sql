-- =====================================================================
-- Phase 5: Declarative Range Partitioning for High-Volume Tables
-- Targets: applications (4.25M rows) & profile_views (4.40M rows)
-- =====================================================================
SET search_path TO linkedin;

-- 1. Range-Partitioned Applications Table (Monthly partitions for 2026)
-- Accelerates time-bounded queries (R06, R14, R19, R20, R22, W05) via Partition Pruning
CREATE TABLE IF NOT EXISTS applications_partitioned (
    LIKE linkedin.applications INCLUDING DEFAULTS
) PARTITION BY RANGE (applied_at);

ALTER TABLE applications_partitioned
    ADD PRIMARY KEY (application_id, applied_at);

CREATE TABLE IF NOT EXISTS applications_y2025
    PARTITION OF applications_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS applications_y2026_q1
    PARTITION OF applications_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS applications_y2026_q2
    PARTITION OF applications_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS applications_y2026_h2
    PARTITION OF applications_partitioned
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS applications_default
    PARTITION OF applications_partitioned DEFAULT;

-- Partition-local indexes (automatically propagated to all child partitions)
CREATE INDEX IF NOT EXISTS idx_part_apps_member_applied
    ON applications_partitioned (member_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_part_apps_job_status
    ON applications_partitioned (job_id, status);

-- Migrate data from unpartitioned table
INSERT INTO applications_partitioned
SELECT * FROM linkedin.applications
ON CONFLICT DO NOTHING;

ANALYZE applications_partitioned;

-- 2. Range-Partitioned Profile Views Table (Quarterly partitions)
-- Accelerates R11 ("Who viewed your profile since April 2026") via Partition Pruning
CREATE TABLE IF NOT EXISTS profile_views_partitioned (
    LIKE linkedin.profile_views INCLUDING DEFAULTS
) PARTITION BY RANGE (viewed_at);

ALTER TABLE profile_views_partitioned
    ADD PRIMARY KEY (view_id, viewed_at);

CREATE TABLE IF NOT EXISTS profile_views_y2025
    PARTITION OF profile_views_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS profile_views_y2026_q1
    PARTITION OF profile_views_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS profile_views_y2026_q2
    PARTITION OF profile_views_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS profile_views_default
    PARTITION OF profile_views_partitioned DEFAULT;

CREATE INDEX IF NOT EXISTS idx_part_pv_viewed_at
    ON profile_views_partitioned (viewed_id, viewed_at DESC);

INSERT INTO profile_views_partitioned
SELECT * FROM linkedin.profile_views
ON CONFLICT DO NOTHING;

ANALYZE profile_views_partitioned;

-- 3. Verify Partition Pruning (Only scans applications_y2026_q2)
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM applications_partitioned
WHERE applied_at >= '2026-06-01' AND applied_at < '2026-07-01';
