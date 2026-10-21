import logging
from sqlalchemy import inspect, text
from database import Base, engine, DEFAULT_DB_PATH
import models

logger = logging.getLogger("kiko.init_db")


def migrate_columns():
    """Safely adds missing nullable columns to existing tables without data loss across both SQLite and PostgreSQL."""
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    is_pg = engine.dialect.name == "postgresql"
    dt_type = "TIMESTAMP WITH TIME ZONE" if is_pg else "DATETIME"

    with engine.begin() as conn:
        # Check users table
        if "users" in existing_tables:
            columns = {col["name"] for col in inspector.get_columns("users")}
            if "created_at" not in columns:
                conn.execute(text(f"ALTER TABLE users ADD COLUMN created_at {dt_type}"))
                logger.info("Migrated: Added 'created_at' column to 'users' table.")
            if "last_login_at" not in columns:
                conn.execute(text(f"ALTER TABLE users ADD COLUMN last_login_at {dt_type}"))
                logger.info("Migrated: Added 'last_login_at' column to 'users' table.")

        # Check lesson_progress table
        if "lesson_progress" in existing_tables:
            columns = {col["name"] for col in inspector.get_columns("lesson_progress")}
            if "completed_at" not in columns:
                conn.execute(text(f"ALTER TABLE lesson_progress ADD COLUMN completed_at {dt_type}"))
                logger.info("Migrated: Added 'completed_at' column to 'lesson_progress' table.")

        # Check exams table
        if "exams" in existing_tables:
            columns = {col["name"] for col in inspector.get_columns("exams")}
            if "course_id" not in columns:
                conn.execute(text("ALTER TABLE exams ADD COLUMN course_id INTEGER REFERENCES courses(id)"))
                logger.info("Migrated: Added 'course_id' column to 'exams' table.")

        # Check exam_attempts table
        if "exam_attempts" in existing_tables:
            columns = {col["name"] for col in inspector.get_columns("exam_attempts")}
            if "answers_summary" not in columns:
                conn.execute(text("ALTER TABLE exam_attempts ADD COLUMN answers_summary TEXT"))
                logger.info("Migrated: Added 'answers_summary' column to 'exam_attempts' table.")


def migrate_constraints_and_indexes():
    """
    Safely adds performance indexes and updates constraints without data loss.
    Avoids running SQLite-specific PRAGMA or sqlite_master statements against PostgreSQL.
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    is_pg = engine.dialect.name == "postgresql"
    is_sqlite = engine.dialect.name == "sqlite"

    with engine.begin() as conn:
        # 1. Add performance indexes for foreign keys & common queries
        indexes_to_create = [
            ("ix_exam_attempts_user_id", "exam_attempts", "user_id"),
            ("ix_exam_attempts_exam_id", "exam_attempts", "exam_id"),
            ("ix_exam_questions_exam_id", "exam_questions", "exam_id"),
            ("ix_lessons_course_id", "lessons", "course_id"),
        ]
        for idx_name, tbl_name, col_name in indexes_to_create:
            if tbl_name in existing_tables:
                existing_indices = {idx["name"] for idx in inspector.get_indexes(tbl_name)}
                if idx_name not in existing_indices:
                    conn.execute(text(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {tbl_name} ({col_name})"))

        # 2. SQLite-specific constraint migration for user_learning_activities
        if is_sqlite and "user_learning_activities" in existing_tables:
            res = conn.execute(
                text("SELECT sql FROM sqlite_master WHERE type='table' AND name='user_learning_activities'")
            ).fetchone()
            if res and res[0] and "uq_user_activity_entity" in res[0]:
                conn.execute(text("""
                    CREATE TABLE IF NOT EXISTS user_learning_activities_new (
                        id INTEGER NOT NULL PRIMARY KEY,
                        user_id INTEGER NOT NULL,
                        firebase_uid VARCHAR(128) NOT NULL,
                        activity_date VARCHAR(10) NOT NULL,
                        activity_type VARCHAR(50) NOT NULL,
                        entity_id INTEGER,
                        created_at DATETIME NOT NULL,
                        CONSTRAINT uq_user_daily_activity UNIQUE (user_id, activity_date, activity_type, entity_id),
                        FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
                    )
                """))
                conn.execute(text("INSERT INTO user_learning_activities_new SELECT * FROM user_learning_activities"))
                conn.execute(text("DROP TABLE user_learning_activities"))
                conn.execute(text("ALTER TABLE user_learning_activities_new RENAME TO user_learning_activities"))

                # Re-create indexes
                conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_learning_activities_id ON user_learning_activities (id)"))
                conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_learning_activities_user_id ON user_learning_activities (user_id)"))
                conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_learning_activities_activity_date ON user_learning_activities (activity_date)"))
                conn.execute(text("CREATE INDEX IF NOT EXISTS ix_user_learning_activities_firebase_uid ON user_learning_activities (firebase_uid)"))
                logger.info("Migrated: Updated 'user_learning_activities' unique constraint in SQLite.")

        # 3. PostgreSQL-specific check for unique constraint on user_learning_activities
        elif is_pg and "user_learning_activities" in existing_tables:
            constraints = inspector.get_unique_constraints("user_learning_activities")
            c_names = {c.get("name") for c in constraints if c.get("name")}
            if "uq_user_daily_activity" not in c_names:
                if "uq_user_activity_entity" in c_names:
                    conn.execute(text("ALTER TABLE user_learning_activities DROP CONSTRAINT uq_user_activity_entity"))
                conn.execute(text(
                    "ALTER TABLE user_learning_activities ADD CONSTRAINT uq_user_daily_activity "
                    "UNIQUE (user_id, activity_date, activity_type, entity_id)"
                ))
                logger.info("Migrated: Added 'uq_user_daily_activity' constraint to PostgreSQL.")


def init_database():
    Base.metadata.create_all(bind=engine)
    migrate_columns()
    migrate_constraints_and_indexes()
    logger.info("Kiko database tables, constraints, and indexes verified successfully.")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    init_database()
