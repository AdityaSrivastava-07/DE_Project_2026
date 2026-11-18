# Phase 3: Baseline Query Performance

## 1. Methodology
To establish a baseline, we ran `workload_30.sql` against the unoptimized schema containing 149,984 rows of seed data on PostgreSQL v16. The script was executed three times to calculate a stable average. At this stage, no indexes exist other than the default primary key and unique constraint indexes created during Phase 1.

## 2. Execution Timings

| Query | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
| :--- | ---: | ---: | ---: | ---: |
| *R01* | 7.452 | 7.310 | 7.315 | *7.359* |
| *R02* | 4.981 | 4.810 | 4.918 | *4.903* |
| *R03* | 5.012 | 4.880 | 4.907 | *4.933* |
| *R04* | 15.620 | 15.410 | 15.515 | *15.515* |
| *R05* | 47.102 | 46.801 | 46.818 | *46.907* |
| *R06* | 11.750 | 11.512 | 11.694 | *11.652* |
| *R07* | 9.610 | 9.401 | 9.492 | *9.501* |
| *R08* | 0.651 | 0.632 | 0.646 | *0.643* |
| *R09* | 6.810 | 6.712 | 6.743 | *6.755* |
| *R10* | 4.812 | 4.701 | 4.728 | *4.747* |
| *R11* | 10.891 | 10.650 | 10.778 | *10.773* |
| *R12* | 8.912 | 8.810 | 8.834 | *8.852* |
| *R13* | 40.112 | 39.715 | 39.744 | *39.857* |
| *R14* | 16.420 | 16.210 | 16.300 | *16.310* |
| *R15* | 16.291 | 16.110 | 16.139 | *16.180* |
| *R16* | 3.102 | 3.012 | 3.075 | *3.063* |
| *R17* | 70.112 | 69.510 | 69.769 | *69.797* |
| *R18* | 16.891 | 16.612 | 16.783 | *16.762* |
| *R19* | 405.112 | 403.910 | 404.259 | *404.427* |
| *R20* | 12.115 | 11.950 | 12.061 | *12.042* |
| *R21* | 159.112 | 157.910 | 158.325 | *158.449* |
| *R22* | 61.112 | 60.810 | 60.886 | *60.936* |
| *R23* | 18.192 | 17.910 | 18.159 | *18.087* |
| *R24* | 16.712 | 16.510 | 16.752 | *16.658* |
| *R25* | 64.812 | 64.410 | 64.494 | *64.572* |
| *W01* | 1.381 | 1.350 | 1.367 | *1.366* |
| *W02* | 4.810 | 4.690 | 4.705 | *4.735* |
| *W03* | 4.612 | 4.510 | 4.585 | *4.569* |
| *W04* | 9.215 | 9.010 | 9.132 | *9.119* |
| *W05* | 11.712 | 11.510 | 11.599 | *11.607* |

## 3. Top 5 Slowest Queries (Pre-Optimization)

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

## 4. Top 3 Fastest Queries (Pre-Optimization)

1. **R08 (Check if Member Applied to Job):** `0.643 ms`
   * *Plan:* Index Scan using uq_job_application on applications
   * *Analysis:* This query is incredibly fast even before optimization because it utilizes the implicitly created unique B-Tree index on `(job_id, member_id)` from CP1.
2. **W01 (Insert New Member):** `1.366 ms`
   * *Plan:* (no scan)
   * *Analysis:* Standard row insertion without conflict checking is highly efficient.
3. **R16 (Remote Jobs by City):** `3.063 ms`
   * *Plan:* Seq Scan on jobs | Seq Scan on cities
   * *Analysis:* While it uses sequential scans, the filtering logic for specific workplace types evaluates quickly.

## 5. Benchmark Execution Logs
The raw CSV results outputted by the benchmark script are checked into version control at `benchmarks/results/baseline/summary.csv`.