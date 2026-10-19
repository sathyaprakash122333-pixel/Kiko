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


def init_database():
    Base.metadata.create_all(bind=engine)
    migrate_columns()
    print("Kiko SQLite database and tables verified successfully.")


if __name__ == "__main__":
    init_database()

