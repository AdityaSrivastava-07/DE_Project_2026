CREATE SCHEMA linkedin;
SET search_path TO linkedin;

CREATE TABLE cities (
    city_id INT PRIMARY KEY,
    city_name TEXT NOT NULL,
    state TEXT NOT NULL
);

CREATE TABLE skills (
    skill_id INT PRIMARY KEY,
    skill_name TEXT UNIQUE NOT NULL
);

CREATE TABLE companies (
    company_id INT PRIMARY KEY,
    company_name TEXT UNIQUE NOT NULL,
    industry TEXT NOT NULL,
    company_size TEXT NOT NULL,
    hq_city_id INT REFERENCES cities(city_id) ON DELETE SET NULL,
    founded_year INT,
    website TEXT
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    headline TEXT,
    email TEXT UNIQUE NOT NULL,
    city_id INT REFERENCES cities(city_id) ON DELETE SET NULL,
    industry TEXT,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    open_to_work BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE positions (
    position_id INT PRIMARY KEY,
    member_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    company_id INT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    employment_type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    CONSTRAINT chk_positions_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE member_skills (
    member_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    skill_id INT NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
    endorsements INT NOT NULL DEFAULT 0,
    PRIMARY KEY (member_id, skill_id),
    CONSTRAINT chk_endorsements_non_negative CHECK (endorsements >= 0)
);

CREATE TABLE connections (
    member_a INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    member_b INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    connected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (member_a, member_b),
    CONSTRAINT chk_connection_order CHECK (member_a < member_b)
);

CREATE TABLE invitations (
    invitation_id INT PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    recipient_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    note TEXT,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL,
    responded_at TIMESTAMPTZ,
    CONSTRAINT chk_invitation_no_self CHECK (sender_id <> recipient_id),
    CONSTRAINT chk_invitation_status CHECK (status IN ('PENDING', 'ACCEPTED', 'IGNORED', 'WITHDRAWN')),
    CONSTRAINT chk_invitation_timeline CHECK (responded_at IS NULL OR responded_at >= sent_at),
    CONSTRAINT chk_invitation_pending_null CHECK ((status = 'PENDING' AND responded_at IS NULL) OR (status <> 'PENDING' AND responded_at IS NOT NULL))
);

CREATE TABLE jobs (
    job_id INT PRIMARY KEY,
    company_id INT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    city_id INT REFERENCES cities(city_id) ON DELETE SET NULL,
    workplace_type TEXT NOT NULL,
    employment_type TEXT NOT NULL,
    min_experience INT,
    min_salary_lpa NUMERIC(10, 2),
    max_salary_lpa NUMERIC(10, 2),
    posted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closes_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL,
    CONSTRAINT chk_job_status CHECK (status IN ('OPEN', 'CLOSED')),
    CONSTRAINT chk_job_dates CHECK (closes_at > posted_at),
    CONSTRAINT chk_job_salary CHECK (max_salary_lpa IS NULL OR min_salary_lpa IS NULL OR max_salary_lpa >= min_salary_lpa),
    CONSTRAINT chk_job_experience CHECK (min_experience IS NULL OR min_experience >= 0),
    CONSTRAINT chk_job_remote_city CHECK ((workplace_type = 'REMOTE' AND city_id IS NULL) OR (workplace_type <> 'REMOTE' AND city_id IS NOT NULL))
);

CREATE TABLE job_skills (
    job_id INT NOT NULL REFERENCES jobs(job_id) ON DELETE CASCADE,
    skill_id INT NOT NULL REFERENCES skills(skill_id) ON DELETE CASCADE,
    PRIMARY KEY (job_id, skill_id)
);

CREATE TABLE applications (
    application_id INT PRIMARY KEY,
    job_id INT NOT NULL REFERENCES jobs(job_id) ON DELETE CASCADE,
    member_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    easy_apply BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL,
    status_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_job_application UNIQUE (job_id, member_id),
    CONSTRAINT chk_app_status CHECK (status IN ('APPLIED', 'VIEWED', 'SHORTLISTED', 'INTERVIEW', 'OFFER', 'HIRED', 'REJECTED', 'WITHDRAWN')),
    CONSTRAINT chk_app_timeline CHECK (status_updated_at >= applied_at)
);

CREATE TABLE profile_views (
    view_id INT PRIMARY KEY,
    viewer_id INT REFERENCES members(member_id) ON DELETE SET NULL,
    viewed_id INT NOT NULL REFERENCES members(member_id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_no_self_view CHECK (viewer_id IS NULL OR viewer_id <> viewed_id)
);
