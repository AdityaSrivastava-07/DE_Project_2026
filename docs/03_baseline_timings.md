# Phase 3: Baseline Query Performance

## 1. Methodology
To establish a baseline for our database performance, we ran a workload of 30 queries (`workload_30.sql`) against the unoptimized `linkedin` schema containing 149,984 rows of seed data. The test was executed on PostgreSQL v16 running locally on an Apple M4 Silicon using the provided `run_benchmark.sh` script. At this stage, no indexes exist other than the default primary key and unique constraint indexes created during Phase 1.

## 2. Top 5 Slowest Queries (Pre-Optimization)

Based on our benchmark output, the following five queries are the slowest and most in need of indexing during Phase 4:

1. **R19 (Company Applicant Demographics):** `404.427 ms`
   * *Plan:* Seq Scan on companies | Seq Scan on jobs | Index Scan using uq_job_application on applications
   * *Analysis:* The database has to sequentially scan the entire `companies` and `jobs` tables before it can use the application unique index, causing massive overhead.
2. **R21 (Most Endorsed Skills):** `158.449 ms`
   * *Plan:* Seq Scan on member_skills | Seq Scan on skills
   * *Analysis:* Aggregating and grouping endorsements requires scanning every single row in the junction table.
3. **R17 (Members with Multiple Roles at Same Company):** `69.797 ms`
   * *Plan:* Seq Scan on positions | Index Scan using companies_company_name_key on companies | Index Scan using companies_pkey on companies
   * *Analysis:* The sequential scan on `positions` to find overlapping dates per company creates a significant bottleneck.
4. **R25 (Members with Longest Tenure):** `64.572 ms`
   * *Plan:* Seq Scan on positions
   * *Analysis:* Sorting by the duration between `start_date` and `end_date` requires a full table scan and in-memory sort.
5. **R22 (Application Conversion Funnel):** `60.936 ms`
   * *Plan:* Seq Scan on applications
   * *Analysis:* Grouping by job posting and status requires reading the entire applications table.

## 3. Top 3 Fastest Queries (Pre-Optimization)

1. **R08 (Check if Member Applied to Job):** `0.643 ms`
   * *Plan:* Index Scan using uq_job_application on applications
   * *Analysis:* This query is incredibly fast even before optimization because it utilizes the implicitly created unique B-Tree index on `(job_id, member_id)` from CP1.
2. **W01 (Insert New Member):** `1.366 ms`
   * *Plan:* (no scan)
   * *Analysis:* Standard row insertion without conflict checking is highly efficient.
3. **R16 (Remote Jobs by City):** `3.063 ms`
   * *Plan:* Seq Scan on jobs | Seq Scan on cities
   * *Analysis:* While it uses sequential scans, the filtering logic for specific workplace types evaluates quickly.

## 4. Benchmark Execution Logs
The raw CSV results outputted by the benchmark script are checked into version control at `benchmarks/results/baseline/summary.csv`.
