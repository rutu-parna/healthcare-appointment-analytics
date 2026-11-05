-- ==============================================================================
-- 03_kpi_analysis.sql
-- Project: Healthcare Appointment Access and Attendance Analysis
-- Purpose: Computes core Key Performance Indicators (KPIs) including overall
--          volume, unique patients, attendance and no-show rates, and segmentations
--          by gender, age bracket, and month.
-- ==============================================================================

-- 1. High-Level Portfolio KPIs: Total volume, unique patients, attendance, and no-shows
SELECT
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct,
    ROUND(1.0 * COUNT(*) / COUNT(DISTINCT patient_id), 2) AS avg_appointments_per_patient
FROM appointments;

-- 2. Gender-Wise Appointment Statistics
SELECT
    gender,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM appointments
GROUP BY gender;

-- 3. Age-Group-Wise Appointment Statistics
-- Categories: 0-12 (Children), 13-24 (Youth), 25-44 (Adults), 45-64 (Middle-Aged), 65+ (Seniors)
SELECT
    CASE 
        WHEN age < 0 THEN 'Invalid (<0)'
        WHEN age BETWEEN 0 AND 12 THEN '0-12 (Children)'
        WHEN age BETWEEN 13 AND 24 THEN '13-24 (Youth)'
        WHEN age BETWEEN 25 AND 44 THEN '25-44 (Young Adults)'
        WHEN age BETWEEN 45 AND 64 THEN '45-64 (Middle-Aged Adults)'
        ELSE '65+ (Seniors)'
    END AS age_group,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM appointments
GROUP BY age_group
ORDER BY MIN(age);

-- 4. Monthly Appointment Statistics (based on appointment_day date)
SELECT
    STRFTIME('%Y-%m', appointment_day) AS appointment_month,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) AS attended_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS missed_appointments,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS attendance_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS no_show_rate_pct
FROM appointments
GROUP BY appointment_month
ORDER BY appointment_month;

