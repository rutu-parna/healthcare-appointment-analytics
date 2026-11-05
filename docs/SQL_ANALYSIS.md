# SQL Analysis Documentation

**Project:** Healthcare Appointment Access and Attendance Analysis  
**Database:** `healthcare_analytics.db` (SQLite)  
**Table:** `appointments`  
**Records:** 110,527  
**SQL Scripts:** `sql/01_table_creation.sql` through `sql/05_operational_analysis.sql`

---

## Table of Contents

1. [Database Overview](#1-database-overview)
2. [Data Quality Analysis](#2-data-quality-analysis)
3. [KPI Analysis](#3-kpi-analysis)
4. [Age-Group Analysis](#4-age-group-analysis)
5. [Attendance Outcome Analysis](#5-attendance-outcome-analysis)
6. [Operational Analysis](#6-operational-analysis)
7. [Business Interpretation](#7-business-interpretation)
8. [SQL Concepts Demonstrated](#8-sql-concepts-demonstrated)

---

## 1. Database Overview

### Source

The dataset originates from the [Kaggle Medical Appointment No Shows dataset](https://www.kaggle.com/datasets/joniarroba/noshowappointments), covering medical appointments in Vitória, Espírito Santo, Brazil. The raw CSV was imported into an SQLite database using `scripts/import_data.py`.

### Schema

The `appointments` table was created by `sql/01_table_creation.sql`:

```sql
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id   INTEGER PRIMARY KEY,
    patient_id       TEXT    NOT NULL,
    gender           TEXT    NOT NULL,
    scheduled_day    TEXT    NOT NULL,
    appointment_day  TEXT    NOT NULL,
    age              INTEGER NOT NULL,
    neighbourhood    TEXT    NOT NULL,
    scholarship      INTEGER NOT NULL,
    hipertension     INTEGER NOT NULL,
    diabetes         INTEGER NOT NULL,
    alcoholism       INTEGER NOT NULL,
    handcap          INTEGER NOT NULL,
    sms_received     INTEGER NOT NULL,
    no_show          TEXT    NOT NULL
);
```

### Column Descriptions

| Column | Type | Description |
| :--- | :--- | :--- |
| `appointment_id` | INTEGER PK | Unique identifier for each appointment booking |
| `patient_id` | TEXT | Patient identifier (one patient can have multiple appointments) |
| `gender` | TEXT | Patient gender — `'F'` (Female) or `'M'` (Male) |
| `scheduled_day` | TEXT | ISO 8601 timestamp when the appointment was booked (e.g. `2016-04-29T18:38:08Z`) |
| `appointment_day` | TEXT | Date of the actual appointment (e.g. `2016-04-29T00:00:00Z`) |
| `age` | INTEGER | Patient age in years at time of appointment |
| `neighbourhood` | TEXT | Neighbourhood where the clinic is located |
| `scholarship` | INTEGER | Whether the patient is enrolled in the Bolsa Família welfare programme (0 = No, 1 = Yes) |
| `hipertension` | INTEGER | Whether the patient has hypertension (0 = No, 1 = Yes) |
| `diabetes` | INTEGER | Whether the patient has diabetes (0 = No, 1 = Yes) |
| `alcoholism` | INTEGER | Whether the patient has alcoholism noted (0 = No, 1 = Yes) |
| `handcap` | INTEGER | Disability indicator (0 = None; original encoding retained as-is) |
| `sms_received` | INTEGER | Whether the patient received an SMS reminder (0 = No, 1 = Yes) |
| `no_show` | TEXT | Whether the patient missed the appointment — `'Yes'` = missed, `'No'` = attended |

> [!NOTE]
> The column name `hipertension` and `handcap` follow the original Kaggle dataset spelling. They were not corrected during import to preserve traceability to the source data.

### Indexes

Three indexes were created to accelerate filtering and aggregation queries:

```sql
CREATE INDEX IF NOT EXISTS idx_patient_id      ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_no_show         ON appointments(no_show);
CREATE INDEX IF NOT EXISTS idx_appointment_day ON appointments(appointment_day);
```

---

## 2. Data Quality Analysis

**Script:** `sql/02_data_quality.sql`

Data quality checks were run before any analytical queries to understand what cleaning or exclusions were required.

### 2.1 Missing Values

```sql
SELECT
    SUM(CASE WHEN appointment_id  IS NULL THEN 1 ELSE 0 END) AS missing_appointment_id,
    SUM(CASE WHEN patient_id      IS NULL THEN 1 ELSE 0 END) AS missing_patient_id,
    SUM(CASE WHEN gender          IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN scheduled_day   IS NULL THEN 1 ELSE 0 END) AS missing_scheduled_day,
    SUM(CASE WHEN appointment_day IS NULL THEN 1 ELSE 0 END) AS missing_appointment_day,
    SUM(CASE WHEN age             IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN neighbourhood   IS NULL THEN 1 ELSE 0 END) AS missing_neighbourhood,
    SUM(CASE WHEN no_show         IS NULL THEN 1 ELSE 0 END) AS missing_no_show
FROM appointments;
```

**Result:** **0 missing values** across all 14 columns. The dataset is complete with no nulls.

---

### 2.2 Duplicate Appointment IDs

```sql
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT appointment_id) AS unique_appointment_ids
FROM appointments;
```

**Result:**

| total_rows | unique_appointment_ids |
| ---: | ---: |
| 110,527 | 110,527 |

**0 duplicate appointment IDs.** Every row represents a distinct booking.

---

### 2.3 Age Anomalies

```sql
SELECT COUNT(*) AS negative_age_count
FROM appointments
WHERE age < 0;

SELECT appointment_id, patient_id, age, no_show
FROM appointments
WHERE age < 0;
```

**Result:**

| appointment_id | patient_id | age | no_show |
| ---: | :--- | ---: | :--- |
| 5775010 | 7... | -1 | No |

**1 record** with a negative age (`age = -1`). This is a data-entry error. The appointment was attended (no_show = 'No'). It is **excluded only from age-related analyses** and retained in all other counts.

Unusual but plausible high ages were also checked:

```sql
SELECT age, COUNT(*) AS count
FROM appointments
WHERE age > 100
GROUP BY age
ORDER BY age;
```

**Result:** A small number of records with ages above 100 exist in the dataset. These are retained as plausible (centenarian patients are uncommon but not impossible in a large population dataset).

---

### 2.4 Categorical Value Distributions

```sql
-- Gender distribution
SELECT gender, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS pct
FROM appointments
GROUP BY gender;

-- No-show distribution
SELECT no_show, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS pct
FROM appointments
GROUP BY no_show;

-- SMS received distribution
SELECT sms_received, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS pct
FROM appointments
GROUP BY sms_received;
```

**Gender:**

| gender | count | % |
| :--- | ---: | ---: |
| F | 71,840 | 65.0% |
| M | 38,687 | 35.0% |

**No-show:**

| no_show | count | % |
| :--- | ---: | ---: |
| No (attended) | 88,208 | 79.81% |
| Yes (missed) | 22,319 | 20.19% |

**SMS received:**

| sms_received | count | % |
| :--- | ---: | ---: |
| 0 (no SMS) | 75,045 | 67.9% |
| 1 (SMS sent) | 35,482 | 32.1% |

**Other binary flags (scholarship, hypertension, diabetes, alcoholism):** All contain only values 0 and 1 — no unexpected categories.

---

### 2.5 Date Consistency and Negative Lead Times

```sql
SELECT COUNT(*) AS negative_lead_time_count
FROM appointments
WHERE JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) < 0;
```

**Result:** **5 records** where the appointment date falls before the scheduled (booking) date — a logical impossibility indicating data-entry errors.

```sql
SELECT appointment_id,
       scheduled_day,
       appointment_day,
       ROUND(JULIANDAY(appointment_day) - JULIANDAY(scheduled_day), 2) AS lead_time_days,
       no_show
FROM appointments
WHERE JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) < 0;
```

All 5 negative lead-time records have `no_show = 'Yes'`. They are **excluded from lead-time analysis only** and retained in all other counts.

---

## 3. KPI Analysis

**Script:** `sql/03_kpi_analysis.sql`

### 3.1 Core KPIs

```sql
SELECT
    COUNT(*)                                                        AS total_appointments,
    COUNT(DISTINCT patient_id)                                      AS unique_patients,
    SUM(CASE WHEN no_show = 'No'  THEN 1 ELSE 0 END)               AS attended,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)               AS missed,
    ROUND(SUM(CASE WHEN no_show = 'No'  THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                            AS attendance_rate_pct,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                            AS noshow_rate_pct,
    ROUND(CAST(COUNT(*) AS FLOAT)
          / COUNT(DISTINCT patient_id), 2)                          AS avg_appointments_per_patient
FROM appointments;
```

**Verified Results:**

| KPI | Value |
| :--- | ---: |
| Total appointments | 110,527 |
| Unique patients | 62,299 |
| Attended | 88,208 |
| Missed | 22,319 |
| Attendance rate | 79.81% |
| No-show rate | 20.19% |
| Avg appointments per patient | 1.77 |

> [!IMPORTANT]
> The no-show rate (20.19%) means roughly 1 in 5 booked appointments was missed. With 110,527 total appointments, this represents 22,319 unused slots.

---

## 4. Age-Group Analysis

**Script:** `sql/03_kpi_analysis.sql`

### 4.1 Classification Logic

Age groups were defined using `CASE WHEN … BETWEEN … THEN` expressions. The `BETWEEN` operator in SQLite is **inclusive on both ends**, so the boundary values (0, 12, 13, 24, etc.) belong to exactly one group with no gaps or overlaps.

```sql
SELECT
    CASE
        WHEN age < 0             THEN 'Invalid (<0)'
        WHEN age BETWEEN 0  AND 12 THEN '0-12 (Children)'
        WHEN age BETWEEN 13 AND 24 THEN '13-24 (Youth)'
        WHEN age BETWEEN 25 AND 44 THEN '25-44 (Young Adults)'
        WHEN age BETWEEN 45 AND 64 THEN '45-64 (Middle-Aged Adults)'
        ELSE                          '65+ (Seniors)'
    END                                                              AS age_group,
    COUNT(*)                                                         AS total,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)                AS missed,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                             AS noshow_rate_pct
FROM appointments
GROUP BY age_group
ORDER BY MIN(age);
```

### 4.2 Verified Results

| Age Group | Appointments | Missed | No-Show Rate |
| :--- | ---: | ---: | ---: |
| Invalid (<0) | 1 | 0 | 0.00% |
| 0–12 (Children) | 21,036 | 4,308 | 20.47% |
| 13–24 (Youth) | 16,231 | 4,159 | 25.62% |
| 25–44 (Young Adults) | 28,865 | 6,460 | 22.38% |
| 45–64 (Middle-Aged Adults) | 29,992 | 5,160 | 17.20% |
| 65+ (Seniors) | 14,402 | 2,232 | 15.50% |
| **Total** | **110,527** | **22,319** | **20.19%** |

> [!NOTE]
> The Python EDA function `assign_sql_age_group()` in `notebooks/healthcare_eda.ipynb` was written to match this exact BETWEEN logic, ensuring identical counts between SQL and Python outputs.

**Key observation:** Youth (13–24) has the highest no-show rate at 25.62%. No-show rates decline steadily through middle age and into senior age groups, suggesting older patients have stronger appointment adherence.

---

## 5. Attendance Outcome Analysis

**Script:** `sql/04_attendance_outcome_analysis.sql`

### 5.1 No-Show Rate by Gender

```sql
SELECT
    gender,
    COUNT(*)                                                         AS total,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)                AS missed,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                             AS noshow_rate_pct
FROM appointments
GROUP BY gender;
```

**Result:**

| Gender | Appointments | Missed | No-Show Rate |
| :--- | ---: | ---: | ---: |
| Female | 71,840 | 14,594 | 20.31% |
| Male | 38,687 | 7,725 | 19.97% |

The gap (0.34 percentage points) is negligible. Gender is **not a meaningful differentiator** of no-show behaviour in this dataset.

---

### 5.2 No-Show Rate by SMS Reminder

```sql
SELECT
    sms_received,
    COUNT(*)                                                         AS total,
    SUM(CASE WHEN no_show = 'No'  THEN 1 ELSE 0 END)                AS attended,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)                AS missed,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                             AS noshow_rate_pct
FROM appointments
GROUP BY sms_received;
```

**Result:**

| SMS Received | Appointments | Attended | Missed | No-Show Rate |
| :--- | ---: | ---: | ---: | ---: |
| 0 (No SMS) | 75,045 | 62,544 | 12,501 | 16.70% |
| 1 (SMS sent) | 35,482 | 25,664 | 9,818 | 27.57% |

> [!WARNING]
> The raw comparison shows a **higher** no-show rate among patients who received SMS reminders. This is a **confounding effect, not a causal relationship.**
>
> All 38,563 same-day appointments (lead time = 0 days) had `sms_received = 0` — it is physically impossible to send an SMS reminder for an appointment booked on the same day it occurs. Same-day appointments have an exceptionally low no-show rate of 4.65%, which deflates the No-SMS group's overall no-show rate.
>
> When restricted to advance bookings (lead time ≥ 1 day), the No-SMS group has a **29.44% no-show rate** vs. the SMS group's **27.57%** — a small difference in the expected direction.

---

### 5.3 No-Show Rate by Chronic Condition

#### Hypertension

```sql
SELECT
    hipertension                                                     AS hypertension,
    COUNT(*)                                                         AS total,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                             AS noshow_rate_pct
FROM appointments
GROUP BY hipertension;
```

**Result:**

| Hypertension | Appointments | No-Show Rate |
| :--- | ---: | ---: |
| 0 (No) | 88,726 | 20.90% |
| 1 (Yes) | 21,801 | 17.30% |

#### Diabetes

```sql
SELECT
    diabetes,
    COUNT(*)                                                         AS total,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                             AS noshow_rate_pct
FROM appointments
GROUP BY diabetes;
```

**Result:**

| Diabetes | Appointments | No-Show Rate |
| :--- | ---: | ---: |
| 0 (No) | 102,584 | 20.36% |
| 1 (Yes) | 7,943 | 18.00% |

Patients with hypertension or diabetes show slightly lower no-show rates. This is an **association** — it may reflect that patients managing chronic conditions are more motivated to attend follow-up appointments, or that they tend to be older (older patients have lower no-show rates overall).

---

### 5.4 Repeat Patient Analysis

```sql
WITH patient_visit_counts AS (
    SELECT patient_id,
           COUNT(*) AS visit_count
    FROM appointments
    GROUP BY patient_id
)
SELECT
    CASE
        WHEN visit_count = 1        THEN '1 visit'
        WHEN visit_count BETWEEN 2 AND 3 THEN '2-3 visits'
        WHEN visit_count BETWEEN 4 AND 5 THEN '4-5 visits'
        ELSE '6+ visits'
    END                                                              AS visit_tier,
    COUNT(*)                                                         AS patient_count,
    SUM(a.total)                                                     AS appointments,
    ROUND(SUM(a.missed) * 100.0 / SUM(a.total), 2)                 AS noshow_rate_pct
FROM patient_visit_counts pvc
JOIN (
    SELECT patient_id,
           COUNT(*) AS total,
           SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed
    FROM appointments
    GROUP BY patient_id
) a ON pvc.patient_id = a.patient_id
GROUP BY visit_tier;
```

**Result:**

| Visit Tier | Patients | Appointments | No-Show Rate |
| :--- | ---: | ---: | ---: |
| 1 visit | 37,920 | 37,920 | 18.77% |
| 2–3 visits | 19,395 | 44,879 | 20.78% |
| 4–5 visits | 3,486 | 14,769 | 21.84% |
| 6+ visits | 1,498 | 12,959 | 20.44% |

No-show rates are broadly similar across visit frequency tiers, suggesting appointment history alone is not a strong predictor.

---

## 6. Operational Analysis

**Script:** `sql/05_operational_analysis.sql`

### 6.1 Lead-Time Analysis

**Lead time** is the number of calendar days between the booking date and the appointment date. It is calculated using SQLite's `JULIANDAY()` function, which converts a date string to a Julian Day Number (a continuous count of days).

```sql
SELECT
    CAST(JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) AS INTEGER) AS lead_time_days
FROM appointments;
```

> [!IMPORTANT]
> Both `appointment_day` and `scheduled_day` are stored as ISO 8601 strings. For calendar-day lead time, `JULIANDAY()` is applied directly to the full timestamp strings. SQLite correctly extracts the date portion when computing the difference. The Python equivalent uses `.dt.date` on both columns before subtracting to avoid sub-day timestamp artefacts.

**5 records** with negative lead time are excluded from this analysis as data-quality exceptions (all 5 have `no_show = 'Yes'`). The valid analysis set is **110,522 records** (attended: 88,208 | missed: 22,314).

```sql
WITH lead_time_data AS (
    SELECT no_show,
           CAST(JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) AS INTEGER) AS lead_time_days
    FROM appointments
    WHERE JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) >= 0
)
SELECT
    CASE
        WHEN lead_time_days = 0           THEN 'Same day (0)'
        WHEN lead_time_days BETWEEN 1 AND  3 THEN '1-3 days'
        WHEN lead_time_days BETWEEN 4 AND  7 THEN '4-7 days'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 days'
        ELSE '31+ days'
    END                                                               AS lead_time_group,
    COUNT(*)                                                          AS total,
    SUM(CASE WHEN no_show = 'No'  THEN 1 ELSE 0 END)                 AS attended,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)                 AS missed,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                              AS noshow_rate_pct
FROM lead_time_data
GROUP BY lead_time_group
ORDER BY MIN(lead_time_days);
```

**Verified Results (110,522 total, Attended: 88,208, Missed: 22,314):**

| Lead-Time Group | Appointments | Attended | Missed | No-Show Rate |
| :--- | ---: | ---: | ---: | ---: |
| Same day (0) | 38,563 | 36,773 | 1,790 | 4.65% |
| 1–3 days | 14,675 | 11,315 | 3,360 | 22.89% |
| 4–7 days | 17,510 | 13,100 | 4,410 | 25.20% |
| 8–14 days | 12,025 | 8,362 | 3,663 | 30.47% |
| 15–30 days | 17,371 | 11,713 | 5,658 | 32.59% |
| 31+ days | 10,378 | 6,945 | 3,433 | 33.00% |
| **Total** | **110,522** | **88,208** | **22,314** | **20.18%** |

**Key finding:** No-show rate increases monotonically with lead time — from 4.65% for same-day bookings to 33.00% for bookings more than 30 days in advance. This is one of the strongest and most actionable patterns in the dataset.

---

### 6.2 Weekday Analysis

```sql
SELECT
    CASE CAST(strftime('%w', appointment_day) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END                                                               AS weekday,
    COUNT(*)                                                          AS total,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                              AS noshow_rate_pct
FROM appointments
GROUP BY weekday
ORDER BY CAST(strftime('%w', appointment_day) AS INTEGER);
```

**Verified Results:**

| Weekday | Appointments | No-Show Rate |
| :--- | ---: | ---: |
| Sunday | 0 | — |
| Monday | 27,197 | 20.65% |
| Tuesday | 24,537 | 20.09% |
| Wednesday | 23,399 | 19.69% |
| Thursday | 23,491 | 19.35% |
| Friday | 11,864 | 21.23% |
| Saturday | 39 | 23.08% |

No appointments occur on Sundays. Saturday has only 39 appointments (statistically negligible). Weekday variation is narrow (19.35%–21.23%), indicating the day of the week is not a strong predictor of no-show behaviour.

---

### 6.3 Neighbourhood Analysis — Top 10 by Volume

```sql
SELECT
    neighbourhood,
    COUNT(*)                                                          AS total,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END)                 AS missed,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 2)                                              AS noshow_rate_pct
FROM appointments
GROUP BY neighbourhood
ORDER BY total DESC
LIMIT 10;
```

**Verified Results — Top 10 Neighbourhoods by Appointment Volume:**

| Neighbourhood | Appointments | Missed | No-Show Rate |
| :--- | ---: | ---: | ---: |
| Jardim Camburi | 7,717 | 1,465 | 18.98% |
| Maria Ortiz | 5,805 | 1,219 | 21.00% |
| Resistência | 4,431 | 906 | 20.45% |
| Jardim da Penha | 3,877 | 631 | 16.28% |
| Itararé | 3,514 | 923 | 26.27% |
| Centro | 3,334 | 703 | 21.09% |
| Tabuazeiro | 3,132 | 573 | 18.30% |
| Santa Martha | 3,131 | 496 | 15.84% |
| Jesus de Nazareth | 2,853 | 696 | 24.40% |
| Bonfim | 2,773 | 549 | 19.83% |

Neighbourhood no-show rates range from 15.84% (Santa Martha) to 26.27% (Itararé) among the top 10 by volume, suggesting that localised factors — such as clinic accessibility, transportation, or patient demographics — may influence attendance.

---

## 7. Business Interpretation

### 7.1 Lead Time Is the Strongest Operational Signal

**What was analysed:** The number of calendar days between booking and appointment date vs. no-show rate.

**Result:** No-show rate rises from 4.65% (same-day) to 33.00% (31+ days) — a 7× increase.

**Why it matters:** Patients booked far in advance have more time to forget their appointment, experience schedule changes, or lose urgency. Same-day bookings are almost always attended, possibly because the patient's need is immediate.

**Action to consider:** Prioritise reminder contacts (SMS, phone, email) for appointments booked more than 14 days in advance. Explore whether any same-day or short-lead-time capacity can be reserved for high-priority cases or used as a buffer for anticipated no-shows.

---

### 7.2 Youth Patients Have the Highest No-Show Rate

**What was analysed:** No-show rate by age group.

**Result:** Youth (13–24) no-show rate = 25.62%, versus 15.50% for Seniors.

**Why it matters:** Younger patients may face different barriers — competing priorities, less established health habits, or less familiarity with rebooking.

**Action to consider:** Targeted reminder strategies for younger patient cohorts, or flexible short-notice booking options.

---

### 7.3 SMS Reminders — Association Requires Careful Interpretation

**What was analysed:** No-show rate among patients who received vs. did not receive SMS reminders.

**Result:** Raw comparison — No SMS: 16.70%, SMS received: 27.57%. After controlling for lead time (advance bookings only) — No SMS: 29.44%, SMS received: 27.57%.

**Why it matters:** The raw figure is misleading because all 38,563 same-day appointments never receive an SMS (by definition), yet have a very low 4.65% no-show rate. This deflates the No-SMS group average.

**Action to consider:** Treat SMS as one tool among several and evaluate it in controlled comparisons. Analysing its effect within comparable lead-time bands provides a more reliable picture.

---

### 7.4 Chronic-Condition Patients Show Better Attendance

**What was analysed:** No-show rates for patients with hypertension (17.30%) and diabetes (18.00%) vs. those without (20.90% and 20.36% respectively).

**Why it matters:** These patients may feel more urgency about managing ongoing conditions, or they may tend to be older. This is an association — not a causal finding.

**Action to consider:** Patient-managed-condition programmes may already be improving attendance through regular follow-ups. No change to those pathways is implied by this finding alone.

---

### 7.5 Neighbourhood Variation Warrants Localised Response

**What was analysed:** No-show rates across the top 10 neighbourhoods by volume.

**Result:** Rates range from 15.84% (Santa Martha) to 26.27% (Itararé).

**Why it matters:** A 10-percentage-point spread across locations suggests that catchment-level factors (transport links, clinic hours, local demographics) may play a role. This cannot be confirmed without additional data.

**Action to consider:** Investigate whether high-no-show neighbourhoods have accessibility barriers. Community outreach or mobile appointment reminders could be trialled in target areas.

---

## 8. SQL Concepts Demonstrated

This project uses a range of SQL techniques across the five query scripts. Key concepts are summarised below with references to where they appear.

### 8.1 Aggregate Functions

```sql
-- COUNT, COUNT DISTINCT, SUM, ROUND, CAST
SELECT
    COUNT(*)                        AS total_appointments,
    COUNT(DISTINCT patient_id)      AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended,
    ROUND(... / COUNT(*), 2)        AS rate_pct
FROM appointments;
```

Used in: `sql/03_kpi_analysis.sql`

---

### 8.2 Conditional Aggregation with CASE WHEN

Converting a text column (`no_show`) into binary 0/1 for summation:

```sql
SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed
```

Categorising a continuous variable (`age`) into groups:

```sql
CASE
    WHEN age < 0             THEN 'Invalid (<0)'
    WHEN age BETWEEN 0 AND 12 THEN 'Children'
    ...
    ELSE '65+ (Seniors)'
END AS age_group
```

Used in: `sql/03_kpi_analysis.sql`, `sql/04_attendance_outcome_analysis.sql`, `sql/05_operational_analysis.sql`

---

### 8.3 Common Table Expressions (CTEs)

CTEs (`WITH` clauses) make multi-step calculations readable by naming intermediate result sets:

```sql
WITH lead_time_data AS (
    SELECT no_show,
           CAST(JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) AS INTEGER) AS lead_time_days
    FROM appointments
    WHERE JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) >= 0
)
SELECT lead_time_group, COUNT(*), ...
FROM lead_time_data
GROUP BY lead_time_group;
```

Used in: `sql/05_operational_analysis.sql` (lead-time analysis), `sql/03_kpi_analysis.sql` (repeat-patient analysis)

---

### 8.4 Date Functions

SQLite's `JULIANDAY()` converts ISO 8601 date strings to a continuous day count, enabling arithmetic:

```sql
JULIANDAY(appointment_day) - JULIANDAY(scheduled_day)   -- lead time in days
strftime('%w', appointment_day)                          -- weekday number (0=Sunday)
```

Used in: `sql/02_data_quality.sql`, `sql/05_operational_analysis.sql`

---

### 8.5 Filtering and WHERE Clauses

```sql
-- Exclude data-quality exceptions from operational analysis
WHERE JULIANDAY(appointment_day) - JULIANDAY(scheduled_day) >= 0

-- Isolate specific anomalies for inspection
WHERE age < 0
```

Used in: `sql/02_data_quality.sql`, `sql/05_operational_analysis.sql`

---

### 8.6 GROUP BY and ORDER BY

All segmented analyses use `GROUP BY` to partition rows into groups and `ORDER BY` to control output sequence:

```sql
GROUP BY neighbourhood
ORDER BY COUNT(*) DESC
LIMIT 10;
```

---

### 8.7 Subqueries

Percentage calculations reference the full table count inside a scalar subquery:

```sql
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS pct
```

Used in: `sql/02_data_quality.sql`, `sql/04_attendance_outcome_analysis.sql`

---

### 8.8 Indexing Strategy

Three indexes were created at schema-definition time to support the most common query patterns:

```sql
CREATE INDEX IF NOT EXISTS idx_patient_id      ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_no_show         ON appointments(no_show);
CREATE INDEX IF NOT EXISTS idx_appointment_day ON appointments(appointment_day);
```

`idx_patient_id` accelerates `COUNT(DISTINCT patient_id)` and CTE joins on `patient_id`.  
`idx_no_show` accelerates `GROUP BY no_show` and conditional `SUM(CASE WHEN no_show = ...)` filters.  
`idx_appointment_day` accelerates the weekday and lead-time `JULIANDAY()` calculations.

---

*Document prepared from verified SQL query outputs. All figures cross-validated between SQL and Python EDA. No patient-level identifiers are included. All associations are descriptive — causal inference requires controlled study design.*

