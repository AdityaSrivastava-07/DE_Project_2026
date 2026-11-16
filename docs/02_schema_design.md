# Schema Design & Data Dictionary (`linkedin` Schema)

## 1. Schema Overview
- **Database Engine:** PostgreSQL 16
- **Target Schema:** `linkedin`
- **Design Goal:** Normalized relational schema supporting both transactional lookups (OLTP) and analytical aggregations (OLAP) across members, companies, job postings, skills, and job applications.

---

## 2. Data Dictionary

> *Note: Replicate the table block below for every table defined in `sql/01_schema.sql` (e.g., `members`, `companies`, `jobs`, `skills`, `member_skills`, `job_skills`, `applications`).*

### 2.1 `linkedin.<table_name>`
**Description:** `<Brief 1-sentence purpose of the entity/junction table>`

| Column Name | Data Type | Constraints | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `<pk_column>` | `SERIAL` / `INT` / `UUID` | `PRIMARY KEY` | `AUTO` | Unique identifier for each record |
| `<fk_column>` | `INT` | `NOT NULL`, `FOREIGN KEY` | `None` | References `linkedin.<parent_table>(<pk>)` |
| `<attribute_1>` | `VARCHAR(255)` | `NOT NULL`, `UNIQUE` | `None` | `<Business meaning of column>` |
| `<attribute_2>` | `NUMERIC(10,2)` | `CHECK (<col> >= 0)` | `0.00` | `<Business meaning of column>` |
| `created_at` | `TIMESTAMP` | `NOT NULL` | `CURRENT_TIMESTAMP` | Record creation timestamp |

---

## 3. Constraint Reasoning & Business Rules

Document the architectural justification behind every key and constraint enforced in `sql/01_schema.sql` (minimum 12 `CHECK`/`NOT NULL` constraints required across the schema).

### 3.1 Primary & Foreign Keys
- **Surrogate vs. Natural Keys:** `<Explain why integer/UUID surrogate keys were chosen over natural keys like email or company name, e.g., immutability and join performance.>`
- **Referential Integrity & Cascade Rules:**
  - `linkedin.<child_table>.<fk_col>` -> `linkedin.<parent_table>.<pk_col>`: `<Explain ON DELETE CASCADE vs. ON DELETE RESTRICT behavior and why it prevents orphaned records.>`
- **Composite Primary Keys (Junction Tables):**
  - `linkedin.member_skills (member_id, skill_id)`: `<Explain how a composite PK prevents duplicate skill assignments to the same member.>`

### 3.2 `CHECK` & `NOT NULL` Constraints Justification

| Constraint Name / Rule | Table.Column | Business & Data Integrity Reasoning |
| :--- | :--- | :--- |
| `NOT NULL` | `members.email` | Every member account requires a valid login/contact identifier. |
| `UNIQUE` | `members.email` | Prevents duplicate account registration for the same email address. |
| `CHECK (salary_max >= salary_min)` | `jobs.salary_max` | Ensures salary ranges are logically valid and prevents inverted pay bands. |
| `CHECK (status IN (...))` | `applications.status` | Restricts application states to valid pipeline stages (`applied`, `reviewing`, `interview`, `offered`, `rejected`). |
| `<Add remaining constraints...>` | `<Table.Column>` | `<Explain exact data anomaly prevented by this constraint>` |

---

## 4. Functional Dependencies & Normalization Proofs

### 4.1 Functional Dependencies (FDs)
List the non-trivial functional dependencies for each core relation:

- **`linkedin.members`**
  - `member_id -> full_name, email, headline, location, experience_years, created_at`
  - `email -> member_id` *(Candidate Key)*
- **`linkedin.companies`**
  - `company_id -> company_name, industry, company_size, headquarters, founded_year`
- **`linkedin.jobs`**
  - `job_id -> company_id, title, employment_type, location, salary_min, salary_max, posted_at`
- **`linkedin.applications`**
  - `application_id -> job_id, member_id, status, applied_at`
  - `(job_id, member_id) -> application_id, status, applied_at` *(If one application per member per job is enforced)*
- **`linkedin.member_skills` / `linkedin.job_skills`**
  - `(member_id, skill_id) -> proficiency_level` *(All-key relation if no non-key attributes exist)*

### 4.2 Normal Form Proofs

#### First Normal Form (1NF)
- **Criteria:** All attributes contain atomic (indivisible) values, there are no repeating groups or multi-valued columns, and every table has a defined Primary Key.
- **Proof:** Multi-valued attributes from raw entities—such as a member possessing multiple skills or a job requiring multiple skills—are decomposed into separate junction tables (`member_skills`, `job_skills`) rather than stored as comma-separated strings or arrays. Every column holds a single scalar value.

#### Second Normal Form (2NF)
- **Criteria:** The schema is in 1NF, and every non-prime attribute is fully functionally dependent on the entire Primary Key (no partial dependencies).
- **Proof:**
  - Single-column primary key tables (`members`, `companies`, `jobs`, `skills`, `applications`) cannot have partial dependencies by definition.
  - In composite-key junction tables (`member_skills(member_id, skill_id)` and `job_skills(job_id, skill_id)`), any non-key attributes depend on the combined `(entity_id, skill_id)` pair rather than either key alone.

#### Third Normal Form (3NF)
- **Criteria:** The schema is in 2NF, and no non-prime attribute is transitively dependent on the Primary Key ($X \rightarrow Y \rightarrow Z$ where $Y$ is not a candidate key).
- **Proof:** Company attributes (`industry`, `company_size`, `headquarters`) depend on `company_id` rather than `job_id`, so they are isolated in `linkedin.companies` instead of `linkedin.jobs`. Similarly, skill names and categories are isolated in `linkedin.skills` rather than repeated in `member_skills` or `job_skills`. Thus, every non-key attribute depends solely on its table's primary key ("the key, the whole key, and nothing but the key").

---

## 5. Custom Data Integrity Checks

After executing `sql/01_schema.sql` and loading the seed CSVs via `sql/02_load_data.sql`, run the following 3 custom validation queries in `psql` to verify zero anomalies.

### Check 1: Orphaned Foreign Key & Referential Integrity Audit
- **Objective:** Verify that every job application references an existing member and an existing job posting.
- **SQL Query:**
  ```sql
  SELECT COUNT(*) AS orphaned_applications
  FROM linkedin.applications a
  LEFT JOIN linkedin.members m ON a.member_id = m.member_id
  LEFT JOIN linkedin.jobs j ON a.job_id = j.job_id
  WHERE m.member_id IS NULL OR j.job_id IS NULL;