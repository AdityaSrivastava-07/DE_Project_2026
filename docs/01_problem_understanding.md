
# Problem Understanding and Analysis

## 1. Business Context

The DE Capstone Project focuses on designing and analyzing a relational database for a LinkedIn-like professional networking platform. The platform manages professional profiles, companies, job postings, skills, and job applications.

The primary business needs are to maintain accurate and consistent professional information, facilitate job discovery and applications, support networking activities, and enable data-driven insights into recruitment and professional trends. The database must efficiently support transactional operations as well as analytical queries while maintaining data integrity and minimizing redundancy.

## 2. Affected Stakeholders

- **Members / Job Seekers:** Maintain professional profiles, search for opportunities, and apply for jobs.
- **Recruiters / Companies:** Create job postings, review applicants, and identify suitable candidates.
- **Platform Administrators:** Maintain data consistency, manage platform records, and ensure reliable database operations.
- **Data Analysts / Management:** Analyze recruitment trends, skill demand, company activity, and application patterns.

## 3. Problem Analysis (P1–P7)

| Problem | Business Need | Affected Stakeholders | Classification |
|---|---|---|---|
| P1 – Member Profile Retrieval | Retrieve member details and professional information efficiently for profile viewing and candidate discovery. | Members, Recruiters | Real-time |
| P2 – Professional Networking | Manage and retrieve connections between members to facilitate professional networking. | Members, Platform Administrators | Real-time |
| P3 – Job Search and Discovery | Allow members to search and filter job opportunities based on relevant criteria such as skills, company, and location. | Members, Recruiters | Real-time |
| P4 – Job Application Management | Record and retrieve job applications while maintaining accurate relationships between members and job postings. | Members, Recruiters | Real-time |
| P5 – Company and Recruitment Insights | Analyze company activity and recruitment patterns to understand hiring behavior and organizational trends. | Companies, Management, Data Analysts | Analytics |
| P6 – Skill Demand Analysis | Identify popular skills and analyze the distribution of professional competencies to support career and recruitment decisions. | Members, Recruiters, Data Analysts | Analytics |
| P7 – Application and Job Trends | Analyze historical job postings and application data to identify recruitment trends and evaluate job-seeking activity. | Recruiters, Management, Data Analysts | Analytics |

## 4. Real-Time vs. Analytics Classification

Real-time problems (P1–P4) involve operational database interactions that require immediate and accurate responses. These include retrieving profiles, managing professional connections, searching for jobs, and recording applications. Such operations prioritize data consistency, query efficiency, and reliable transaction processing.

Analytics problems (P5–P7) involve processing and aggregating historical data to generate insights. These include analyzing company recruitment activity, identifying in-demand skills, and evaluating application trends. These queries may involve joins, aggregations, grouping, and large-scale data retrieval, making query optimization important for performance.

## 5. Conclusion

The database must support both operational and analytical requirements of the professional networking platform. Efficient schema design, appropriate constraints, normalization, and query optimization are essential for maintaining data integrity and providing reliable performance. The distinction between real-time operations and analytics helps guide database design and performance optimization throughout the DE Capstone Project.
