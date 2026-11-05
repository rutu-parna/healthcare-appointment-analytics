"""
scripts/import_data.py
Project: Healthcare Appointment Access and Attendance Analysis

This script safely imports the Kaggle Medical Appointment No Shows dataset
(data/raw/KaggleV2-May-2016.csv) into the root SQLite database:
healthcare_analytics.db -> appointments table.

Safety checks:
1. Verifies that the raw CSV file exists.
2. Checks if the appointments table already has data before inserting (prevents accidental duplication).
3. Renames original dataset columns to clean snake_case database column names.
4. Uses Python's built-in sqlite3 library.
"""

from pathlib import Path
import sqlite3
import pandas as pd


def get_project_root() -> Path:
    """Returns the root directory of the health_data project."""
    # This file is in health_data/scripts/, so parent.parent is health_data/
    return Path(__file__).resolve().parent.parent


def import_dataset():
    project_root = get_project_root()
    raw_csv_path = project_root / "data" / "raw" / "KaggleV2-May-2016.csv"
    db_path = project_root / "healthcare_analytics.db"

    print("=" * 60)
    print("Healthcare Data Ingestion Pipeline")
    print("=" * 60)

    # 1. Verify CSV existence
    if not raw_csv_path.exists():
        print(f"[ERROR] Raw CSV file not found at:\n  {raw_csv_path}")
        print("\nPlease download 'KaggleV2-May-2016.csv' from Kaggle:")
        print("  https://www.kaggle.com/datasets/joniarroba/noshowappointments")
        print(f"and place it inside: {project_root / 'data' / 'raw'}\n")
        return

    # 2. Verify Database existence
    if not db_path.exists():
        print(f"[ERROR] Database file not found at:\n  {db_path}")
        print("Please ensure healthcare_analytics.db exists in the project root.")
        return

    # 3. Connect to SQLite database
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
    except sqlite3.Error as e:
        print(f"[ERROR] Could not connect to SQLite database: {e}")
        return

    try:
        # Check if 'appointments' table exists
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='appointments';"
        )
        table_exists = cursor.fetchone()

        if not table_exists:
            print("[INFO] Table 'appointments' does not exist yet. Creating table from sql/01_table_creation.sql...")
            schema_file = project_root / "sql" / "01_table_creation.sql"
            if schema_file.exists():
                with open(schema_file, "r", encoding="utf-8") as f:
                    cursor.executescript(f.read())
                conn.commit()
                print("[SUCCESS] Created 'appointments' table.")
            else:
                print(f"[ERROR] Schema file missing at {schema_file}. Cannot proceed.")
                return

        # Check existing row count to prevent duplicate insertions
        cursor.execute("SELECT COUNT(*) FROM appointments;")
        existing_count = cursor.fetchone()[0]

        if existing_count > 0:
            print(f"[NOTICE] The 'appointments' table already contains {existing_count:,} records.")
            print("Import aborted to prevent duplicate records.")
            print("If you wish to re-import, please inspect or truncate the table manually first.")
            return

        # 4. Load CSV using pandas
        print(f"[INFO] Reading CSV from: {raw_csv_path.name}...")
        df = pd.read_csv(raw_csv_path, dtype={"PatientId": "string"})
        print(f"[INFO] Loaded {len(df):,} rows and {len(df.columns)} columns from CSV.")

        # 5. Rename columns to consistent snake_case naming
        column_mapping = {
            "PatientId": "patient_id",
            "AppointmentID": "appointment_id",
            "Gender": "gender",
            "ScheduledDay": "scheduled_day",
            "AppointmentDay": "appointment_day",
            "Age": "age",
            "Neighbourhood": "neighbourhood",
            "Scholarship": "scholarship",
            "Hipertension": "hipertension",
            "Diabetes": "diabetes",
            "Alcoholism": "alcoholism",
            "Handcap": "handcap",
            "SMS_received": "sms_received",
            "No-show": "no_show",
        }

        # Validate that all expected columns are present
        missing_columns = [col for col in column_mapping.keys() if col not in df.columns]
        if missing_columns:
            print(f"[ERROR] CSV is missing expected columns: {missing_columns}")
            return

        df = df.rename(columns=column_mapping)

        # Ensure correct data types before loading into SQLite
        # patient_id remains exact string to preserve all identifier digits
        df["patient_id"] = df["patient_id"].astype("string")
        df["appointment_id"] = df["appointment_id"].astype("int64")

        # Select only the target columns in correct order
        df = df[list(column_mapping.values())]

        # 6. Insert data into SQLite
        print("[INFO] Inserting records into 'appointments' table...")
        df.to_sql("appointments", conn, if_exists="append", index=False)

        # 7. Confirm row count
        cursor.execute("SELECT COUNT(*) FROM appointments;")
        final_count = cursor.fetchone()[0]

        print("=" * 60)
        print(f"[SUCCESS] Ingestion complete!")
        print(f"Total records in 'appointments' table: {final_count:,}")
        print("=" * 60)

    except sqlite3.Error as e:
        print(f"[ERROR] Database operation failed: {e}")
        conn.rollback()
    except Exception as e:
        print(f"[ERROR] Unexpected error occurred: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    import_dataset()

