-- ==============================================================================
-- 01_table_creation.sql
-- Project: Healthcare Appointment Access and Attendance Analysis
-- Purpose: Creates the schema for the 'appointments' table in SQLite.
-- ==============================================================================

-- Create the appointments table with appropriate SQLite data types
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id      INTEGER PRIMARY KEY, -- Unique appointment identifier (Primary Key)
    patient_id          TEXT NOT NULL,       -- Unique patient identifier (a patient can have multiple appointments)
    gender              TEXT NOT NULL,       -- Gender of the patient ('M' or 'F')
    scheduled_day       TEXT NOT NULL,       -- Date and time when the appointment was scheduled/booked
    appointment_day     TEXT NOT NULL,       -- Date of the actual appointment
    age                 INTEGER NOT NULL,    -- Patient age in years
    neighbourhood       TEXT NOT NULL,       -- District or neighbourhood where the appointment took place
    scholarship         INTEGER NOT NULL,    -- Bolsa Família welfare program: 1 = enrolled, 0 = not enrolled
    hipertension        INTEGER NOT NULL,    -- Hypertension condition: 1 = diagnosed, 0 = none
    diabetes            INTEGER NOT NULL,    -- Diabetes condition: 1 = diagnosed, 0 = none
    alcoholism          INTEGER NOT NULL,    -- Alcoholism condition: 1 = diagnosed, 0 = none
    handcap             INTEGER NOT NULL,    -- Handicap status: 0 = none, 1-4 = handicap scale/conditions
    sms_received        INTEGER NOT NULL,    -- SMS reminder flag: 1 = reminder sent, 0 = no reminder sent
    no_show             TEXT NOT NULL        -- Attendance status: 'No' = Patient attended, 'Yes' = Patient missed appointment
);

-- Create indexes on frequently queried columns to improve query performance
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_appointment_day ON appointments(appointment_day);
CREATE INDEX IF NOT EXISTS idx_appointments_no_show ON appointments(no_show);

