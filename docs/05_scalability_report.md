# Phase 5: Scalability Analysis (1x Seed vs. 20x Large Dataset)

## 1. Dataset Scaling Overview
To evaluate how our indexed schema scales under production-like volume, we loaded the official Phase 5 `large_data` dataset (**21,303,424 total rows**, ~20x the initial seed dataset) into PostgreSQL v16 (`linkedin_large`) and re-ran the full 30-query workload (`workload_30.sql`) across 3 runs per query.

### Row Count Growth by Major Table

| Table | 20x Large Rows | Scaling Factor |
| :--- | ---: | ---: |
| `profile_views` | 4,399,965 | ~20x |
| `applications` | 4,249,459 | ~20x |
| `job_skills` | 3,999,994 | ~20x |
| `connections` | 2,999,984 | ~20x |
| `member_skills` | 1,998,792 | ~20x |
| `positions` | 1,315,149 | ~20x |
| `invitations` | 1,199,999 | ~20x |
| `members` | 800,000 | ~20x |
| `jobs` | 300,000 | ~20x |
| `companies` | 40,000 | ~20x |

---

## 2. Performance Comparison: 1x Optimized vs. 20x Large

| Query | 1x Optimized (ms) | 20x Large (ms) | Scale Factor | Scaling Behavior |
| :--- | ---: | ---: | ---: | :--- |
| **R01** | 0.179 | 0.119 | **0.7x** | Sub-linear (`O(log N)` B-Tree lookup) |
| **R02** | 0.078 | 0.093 | **1.2x** | Sub-linear (`O(log N)` Index Scan) |
| **R03** | 0.257 | 0.221 | **0.9x** | Sub-linear (`O(log N)` Bitmap Index Scan) |
| **R04** | 0.205 | 0.230 | **1.1x** | Sub-linear (`O(log N)` Bitmap Index Scan) |
| **R05** | 1.479 | 1.830 | **1.2x** | Sub-linear (2-hop indexed traversal) |
| **R06** | 0.921 | 16.099 | **17.5x** | Linear (`ILIKE` filter over recent jobs) |
| **R07** | 2.371 | 55.318 | **23.3x** | Linear (Index-Only Scan over 4M `job_skills`) |
| **R08** | 0.383 | 0.494 | **1.3x** | Sub-linear (`O(log N)` Unique Index Scan) |
| **R09** | 0.393 | 0.145 | **0.4x** | Sub-linear (`O(log N)` Composite Index) |
| **R10** | 0.181 | 0.070 | **0.4x** | Sub-linear (`O(log N)` Partial Index) |
| **R11** | 0.131 | 0.165 | **1.3x** | Sub-linear (`O(log N)` Composite Index) |
| **R12** | 0.539 | 1.808 | **3.4x** | Near-constant (Partial Index on `end_date IS NULL`) |
| **R13** | 42.512 | 2288.293 | **53.8x** | Super-linear (`NOT IN` on nullable column; hit `work_mem` limit) |
| **R14** | 7.240 | 375.032 | **51.8x** | Super-linear (Hash Join spill across 4.25M applications) |
| **R15** | 16.126 | 130.767 | **8.1x** | Sub-20x (Non-sargable `EXTRACT(YEAR)` scan) |
| **R16** | 2.421 | 18.674 | **7.7x** | Sub-20x (Index Scan on `posted_at`) |
| **R17** | 66.331 | 1451.275 | **21.9x** | Linear (Window function `LEAD()` over 1.31M `positions`) |
| **R18** | 1.650 | 36.170 | **21.9x** | Linear (Top-50 filter across 800k `members`) |
| **R19** | 21.900 | 1665.493 | **76.1x** | Super-linear (Correlated subqueries executed per IT company) |
| **R20** | 12.486 | 150.206 | **12.0x** | Sub-20x (`::date` cast forces Seq Scan on 4.25M rows) |
| **R21** | 40.959 | 1002.002 | **24.5x** | Linear (`ROW_NUMBER()` sort over 2M `member_skills`) |
| **R22** | 17.686 | 20.528 | **1.2x** | Sub-linear (`idx_applications_applied_at` Index Scan) |
| **R23** | 0.068 | 0.193 | **2.8x** | Sub-linear (`lower(email)` Expression Index) |
| **R24** | 15.574 | 186.231 | **12.0x** | Sub-20x (Index Scan on `invitations.sent_at`) |
| **R25** | 61.553 | 1555.918 | **25.3x** | Linear (Window function `LAG()` over 1.31M `positions`) |
| **W01** | 1.923 | 3.420 | **1.8x** | Sub-linear (B-Tree insert overhead remains low) |
| **W02** | 0.712 | 1.214 | **1.7x** | Sub-linear (Partial index lookup + PK update) |
| **W03** | 1.075 | 2.129 | **2.0x** | Sub-linear (Indexed lookup + conflict check) |
| **W04** | 10.300 | 530.929 | **51.5x** | Super-linear (Bulk update across thousands of expired open jobs) |
| **W05** | 6.143 | 122.771 | **20.0x** | Linear (Multi-table join update on TCS applications) |

---

## 3. Key Bottlenecks & Architectural Takeaways

1. **B-Tree & Partial Indexes Scale Logarithmically (`O(log N)`):**
   User-facing transactional queries (`R01`–`R05`, `R08`–`R11`, `R22`, `R23`) showed virtually zero degradation when scaling from 1M to 21.3M rows, remaining well under `2 ms` (`0.070 ms` to `1.830 ms`).
2. **The `work_mem` Cliff on `R13` (`NOT IN` with `NULL`s):**
   Under PostgreSQL's default `4 MB` `work_mem`, `R13` stalled at 20x scale because the 4.4M-row `profile_views.viewer_id` hash table exceeded RAM and fell back to a quadratic `O(N × M)` `SubPlan` (since `viewer_id` is nullable, blocking a standard Hash Anti-Join). Increasing `work_mem = '256MB'` restored the `Hashed SubPlan` (`2288.293 ms`), while our `NOT EXISTS` rewrite in `sql/06_optimized_queries.sql` avoids this trap altogether.
3. **Correlated Subqueries Compound at Scale (`R19`):**
   `R19` degraded by **76.1x** (`21.900 ms` $\rightarrow$ `1665.493 ms`) because correlated subqueries re-execute per matching company row. Using the pre-aggregated CTE rewrite in `sql/06_optimized_queries.sql` eliminates repeated scans.
4. **Justification for Declarative Partitioning (`sql/08_partitioning.sql`):**
   `applications` (4.25M rows) and `profile_views` (4.40M rows) account for over 40% of total database rows and drive the slowest time-range scans (`R14`, `R19`, `R20`, `W05`). Range-partitioning both tables by timestamp (`applied_at` and `viewed_at`) enables PostgreSQL partition pruning, shrinking active working sets and index B-Tree depths as historical data grows.
