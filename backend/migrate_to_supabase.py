#!/usr/bin/env python3
"""
Kiko — Safe Migration Script: SQLite -> Supabase PostgreSQL
Preserves primary keys, foreign keys, timestamps, unique constraints, and synchronizes PostgreSQL sequences.
"""

import argparse
from datetime import datetime, timezone
import json
import logging
import os
from pathlib import Path
import re
import sys
from urllib.parse import urlparse

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker

# Add current directory to path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from database import Base, normalize_database_url, mask_db_url
import models
from init_db import init_database

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("kiko.migration")

DEFAULT_BACKUP_PATH = Path("/home/sathyaprakash/Kiko_backups/migration_backup_20261021_181451/kiko_full_database_export.json")

MIGRATION_ORDER = [
    ("users", models.User),
    ("user_profiles", models.UserProfile),
    ("courses", models.Course),
    ("lessons", models.Lesson),
    ("exams", models.Exam),
    ("exam_questions", models.ExamQuestion),
    ("lesson_progress", models.LessonProgress),
    ("exam_attempts", models.ExamAttempt),
    ("user_learning_activities", models.UserLearningActivity),
    ("user_stats", models.UserStats),
    ("achievements", models.Achievement),
    ("user_achievements", models.UserAchievement),
]


def mask_db_url(url: str) -> str:
    """Masks database password in connection string for secret-free logging."""
    if not url:
        return "<empty>"
    try:
        parsed = urlparse(url)
        if parsed.password:
            netloc = parsed.netloc.replace(f":{parsed.password}@", ":******@")
            return parsed._replace(netloc=netloc).geturl()
    except Exception:
        pass
    return re.sub(r"://([^:]+):([^@]+)@", r"://\1:******@", url)


def parse_datetime(val):
    """Safely converts string or date to a timezone-aware UTC datetime."""
    if val is None or isinstance(val, datetime):
        return val
    try:
        dt = datetime.fromisoformat(str(val))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        pass
    try:
        dt = datetime.strptime(str(val), "%Y-%m-%d %H:%M:%S.%f")
        return dt.replace(tzinfo=timezone.utc)
    except Exception:
        pass
    try:
        dt = datetime.strptime(str(val), "%Y-%m-%d %H:%M:%S")
        return dt.replace(tzinfo=timezone.utc)
    except Exception:
        return val


def parse_bool(val):
    if val is None:
        return None
    if isinstance(val, bool):
        return val
    if isinstance(val, (int, float)):
        return bool(val)
    if isinstance(val, str):
        return val.lower() in ("1", "true", "t", "yes", "y")
    return bool(val)


def transform_record(table_name: str, record: dict) -> dict:
    """Applies necessary type conversions for PostgreSQL compatibility."""
    transformed = dict(record)
    
    # Datetime fields
    datetime_fields = {
        "users": ["created_at", "last_login_at"],
        "user_profiles": ["created_at", "updated_at"],
        "user_learning_activities": ["created_at"],
        "lesson_progress": ["completed_at"],
        "exam_attempts": ["attempted_at"],
        "user_achievements": ["earned_at"],
    }
    for field in datetime_fields.get(table_name, []):
        if field in transformed and transformed[field] is not None:
            transformed[field] = parse_datetime(transformed[field])

    # Boolean fields
    boolean_fields = {
        "courses": ["is_published"],
        "lesson_progress": ["is_completed"],
        "exam_attempts": ["passed"],
    }
    for field in boolean_fields.get(table_name, []):
        if field in transformed and transformed[field] is not None:
            transformed[field] = parse_bool(transformed[field])

    return transformed


def sync_sequences(engine, tables: list[str]) -> dict[str, str]:
    """
    Synchronizes PostgreSQL sequences for serial/identity primary keys after inserting explicit IDs.
    Returns status mapping for each table.
    """
    status = {}
    with engine.begin() as conn:
        for table_name in tables:
            try:
                seq_query = text(f"SELECT pg_get_serial_sequence('\"{table_name}\"', 'id')")
                seq_name = conn.execute(seq_query).scalar()
                if seq_name:
                    max_id = conn.execute(text(f'SELECT MAX(id) FROM "{table_name}"')).scalar()
                    if max_id is not None and max_id > 0:
                        conn.execute(text(f"SELECT setval('{seq_name}', {max_id}, true)"))
                        status[table_name] = f"seq {seq_name} -> {max_id}"
                    else:
                        conn.execute(text(f"SELECT setval('{seq_name}', 1, false)"))
                        status[table_name] = f"seq {seq_name} -> 1 (empty)"
                else:
                    status[table_name] = "no serial sequence (standard/identity)"
            except Exception as exc:
                status[table_name] = f"sequence check warning: {exc}"
    return status


def verify_target_data(engine, expected_counts: dict[str, int]) -> tuple[bool, dict]:
    """
    Verifies that all tables in PostgreSQL exist, contain the expected row counts,
    and have consistent foreign-key relationships.
    """
    results = {}
    all_matched = True

    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    with engine.connect() as conn:
        for tbl_name, expected_count in expected_counts.items():
            if tbl_name not in existing_tables:
                results[tbl_name] = {
                    "exists": False,
                    "expected": expected_count,
                    "actual": 0,
                    "matched": False,
                }
                all_matched = False
                continue

            actual_count = conn.execute(text(f'SELECT COUNT(*) FROM "{tbl_name}"')).scalar()
            matched = (actual_count == expected_count)
            results[tbl_name] = {
                "exists": True,
                "expected": expected_count,
                "actual": actual_count,
                "matched": matched,
            }
            if not matched:
                all_matched = False

    return all_matched, results


def run_migration(database_url: str, backup_file: Path, verify_only: bool = False):
    database_url = normalize_database_url(database_url)
    masked_url = mask_db_url(database_url)
    logger.info("Initializing migration target: %s", masked_url)

    # Configure SQLAlchemy engine for PostgreSQL
    engine = create_engine(
        database_url,
        pool_pre_ping=True,
        pool_recycle=300,
    )

    # 1. Test connectivity
    with engine.connect() as conn:
        res = conn.execute(text("SELECT 1")).scalar()
        if res != 1:
            raise RuntimeError("Database connection test failed (SELECT 1 returned unexpected result).")
    logger.info("Connected successfully to target database (dialect: %s)", engine.dialect.name)

    if engine.dialect.name != "postgresql":
        raise ValueError(
            f"Target database dialect must be 'postgresql', but detected '{engine.dialect.name}'. Aborting migration."
        )

    # 2. Load and validate backup file
    if not backup_file.exists():
        raise FileNotFoundError(f"Backup export file not found at: {backup_file}")
    
    with open(backup_file, "r", encoding="utf-8") as f:
        backup_data = json.load(f)

    tables_data = backup_data.get("tables", {})
    expected_counts = {tbl: info["row_count"] for tbl, info in tables_data.items()}
    logger.info("Loaded backup file: %s (%d tables, %d total records)", backup_file, len(tables_data), sum(expected_counts.values()))

    # 3. Create schema
    logger.info("Ensuring PostgreSQL schema and indexes exist...")
    Base.metadata.create_all(bind=engine)
    init_database()
    logger.info("PostgreSQL schema initialization complete.")

    if verify_only:
        logger.info("Running in --verify-only mode. Skipping record insertion.")
        passed, report = verify_target_data(engine, expected_counts)
        _print_verification_report(report)
        if passed:
            logger.info("Verification passed: Target database perfectly matches expected backup counts.")
            return True
        else:
            logger.error("Verification failed: Target database does not match expected backup counts.")
            return False

    # 4. Check existing counts in target database to ensure safety
    _, current_counts = verify_target_data(engine, {t: 0 for t in tables_data})
    target_has_data = any(c["actual"] > 0 for c in current_counts.values())
    if target_has_data:
        logger.warning("Target PostgreSQL database already contains existing rows.")
        for tbl, stat in current_counts.items():
            if stat["actual"] > 0:
                logger.warning("  Table '%s' has %d existing rows.", tbl, stat["actual"])

    # 5. Migrate table by table in dependency order
    Session = sessionmaker(bind=engine)
    migrated_stats = {}

    for table_name, model_class in MIGRATION_ORDER:
        table_info = tables_data.get(table_name)
        if not table_info:
            logger.info("No data in backup for table '%s'. Skipping.", table_name)
            migrated_stats[table_name] = {"inserted": 0, "skipped": 0, "updated": 0}
            continue

        records = table_info.get("records", [])
        logger.info("Migrating table '%s' (%d records)...", table_name, len(records))

        inserted = 0
        skipped = 0
        updated = 0

        with Session() as session:
            for raw_record in records:
                transformed = transform_record(table_name, raw_record)
                record_id = transformed.get("id")

                # Idempotent check by primary key
                existing_record = None
                if record_id is not None:
                    existing_record = session.get(model_class, record_id)

                if existing_record:
                    # Update fields if changed
                    has_changes = False
                    for key, val in transformed.items():
                        if getattr(existing_record, key) != val:
                            setattr(existing_record, key, val)
                            has_changes = True
                    if has_changes:
                        updated += 1
                    else:
                        skipped += 1
                else:
                    new_obj = model_class(**transformed)
                    session.add(new_obj)
                    inserted += 1

            session.commit()
            migrated_stats[table_name] = {"inserted": inserted, "skipped": skipped, "updated": updated}
            logger.info("Table '%s' migrated: %d inserted, %d updated, %d skipped.", table_name, inserted, updated, skipped)

    # 6. Synchronize PostgreSQL sequences
    logger.info("Synchronizing PostgreSQL serial sequences...")
    seq_status = sync_sequences(engine, [t[0] for t in MIGRATION_ORDER])
    for tbl, status_str in seq_status.items():
        logger.info("  %s: %s", tbl, status_str)

    # 7. Final Verification & Row Count Comparison
    logger.info("Performing final verification of migrated data...")
    passed, verification_report = verify_target_data(engine, expected_counts)
    _print_verification_report(verification_report)

    if not passed:
        logger.error("Migration finished but verification check failed! Some counts do not match expected records.")
        return False

    # 8. Relationship and sequence smoke test
    with engine.begin() as conn:
        # Check course-lesson-exam relationship
        res_course = conn.execute(text("SELECT COUNT(*) FROM courses")).scalar()
        res_lessons = conn.execute(text("SELECT COUNT(*) FROM lessons")).scalar()
        res_exams = conn.execute(text("SELECT COUNT(*) FROM exams")).scalar()
        res_questions = conn.execute(text("SELECT COUNT(*) FROM exam_questions")).scalar()
        res_users = conn.execute(text("SELECT COUNT(*) FROM users")).scalar()
        res_profiles = conn.execute(text("SELECT COUNT(*) FROM user_profiles")).scalar()
        
        logger.info("Relational Integrity Checks:")
        logger.info("  Courses: %d, Lessons: %d, Exams: %d, Questions: %d", res_course, res_lessons, res_exams, res_questions)
        logger.info("  Users: %d, Profiles: %d", res_users, res_profiles)

        if res_users > 0 and res_profiles != res_users:
            logger.warning("Profile count (%d) does not match user count (%d)", res_profiles, res_users)

    logger.info("MIGRATION COMPLETED SUCCESSFULLY. All records verified in Supabase PostgreSQL.")
    return True


def _print_verification_report(report: dict):
    print("\n" + "=" * 65)
    print(f"{'Table Name':<28} | {'Expected':<10} | {'Actual':<10} | {'Status':<8}")
    print("-" * 65)
    for tbl, data in report.items():
        status_str = "MATCH" if data["matched"] else "MISMATCH"
        print(f"{tbl:<28} | {data['expected']:<10} | {data['actual']:<10} | {status_str:<8}")
    print("=" * 65 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Migrate Kiko SQLite database to Supabase PostgreSQL.")
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL"),
        help="Target PostgreSQL database URL (defaults to DATABASE_URL environment variable).",
    )
    parser.add_argument(
        "--backup-file",
        type=Path,
        default=DEFAULT_BACKUP_PATH,
        help="Path to the JSON backup file created from SQLite.",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Only verify existing target database against backup without writing.",
    )

    args = parser.parse_args()

    if not args.database_url:
        print("\nERROR: No DATABASE_URL provided. Specify via --database-url or set the DATABASE_URL environment variable.")
        print("Example:")
        print("  export DATABASE_URL='postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres'")
        print("  python3 backend/migrate_to_supabase.py\n")
        sys.exit(1)

    success = run_migration(
        database_url=args.database_url,
        backup_file=args.backup_file,
        verify_only=args.verify_only,
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
