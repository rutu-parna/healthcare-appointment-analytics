# Healthcare Appointment Access and Attendance Analysis
## Business Analysis & Operational Insights Report

---

### 1. Executive Summary

Healthcare appointment non-attendance ("no-shows") presents a significant operational planning challenge for outpatient clinics and public health systems. When scheduled appointments are missed without prior notification, allocated clinical consultation time remains idle, waiting queues for other patients are artificially lengthened, and clinical care continuity is disrupted.

This project delivers an end-to-end operational and attendance analysis of **110,527 medical appointments** across public clinics in Vitória, Brazil, combining **SQL (SQLite)** data modeling and aggregation with **Python (Pandas, Matplotlib, Seaborn)** exploratory data analysis.

#### Core Findings:
1. **Baseline Utilization:** Exactly **20.19%** of booked appointments resulted in a no-show (88,208 attended vs. 22,319 missed), establishing an operational benchmark of approximately 1 unfulfilled consultation out of every 5 scheduled slots.
2. **Scheduling Horizon is the Primary Driver:** Appointment lead time (the calendar duration between booking and visit date) is the single strongest predictor of attendance. Same-day bookings achieve an outstanding **95.35% attendance rate** (4.65% no-show), whereas appointments booked $>30$ days in advance experience an absenteeism rate of **33.00%**.
3. **Age-Cohort Attendance Gradient:** Patient attendance improves steadily with maturity. Youth (ages 13–24) exhibit the highest no-show rate (**25.62%**), whereas Seniors (ages 65+) exhibit the lowest (**15.50%**).
4. **Gender Parity in Attendance:** Despite female patients booking nearly two-thirds of all consultations (65.00%), attendance rates between females (**79.69%**) and males (**80.03%**) are virtually identical (0.34% difference).
5. **The SMS Confounder:** While unadjusted data shows an apparent paradox (patients receiving SMS reminders exhibiting a 27.57% no-show rate vs. 16.70% for non-recipients), this is an operational artifact: all 38,563 same-day appointments never received an SMS due to 0-day lead time. Among advance bookings ($\ge 1$ day), SMS recipients attended slightly better than non-recipients (27.57% vs. 29.44% no-show).
6. **Geographic Variation:** Across the top 10 highest-volume clinic districts, attendance rates range from **84.16%** in Santa Martha to **73.73%** in Itararé, highlighting localized opportunities for operational review.

---

### 2. Business Problem

Outpatient healthcare delivery depends heavily on predictable schedule utilization:
- **Idle Clinical Capacity:** Consultation slots booked but unattended represent lost service capacity that cannot be recovered in real time.
- **Inflated Patient Wait Times:** When slots are occupied by patients who later fail to appear, other patients in need of timely medical consultations face deferred care and lengthened waitlists.
- **Care Continuity & Preventative Management:** Regular consultation attendance is vital for monitoring chronic conditions such as hypertension and diabetes. Unplanned absences can compromise preventative intervention schedules.

*Note: In alignment with sound data analytics principles, this report does not calculate financial losses or cost projections, as the underlying dataset captures operational and clinical tracking attributes without billing, cost, or revenue information.*

---

### 3. Dataset Overview

- **Source:** [Medical Appointment No Shows Dataset](https://www.kaggle.com/datasets/joniarroba/noshowappointments) (hosted on Kaggle, authored by Joni Hoppen & Aquarela Advanced Analytics).
- **Total Appointments Tracked:** `110,527`
- **Total Features (Columns):** `14`
- **Unique Patients:** `62,299`
- **Average Bookings per Patient:** `1.77`
- **Observation Focus:** Scheduled appointment attendance outcomes across public health clinics in Vitória, Espírito Santo, Brazil.

#### Captured Variables:
- `patient_id` (`TEXT`): Unique alphanumeric patient identifier.
- `appointment_id` (`INTEGER`): Unique primary key for each consultation.
- `gender` (`TEXT`): Patient gender (`'M'` or `'F'`).
- `scheduled_day` (`TEXT`): Timestamp when the appointment was registered.
- `appointment_day` (`TEXT`): Date of the scheduled medical consultation.
- `age` (`INTEGER`): Patient age in years.
- `neighbourhood` (`TEXT`): District location of the health clinic.
- `scholarship` (`INTEGER`): Binary welfare assistance indicator (*Bolsa Família*).
- `hipertension` (`INTEGER`): Binary indicator for diagnosed hypertension.
- `diabetes` (`INTEGER`): Binary indicator for diagnosed diabetes.
- `alcoholism` (`INTEGER`): Binary indicator for alcoholism condition.
- `handcap` (`INTEGER`): Graded handicap severity scale (0 to 4).
- `sms_received` (`INTEGER`): Binary indicator (1 or more SMS reminders sent).
- `no_show` (`TEXT`): Final outcome (`'No'` = Patient attended; `'Yes'` = Patient missed).

---

### 4. Tools & Technologies

| Tool / Library | Role in Analytical Pipeline |
| :--- | :--- |
| **SQL (SQLite)** | Relational table schema design, data type enforcement, index creation, and aggregated statistical querying. |
| **Python 3.13** | Core language for automated ingestion pipelines, environment configuration, and analytics. |
| **Pandas** | High-performance data manipulation, SQL-to-DataFrame loading, categorical bucketing, and summary table compilation. |
| **NumPy** | Array transformations, data type alignment, and vectorized operations. |
| **Matplotlib & Seaborn** | Statistical data visualization, multi-axis plotting, and publication-ready chart rendering (300 DPI). |
| **Jupyter Notebook** | Interactive development environment for documented, reproducible exploratory data analysis. |

---

### 5. Data Quality and Validation

A rigorous, multi-stage data hygiene audit was performed across both the SQLite database and Python runtime:

1. **Completeness & Uniqueness:**
   - All **110,527 records** loaded successfully into `healthcare_analytics.db`.
   - **Zero missing values** (`0` NULLs or blank fields across all 14 columns).
   - **Zero duplicate `appointment_id` keys** (confirming 100% primary key integrity).
2. **Identification of Domain Anomalies:**
   - **Negative Age Record:** Exactly 1 record (`appointment_id = 5775010`) recorded `age = -1`.
   - **Negative Lead-Time Records:** Exactly 5 records recorded a `scheduled_day` dated after `appointment_day` (e.g., booked on May 4 for a May 3 visit), resulting in negative lead times (-1 to -6 days). All 5 records had `no_show = 'Yes'`.
3. **Data Integrity Preservation:**
   - The primary database records were **preserved untouched**.
   - Anomalies were safely isolated using separate, in-memory analytical subsets (e.g., `df[df['age'] >= 0]` for age plots, and `df[df['lead_time_days'] >= 0]` for lead-time analysis).
4. **Cross-Method Reconciliation:**
   - SQL and Python age-group classifications were verified to produce identical appointment counts across every category.
   - Core portfolio KPIs (total appointments, attended count, missed count, attendance rate, no-show rate) cross-validated with 100% precision between SQL queries and Pandas computations.

---

### 6. Key Performance Indicators (KPIs)

Computed via verified queries against [`healthcare_analytics.db`](file:///c:/Users/soham/OneDrive/Desktop/health_data/healthcare_analytics.db):

| Key Performance Indicator | Value | Operational Definition & Strategic Meaning |
| :--- | :---: | :--- |
| **Total Appointments** | **110,527** | Total volume of confirmed outpatient bookings logged in the system. |
| **Unique Patients** | **62,299** | Distinct individuals served; measures the patient population size. |
| **Attended Appointments** | **88,208** | Number of scheduled slots successfully completed (`no_show = 'No'`). |
| **Missed Appointments** | **22,319** | Number of scheduled slots missed by patients (`no_show = 'Yes'`). |
| **Portfolio Attendance Rate** | **79.81%** | Percentage of scheduled capacity utilized for completed consultations. |
| **Portfolio No-Show Rate** | **20.19%** | Percentage of booked consultations that resulted in absenteeism; baseline benchmark. |
| **Average Visits per Patient** | **1.77** | Average consultation frequency; indicates repeat clinical engagement. |

---

### 7. SQL Analysis and Verified Findings

#### A. Age-Group Analysis
Using standard clinical life-stage classifications:

| Age Demographic Cohort | Age Span | Total Bookings | Attended | Missed | No-Show Rate (%) | Attendance Rate (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Invalid (`<0`)** | $< 0$ | 1 | 1 | 0 | 0.00% | 100.00% |
| **Children** | `0–12` | 21,036 | 16,729 | 4,307 | **20.47%** | 79.53% |
| **Youth** | `13–24` | 16,231 | 12,072 | 4,159 | **25.62%** | 74.38% |
| **Young Adults** | `25–44` | 28,865 | 22,404 | 6,461 | **22.38%** | 77.62% |
| **Middle-Aged Adults** | `45–64` | 29,992 | 24,833 | 5,159 | **17.20%** | 82.80% |
| **Seniors** | `65+` | 14,402 | 12,169 | 2,233 | **15.50%** | 84.50% |
| **Total Reconciled Sum** | | **110,527** | **88,208** | **22,319** | **20.19%** | **79.81%** |

*Finding:* Absenteeism exhibits an inverse relationship with patient age. Younger cohorts (Youth at 25.62% and Young Adults at 22.38%) have the highest no-show tendencies, while Seniors demonstrate the highest reliability (15.50%).

#### B. Chronic-Condition Analysis
Evaluating attendance across diagnostic indicators:

| Condition Profile | Patient Category | Total Appointments | No-Show Rate (%) | Attendance Rate (%) |
| :--- | :--- | :---: | :---: | :---: |
| **Hypertension** | Without Hypertension (`0`) | 88,726 | **20.90%** | 79.10% |
| | Diagnosed Hypertension (`1`) | 21,801 | **17.30%** | 82.70% |
| **Diabetes** | Without Diabetes (`0`) | 102,584 | **20.36%** | 79.64% |
| | Diagnosed Diabetes (`1`) | 7,943 | **18.00%** | 82.00% |

*Interpretation:* Patients with chronic conditions (hypertension and diabetes) display lower no-show rates than patients without these diagnoses (17.30% vs. 20.90% for hypertension; 18.00% vs. 20.36% for diabetes). This is an **observed statistical association**—patients managing chronic conditions may have stronger perceived medical need and structured care pathways—not causal proof that a diagnosis prevents missed visits.

#### C. Neighbourhood Analysis (Top 10 Locations by Volume)
Examining attendance stability across the highest-traffic clinic facilities:

| Rank | Clinic Neighbourhood | Total Bookings | Attended | Missed | No-Show Rate (%) | Attendance Rate (%) |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| **1** | **JARDIM CAMBURI** | 7,717 | 6,252 | 1,465 | **18.98%** | 81.02% |
| **2** | **MARIA ORTIZ** | 5,805 | 4,586 | 1,219 | **21.00%** | 79.00% |
| **3** | **RESISTÊNCIA** | 4,431 | 3,525 | 906 | **20.45%** | 79.55% |
| **4** | **JARDIM DA PENHA** | 3,877 | 3,246 | 631 | **16.28%** | 83.72% |
| **5** | **ITARARÉ** | 3,514 | 2,591 | 923 | **26.27%** | 73.73% |
| **6** | **CENTRO** | 3,334 | 2,631 | 703 | **21.09%** | 78.91% |
| **7** | **TABUAZEIRO** | 3,132 | 2,559 | 573 | **18.30%** | 81.70% |
| **8** | **SANTA MARTHA** | 3,131 | 2,635 | 496 | **15.84%** | 84.16% |
| **9** | **JESUS DE NAZARETH** | 2,853 | 2,157 | 696 | **24.40%** | 75.60% |
| **10**| **BONFIM** | 2,773 | 2,223 | 550 | **19.83%** | 80.17% |

*Interpretation:* Substantial attendance differences exist across clinic locations, ranging from **15.84%** in Santa Martha to **26.27%** in Itararé. While location correlates with attendance, geographic naming alone is not a causal driver; local factors such as public transit connectivity, clinic accessibility, and neighbourhood demographics contribute to these variances.

#### D. Repeat-Patient Analysis
Evaluating patient retention and appointment frequency:

| Patient Frequency Tier | Unique Patients | Total Appointments | Missed Visits | Tier No-Show Rate (%) | Attendance Rate (%) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **1 Visit (Single-Visit Patients)** | 37,920 | 37,920 | 7,118 | **18.77%** | 81.23% |
| **2–3 Visits** | 19,395 | 47,845 | 9,944 | **20.78%** | 79.22% |
| **4–5 Visits** | 3,486 | 15,364 | 3,356 | **21.84%** | 78.16% |
| **6+ Visits (Frequent Patients)** | 1,498 | 9,398 | 1,901 | **20.23%** | 79.77% |
| **Total** | **62,299** | **110,527** | **22,319** | **20.19%** | **79.81%** |

*Interpretation:* Single-visit patients maintain the lowest no-show rate (**18.77%**). As patients schedule repeat consultations (2–5 visits), no-show rates slightly increase to **20.78% – 21.84%**, before stabilizing at **20.23%** among frequent patients (6+ visits).

#### E. Lead-Time Analysis
Analyzing the interval between scheduling date and appointment date:

| Lead-Time Bucket | Calendar Interval | Total Bookings | Attended | Missed | No-Show Rate (%) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Invalid Negative Lead Time** | $< 0\text{ days}$ | 5 | 0 | 5 | **100.00%** |
| **Same Day** | $0\text{ days}$ | 38,563 | 36,771 | 1,792 | **4.65%** |
| **1–3 Days** | $1–3\text{ days}$ | 14,675 | 11,316 | 3,359 | **22.89%** |
| **4–7 Days** | $4–7\text{ days}$ | 17,510 | 13,097 | 4,413 | **25.20%** |
| **8–14 Days** | $8–14\text{ days}$ | 12,025 | 8,361 | 3,664 | **30.47%** |
| **15–30 Days** | $15–30\text{ days}$ | 17,371 | 11,710 | 5,661 | **32.59%** |
| **31+ Days** | $> 30\text{ days}$ | 10,378 | 6,953 | 3,425 | **33.00%** |
| **Total Valid Appointments** | $\ge 0\text{ days}$ | **110,522** | **88,208** | **22,314** | **20.19%** |

*Note on Data Exceptions:* The 5 negative lead-time records are data-logging exceptions (scheduled after appointment date) and must be isolated from valid operational benchmarks.

---

### 8. Python Exploratory Data Analysis & Visualizations Summary

The exploratory analysis produced 8 high-resolution visualizations stored in [`visuals/`](file:///c:/Users/soham/OneDrive/Desktop/health_data/visuals/):

1. **Overall Appointment Outcome Distribution (`01_outcome_distribution.png`):**
   - 79.81% Attended (88,208) vs. 20.19% Missed (22,319). Establishes the baseline benchmark.
2. **Patient Age Distribution (`02_age_distribution.png`):**
   - Cleaned subset (excluding 1 negative age). Mean age: 37.1 years; median: 37.0 years. Bimodal curve with peaks at infancy (0–1 years) and late middle age (50–60 years).
3. **No-Show Rate by Age Group (`03_noshow_by_age_group.png`):**
   - Youth (13–24) peak at 25.62% absenteeism, whereas Seniors (65+) attend at 84.50% (15.50% no-show).
4. **No-Show Rate by Gender (`04_noshow_by_gender.png`):**
   - Females account for 65.00% of bookings (71,840) and males account for 35.00% (38,687). No-show rates are virtually identical: 20.31% for females vs. 19.97% for males.
5. **No-Show Rate by SMS Reminder Status (`05_noshow_by_sms.png`):**
   - Unadjusted no-show rate: 27.57% for SMS recipients vs. 16.70% for non-recipients.
   - **Confounder Identified:** All 38,563 same-day appointments had 0 days lead time and received no SMS, while carrying an ultra-low 4.65% miss rate. Among advance bookings ($\ge 1$ day), SMS recipients experienced a 27.57% no-show rate vs. 29.44% for non-recipients (a modest 1.87% improvement).
6. **No-Show Rate by Scheduling Lead Time (`06_noshow_by_lead_time.png`):**
   - Strict monotonic climb: 4.65% for same-day bookings to 33.00% for bookings $>30$ days. Reconciled across 110,522 valid appointments.
7. **Weekday-Wise Appointment Analysis (`07_weekday_analysis.png`):**
   - Tuesday (25,640) and Wednesday (25,867) handle peak volume; Thursday (17,247) and Friday (19,019) handle less.
   - Weekday no-show rates remain remarkably flat: Monday (20.65%), Tuesday (20.09%), Wednesday (19.69%), Thursday (19.35%), and Friday (21.23%).
   - Weekend operations: Only 39 appointments took place on Saturday (23.08% no-show) and 0 on Sunday.
8. **Top 10 Neighbourhoods Analysis (`08_top10_neighbourhoods.png`):**
   - Ranks top 10 highest-volume facilities. Highlights attendance variations between Jardim da Penha / Santa Martha (<16.5% no-show) and Itararé / Jesus de Nazareth (>24.4% no-show).

---

### 9. Business Insights & Practical Recommendations

| Focus Area | Observed Analytical Finding | Practical Operational Recommendation | Implementation Type |
| :--- | :--- | :--- | :--- |
| **Distant Horizons ($>7$ Days)** | No-show rates exceed 30% for bookings $>7$ days in advance. | Implement a mandatory automated re-confirmation workflow 48–72 hours prior to visit date ("Reply 1 to Confirm, 2 to Reschedule"). | Preventative Process |
| **Same-Day Capacity** | Same-day appointments achieve 95.35% attendance. | Protect an operational buffer of open same-day slots for acute or walk-in needs rather than booking all slots weeks in advance. | Schedule Optimization |
| **Youth & Young Adults** | Youth (13–24) and Young Adults (25–44) miss appointments at 25.6% and 22.4%. | Explore flexible clinic scheduling windows (early morning or evening slots) and test mobile-first communication channels (e.g., instant messaging). | Targeted Engagement |
| **SMS Strategy Optimization** | Single SMS messages sent days in advance have limited reach. | Transition from one-way text blasts to dynamic multi-touch reminder sequences with clear cancellation options. | Communication Workflow |
| **High-Miss Clinic Hubs** | Itararé (26.27%) and Jesus de Nazareth (24.40%) have high absenteeism. | Conduct localized patient access reviews to assess public transit friction, walking barriers, or facility check-in bottlenecks. | Facility-Level Review |
| **KPI Tracking** | Baseline portfolio no-show rate is 20.19%. | Institute weekly dashboard monitoring tracking Attendance Rate, No-Show Rate, and Lead-Time distribution by department. | Operational Governance |

*Note: The recommendations above represent operational proposals to be tested via controlled pilot programs; they are distinct from historical descriptive findings.*

---

### 10. Limitations

1. **Historical Snapshot:** The dataset captures a multi-week observational period from May–June 2016 and may not account for seasonal variations across an entire annual cycle.
2. **Operational Scope:** The data tracks scheduling and demographic indicators only. It contains no clinical severity grades, consultation specialties (e.g., oncology vs. general checkup), doctor identity, or diagnostic results.
3. **No Financial or Billing Data:** The dataset lacks billing, payment, revenue, or clinic operating cost metrics; financial loss calculations cannot be performed.
4. **No Causal Guarantee:** Observed statistical correlations (such as chronic illness or welfare enrolment correlating with attendance) do not prove direct causation without controlled randomized trials.
5. **Weekend Data Scarcity:** Saturday accounts for only 39 consultations and Sunday has 0 records, precluding meaningful weekend operational modeling.
6. **Geographic Specificity:** Data originates from public healthcare facilities in Vitória, Brazil; findings may reflect local municipal healthcare policies and may not generalize directly to private healthcare or other countries.

---

### 11. Conclusion

This project demonstrates the analytical power of coupling **SQL** for relational data integrity, structured aggregation, and categorical KPI reporting with **Python** for granular statistical validation and high-resolution visual storytelling.

By identifying **scheduling lead time** as the primary driver of patient absenteeism and resolving confounding factors in **reminder communications**, healthcare operational managers can shift from reactive scheduling to data-informed, proactive capacity management.
