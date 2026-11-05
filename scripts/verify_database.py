"""
scripts/verify_database.py
Project: Healthcare Appointment Access and Attendance Analysis

This utility script verifies the state of the SQLite database:
1. Connects to healthcare_analytics.db in the project root.
2. Checks whether the 'appointments' table exists.
3. Prints the total record count.
4. Lists all column names and data types.
5. Displays a small 5-row sample for local verification.
"""

from pathlib import Path
import sqlite3


def get_project_root() -> Path:
    """Returns the root directory of the health_data project."""
    return Path(__file__).resolve().parent.parent


def verify_database():
    project_root = get_project_root()
    db_path = project_root / "healthcare_analytics.db"

    print("=" * 60)
    print("Database Verification Utility")
    print("=" * 60)

    if not db_path.exists():
        print(f"[ERROR] Database file not found at:\n  {db_path}")
        return

    print(f"[INFO] Connecting to database: {db_path.name}")

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # 1. Check if 'appointments' table exists
        cursor.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='appointments';"
        )
        table_exists = cursor.fetchone()

        if not table_exists:
            print("[STATUS] Table 'appointments' does NOT exist yet in the database.")
            print("Next step: Run 'sql/01_table_creation.sql' or execute 'scripts/import_data.py'.")
            return

        print("[STATUS] Table 'appointments' found successfully.")

        # 2. Get table column details (PRAGMA table_info)
        cursor.execute("PRAGMA table_info(appointments);")
        columns = cursor.fetchall()
        print("\n--- Table Columns Schema ---")
        for col in columns:
            cid, col_name, col_type, not_null, default_val, is_pk = col
            pk_label = " [PRIMARY KEY]" if is_pk else ""
            print(f" - {col_name:18} {col_type:10} (NotNull={bool(not_null)}){pk_label}")

        # 3. Get total row count
        cursor.execute("SELECT COUNT(*) FROM appointments;")
        total_rows = cursor.fetchone()[0]
        print(f"\n--- Record Count ---")
        print(f"Total appointments stored: {total_rows:,}")

        if total_rows == 0:
            print("[INFO] Table is currently empty. Run 'scripts/import_data.py' once CSV is available.")
            return

        # 4. Display a small sample (5 records) for local inspection
        print(f"\n--- Sample Records (First 5 Rows) ---")
        cursor.execute("SELECT * FROM appointments LIMIT 5;")
        sample_rows = cursor.fetchall()
        col_names = [col[1] for col in columns]

        for i, row in enumerate(sample_rows, start=1):
            print(f"\n[Record #{i}]")
            for col_name, value in zip(col_names, row):
                print(f"  {col_name:18}: {value}")

        print("\n" + "=" * 60)
        print("[SUCCESS] Database verification completed.")
        print("=" * 60)

    except sqlite3.Error as e:
        print(f"[ERROR] Database error during verification: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    verify_database()

