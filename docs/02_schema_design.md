# Phase 1: LinkedIn Data Dictionary

## Table: cities
* **Primary Key:** `city_id`
* **Description:** Stores unique geographic city locations and their corresponding states. Used to normalize location data across members, companies, and jobs.

## Table: skills
* **Primary Key:** `skill_id`
* **Description:** A master lookup table of all professional skills. Ensures consistency so users and jobs reference the exact same skill names without spelling variations.

## Table: companies
* **Primary Key:** `company_id`
* **Description:** Stores data for organizations on the platform, including their industry, size, headquarters location, and founding details.

## Table: members
* **Primary Key:** `member_id`
* **Description:** The core user table. Stores personal information, authentication context (email), account tier (is_premium), and current job-seeking status.

## Table: positions
* **Primary Key:** `position_id`
* **Description:** Represents a member's employment history. Links a `member_id` to a `company_id` with specific dates, job titles, and employment types.

## Table: member_skills
* **Primary Key:** `member_id, skill_id`
* **Description:** A junction table mapping members to their skills. Includes an `endorsements` counter to track peer validation of the skill.

## Table: connections
* **Primary Key:** `member_a, member_b`
* **Description:** Stores established, accepted connections between two members. Enforces `member_a < member_b` to ensure relationships are only stored once regardless of who initiated.

## Table: invitations
* **Primary Key:** `invitation_id`
* **Description:** Tracks the lifecycle of connection requests from one member to another, including the optional note and timestamp tracking from 'PENDING' to 'ACCEPTED' or 'IGNORED'.

## Table: jobs
* **Primary Key:** `job_id`
* **Description:** Stores job postings created by companies, detailing the role, workplace type (remote/on-site), experience requirements, salary ranges, and posting timelines.

## Table: job_skills
* **Primary Key:** `job_id, skill_id`
* **Description:** A junction table defining the specific skills required for a given job posting. 

## Table: applications
* **Primary Key:** `application_id`
* **Description:** Tracks members applying to jobs. Records the timestamp, whether it was an easy apply, and the current status of the application pipeline.

## Table: profile_views
* **Primary Key:** `view_id`
* **Description:** An analytical table tracking when one member views another member's profile. Allows `viewer_id` to be null for anonymous/private mode browsing.
