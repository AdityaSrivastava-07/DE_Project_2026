-- =====================================================================
-- Phase 4: Strategic Indexes for LinkedIn Workload
-- =====================================================================
SET search_path TO linkedin;

-- Enable pg_trgm for fast ILIKE '%...%' text search (R06)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Members (R18, R23)
CREATE INDEX IF NOT EXISTS idx_members_lower_email ON members (lower(email));
CREATE INDEX IF NOT EXISTS idx_members_city_open ON members (city_id) WHERE open_to_work = TRUE;

-- 2. Companies (R19)
CREATE INDEX IF NOT EXISTS idx_companies_industry ON companies (industry);

-- 3. Positions (R01, R02, R12, R17, R25)
CREATE INDEX IF NOT EXISTS idx_positions_member_start ON positions (member_id, start_date DESC);
CREATE INDEX IF NOT EXISTS idx_positions_member_current ON positions (member_id) WHERE end_date IS NULL;
CREATE INDEX IF NOT EXISTS idx_positions_company_current ON positions (company_id) WHERE end_date IS NULL;

-- 4. Connections (R03, R04, R05)
CREATE INDEX IF NOT EXISTS idx_connections_member_b ON connections (member_b, member_a);

-- 5. Jobs (R06, R07, R15, R16, R19, W04)
CREATE INDEX IF NOT EXISTS idx_jobs_company_status ON jobs (company_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_at ON jobs (posted_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_open_closes ON jobs (closes_at) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_jobs_title_trgm ON jobs USING gin (title gin_trgm_ops);

-- 6. Skills & Junction Tables (R07, R15, R18, R21)
CREATE INDEX IF NOT EXISTS idx_skills_name ON skills (skill_name);
CREATE INDEX IF NOT EXISTS idx_job_skills_skill_job ON job_skills (skill_id, job_id);
CREATE INDEX IF NOT EXISTS idx_member_skills_skill_endorsements ON member_skills (skill_id, endorsements DESC, member_id);

-- 7. Applications (R09, R14, R19, R20, R22, W05)
CREATE INDEX IF NOT EXISTS idx_applications_member_applied ON applications (member_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at ON applications (applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_hired_updated ON applications (status_updated_at) WHERE status = 'HIRED';
CREATE INDEX IF NOT EXISTS idx_applications_job_applied ON applications (job_id, applied_at) WHERE status = 'APPLIED';

-- 8. Invitations (R10, R24, W02, W03)
CREATE INDEX IF NOT EXISTS idx_invitations_recipient_pending ON invitations (recipient_id, sent_at DESC) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_invitations_sent_at ON invitations (sent_at);

-- 9. Profile Views (R11, R13)
CREATE INDEX IF NOT EXISTS idx_profile_views_viewed_at ON profile_views (viewed_id, viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_profile_views_viewer ON profile_views (viewer_id) WHERE viewer_id IS NOT NULL;

ANALYZE;
