-- ==============================================================================
-- 05_operational_analysis.sql
-- Project: Healthcare Appointment Access and Attendance Analysis
-- Purpose: Operational analysis examining appointment lead time (lag between
--          booking date and appointment date), day-of-week demand patterns,
--          clinic location distribution, and repeat patient attendance.
-- Note: Uses SQLite date functions (JULIANDAY, DATE, STRFTIME).
-- ==============================================================================

-- 1. Appointment Scheduling Lead Time (in days) Summary Statistics
-- Lead time = difference in days between appointment date and booking date
WITH lead_time_calc AS (
    SELECT
        appointment_id,
        no_show,
        CAST(JULIANDAY(DATE(appointment_day)) - JULIANDAY(DATE(scheduled_day)) AS INTEGER) AS lead_time_days
    FROM appointments
)
SELECT
    COUNT(*) AS total_appointments,
    MIN(lead_time_days) AS min_lead_time_days,
    MAX(lead_time_days) AS max_lead_time_days,
    ROUND(AVG(lead_time_days), 1) AS avg_lead_time_days,
    ROUND(AVG(CASE WHEN no_show = 'No' THEN lead_time_days END), 1) AS avg_lead_time_attended,
    ROUND(AVG(CASE WHEN no_show = 'Yes' THEN lead_time_days END), 1) AS avg_lead_time_missed
FROM lead_time_calc
WHERE lead_time_days >= 0; -- Exclude negative date anomalies if any exist

-- 2. Lead-Time Buckets vs Attendance Outcomes
WITH lead_time_calc AS (
    SELECT
        appointment_id,
        no_show,
        CAST(JULIANDAY(DATE(appointment_day)) - JULIANDAY(DATE(scheduled_day)) AS INTEGER) AS lead_time_days
    FROM appointments
)
SELECT
    CASE
        WHEN lead_time_days < 0 THEN 'Invalid (< 0 days)'
        WHEN lead_time_days = 0 THEN '0 Days (Same Day)'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN '1-3 Days (Short)'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 Days (1 Week)'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 Days (2 Weeks)'
        WHEN lead_time_days BETWEEN 15 AND 30 THEN '15-30 Days (1 Month)'
        ELSE '31+ Days (Long Horizon)'
    END AS lead_time_category,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_count,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_count,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM lead_time_calc
GROUP BY lead_time_category
ORDER BY MIN(lead_time_days);

-- 3. Weekday-Wise Appointment Volume and No-Show Rates
-- SQLite strftime('%w', ...) returns 0 for Sunday, 1 for Monday, ..., 6 for Saturday
SELECT
    STRFTIME('%w', appointment_day) AS weekday_num,
    CASE STRFTIME('%w', appointment_day)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END AS weekday_name,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_count,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_count,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM appointments
GROUP BY weekday_num, weekday_name
ORDER BY weekday_num;

-- 4. Neighbourhood-Wise Attendance Patterns (Top 15 Clinics by Volume)
SELECT
    neighbourhood,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_count,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_count,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM appointments
GROUP BY neighbourhood
HAVING COUNT(*) >= 500
ORDER BY total_appointments DESC
LIMIT 15;

-- 5. Interaction Between Lead Time and SMS Reminder
WITH lead_time_calc AS (
    SELECT
        appointment_id,
        sms_received,
        no_show,
        CAST(JULIANDAY(DATE(appointment_day)) - JULIANDAY(DATE(scheduled_day)) AS INTEGER) AS lead_time_days
    FROM appointments
)
SELECT
    CASE 
        WHEN lead_time_days = 0 THEN 'Same Day (0d)'
        WHEN lead_time_days BETWEEN 1 AND 7 THEN '1-7 Days'
        ELSE '8+ Days'
    END AS lead_time_tier,
    CASE WHEN sms_received = 1 THEN 'SMS Sent' ELSE 'No SMS' END AS reminder_status,
    COUNT(*) AS appointment_count,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM lead_time_calc
WHERE lead_time_days >= 0
GROUP BY lead_time_tier, reminder_status
ORDER BY lead_time_tier, reminder_status;

-- 6. Repeat Patient Attendance Patterns
WITH patient_visit_counts AS (
    SELECT
        patient_id,
        COUNT(*) AS total_visits,
        SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_visits
    FROM appointments
    GROUP BY patient_id
),
patient_tiers AS (
    SELECT
        patient_id,
        total_visits,
        missed_visits,
        CASE
            WHEN total_visits = 1 THEN '1 Visit (Single Visit)'
            WHEN total_visits BETWEEN 2 AND 3 THEN '2-3 Visits'
            WHEN total_visits BETWEEN 4 AND 5 THEN '4-5 Visits'
            ELSE '6+ Visits (Frequent Patients)'
        END AS patient_frequency_tier
    FROM patient_visit_counts
)
SELECT
    patient_frequency_tier,
    COUNT(*) AS patient_count,
    SUM(total_visits) AS total_appointments_booked,
    SUM(missed_visits) AS total_appointments_missed,
    ROUND(100.0 * SUM(missed_visits) / SUM(total_visits), 2) AS tier_no_show_rate_pct
FROM patient_tiers
GROUP BY patient_frequency_tier
ORDER BY MIN(total_visits);

