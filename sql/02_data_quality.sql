-- ==============================================================================
-- 02_data_quality.sql
-- Project: Healthcare Appointment Access and Attendance Analysis
-- Purpose: Data quality audit queries to inspect data health, completeness,
--          and anomalies without modifying or deleting any underlying records.
-- ==============================================================================

-- 1. Total row count in appointments table
SELECT COUNT(*) AS total_records
FROM appointments;

-- 2. Check for duplicate appointment_id values (Primary Key integrity)
SELECT 
    appointment_id, 
    COUNT(*) AS occurrence_count
FROM appointments
GROUP BY appointment_id
HAVING COUNT(*) > 1;

-- 3. Check for NULL or missing values across all critical columns
SELECT
    SUM(CASE WHEN appointment_id IS NULL THEN 1 ELSE 0 END) AS null_appointment_ids,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS null_patient_ids,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_genders,
    SUM(CASE WHEN scheduled_day IS NULL THEN 1 ELSE 0 END) AS null_scheduled_days,
    SUM(CASE WHEN appointment_day IS NULL THEN 1 ELSE 0 END) AS null_appointment_days,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_ages,
    SUM(CASE WHEN neighbourhood IS NULL THEN 1 ELSE 0 END) AS null_neighbourhoods,
    SUM(CASE WHEN scholarship IS NULL THEN 1 ELSE 0 END) AS null_scholarships,
    SUM(CASE WHEN hipertension IS NULL THEN 1 ELSE 0 END) AS null_hipertension,
    SUM(CASE WHEN diabetes IS NULL THEN 1 ELSE 0 END) AS null_diabetes,
    SUM(CASE WHEN alcoholism IS NULL THEN 1 ELSE 0 END) AS null_alcoholism,
    SUM(CASE WHEN handcap IS NULL THEN 1 ELSE 0 END) AS null_handcap,
    SUM(CASE WHEN sms_received IS NULL THEN 1 ELSE 0 END) AS null_sms_received,
    SUM(CASE WHEN no_show IS NULL THEN 1 ELSE 0 END) AS null_no_shows
FROM appointments;

-- 4. Check for invalid or unusual age values (e.g. negative ages or age > 115)
SELECT 
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    AVG(age) AS avg_age,
    COUNT(CASE WHEN age < 0 THEN 1 END) AS negative_age_count,
    COUNT(CASE WHEN age > 105 THEN 1 END) AS extreme_elderly_count
FROM appointments;

-- Details of records with invalid age (< 0)
SELECT *
FROM appointments
WHERE age < 0;

-- 5. Check distinct values and distribution for categorical columns
-- 5a. Gender distinct values
SELECT gender, COUNT(*) AS count
FROM appointments
GROUP BY gender;

-- 5b. No-show outcome distinct values
SELECT no_show, COUNT(*) AS count
FROM appointments
GROUP BY no_show;

-- 5c. Scholarship binary flag check
SELECT scholarship, COUNT(*) AS count
FROM appointments
GROUP BY scholarship;

-- 5d. Medical condition flag checks
SELECT hipertension, COUNT(*) AS count FROM appointments GROUP BY hipertension;
SELECT diabetes, COUNT(*) AS count FROM appointments GROUP BY diabetes;
SELECT alcoholism, COUNT(*) AS count FROM appointments GROUP BY alcoholism;
SELECT handcap, COUNT(*) AS count FROM appointments GROUP BY handcap;
SELECT sms_received, COUNT(*) AS count FROM appointments GROUP BY sms_received;

-- 6. Date field format and consistency checks
-- 6a. Sample date string values to verify format
SELECT 
    scheduled_day, 
    appointment_day, 
    DATE(scheduled_day) AS scheduled_date, 
    DATE(appointment_day) AS appointment_date
FROM appointments
LIMIT 10;

-- 6b. Check for illogical date sequences (scheduled date occurring AFTER appointment date)
SELECT 
    COUNT(*) AS illogical_date_count
FROM appointments
WHERE DATE(scheduled_day) > DATE(appointment_day);

