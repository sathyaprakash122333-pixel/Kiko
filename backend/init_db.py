import sqlite3
from sqlalchemy import text
from database import Base, engine, DEFAULT_DB_PATH
import models


def migrate_columns():
    """Safely adds missing nullable columns to existing tables without data loss."""
    with engine.connect() as conn:
        # Check users table
        result = conn.execute(text("PRAGMA table_info(users)"))
        columns = [row[1] for row in result.fetchall()]
        if "created_at" not in columns:
            conn.execute(text("ALTER TABLE users ADD COLUMN created_at DATETIME"))
            conn.commit()
            print("Migrated: Added 'created_at' column to 'users' table.")
        if "last_login_at" not in columns:
            conn.execute(text("ALTER TABLE users ADD COLUMN last_login_at DATETIME"))
            conn.commit()
            print("Migrated: Added 'last_login_at' column to 'users' table.")

        # Check lesson_progress table
        result = conn.execute(text("PRAGMA table_info(lesson_progress)"))
        columns = [row[1] for row in result.fetchall()]
        if "completed_at" not in columns:
            conn.execute(text("ALTER TABLE lesson_progress ADD COLUMN completed_at DATETIME"))
            conn.commit()
            print("Migrated: Added 'completed_at' column to 'lesson_progress' table.")

        # Check exams table
        result = conn.execute(text("PRAGMA table_info(exams)"))
        columns = [row[1] for row in result.fetchall()]
        if "course_id" not in columns:
            conn.execute(text("ALTER TABLE exams ADD COLUMN course_id INTEGER REFERENCES courses(id)"))
            conn.commit()
            print("Migrated: Added 'course_id' column to 'exams' table.")

        # Check exam_attempts table
        result = conn.execute(text("PRAGMA table_info(exam_attempts)"))
        columns = [row[1] for row in result.fetchall()]
        if "answers_summary" not in columns:
            conn.execute(text("ALTER TABLE exam_attempts ADD COLUMN answers_summary TEXT"))
            conn.commit()
            print("Migrated: Added 'answers_summary' column to 'exam_attempts' table.")


def migrate_constraints_and_indexes():
    """
    Safely adds performance indexes and updates constraints without data loss.
    """
    with engine.connect() as conn:
        # 1. Add performance indexes for foreign keys & common queries
        indexes_to_create = [
            ("ix_exam_attempts_user_id", "exam_attempts", "user_id"),
            ("ix_exam_attempts_exam_id", "exam_attempts", "exam_id"),
            ("ix_exam_questions_exam_id", "exam_questions", "exam_id"),
            ("ix_lessons_course_id", "lessons", "course_id"),
        ]
        for idx_name, tbl_name, col_name in indexes_to_create:
            conn.execute(text(f"CREATE INDEX IF NOT EXISTS {idx_name} ON {tbl_name} ({col_name})"))
        conn.commit()

        # 2. Check user_learning_activities constraint in SQLite
        res = conn.execute(
            text("SELECT sql FROM sqlite_master WHERE type='table' AND name='user_learning_activities'")
        ).fetchone()
        if res and res[0] and "uq_user_activity_entity" in res[0]:
            # Old constraint is (user_id, activity_type, entity_id), which prevents recording activities
            # on different days for the same entity. Migrate to uq_user_daily_activity.
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
            conn.commit()
            print("Migrated: Updated 'user_learning_activities' unique constraint to (user_id, activity_date, activity_type, entity_id).")


def init_database():
    Base.metadata.create_all(bind=engine)
    migrate_columns()
    migrate_constraints_and_indexes()
    print("Kiko database tables, constraints, and indexes verified successfully.")


if __name__ == "__main__":
    init_database()

