-- ==============================================================================
-- 04_attendance_outcome_analysis.sql
-- Project: Healthcare Appointment Access and Attendance Analysis
-- Purpose: Examines appointment outcome distributions (Attended vs. Missed)
--          across key segments: overall, age groups, neighbourhoods, and
--          SMS reminder status.
-- Note: This is an outcome split of booked appointments, not a sales or conversion funnel.
-- ==============================================================================

-- 1. Overall Appointment Outcome Split
SELECT
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments;

-- 2. Outcome Split by Age Group
SELECT
    CASE 
        WHEN age < 0 THEN 'Invalid (<0)'
        WHEN age BETWEEN 0 AND 12 THEN '0-12 (Children)'
        WHEN age BETWEEN 13 AND 24 THEN '13-24 (Youth)'
        WHEN age BETWEEN 25 AND 44 THEN '25-44 (Young Adults)'
        WHEN age BETWEEN 45 AND 64 THEN '45-64 (Middle-Aged Adults)'
        ELSE '65+ (Seniors)'
    END AS age_group,
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments
GROUP BY age_group
ORDER BY scheduled_appointments DESC;

-- 3. Outcome Split by SMS Reminder Status
SELECT
    CASE WHEN sms_received = 1 THEN 'SMS Received' ELSE 'No SMS Received' END AS sms_status,
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments
GROUP BY sms_received;

-- 4. Outcome Split by Neighbourhood (Top 20 neighbourhoods by appointment volume)
SELECT
    neighbourhood,
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments
GROUP BY neighbourhood
ORDER BY scheduled_appointments DESC
LIMIT 20;

-- 5. Outcome Split by Health Condition (Hypertension, Diabetes, Alcoholism)
SELECT
    'Hypertension' AS condition_name,
    hipertension AS condition_flag,
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments
GROUP BY hipertension

UNION ALL

SELECT
    'Diabetes' AS condition_name,
    diabetes AS condition_flag,
    COUNT(*) AS scheduled_appointments,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_pct
FROM appointments
GROUP BY diabetes;

