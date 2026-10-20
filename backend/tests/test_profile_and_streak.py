import os
import sys
import unittest
from datetime import datetime, timezone, timedelta, date
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from database import Base
import models
from models import User, UserProfile, UserLearningActivity, Lesson, Course, LessonProgress, Exam, ExamQuestion, ExamAttempt
from schemas import UserProfileUpdatePayload, LessonCompletionRequest, ExamSubmissionRequest, QuestionAnswer
from main import app, get_db, record_learning_activity, calculate_user_streak
from auth import get_current_user
from seed_data import seed_courses


class ProfileAndStreakTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.test_engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        cls.TestSessionLocal = sessionmaker(
            bind=cls.test_engine, autoflush=False, autocommit=False
        )

    def setUp(self):
        Base.metadata.create_all(bind=self.test_engine)
        self.db = self.TestSessionLocal()
        seed_courses(self.db)

        now = datetime.now(timezone.utc)
        self.user1 = User(
            firebase_uid="uid_user_1",
            email="sathya@example.com",
            display_name="Sathya Prakash",
            created_at=now,
            last_login_at=now,
        )
        self.user2 = User(
            firebase_uid="uid_user_2",
            email="other@example.com",
            display_name="Other Student",
            created_at=now,
            last_login_at=now,
        )
        self.db.add_all([self.user1, self.user2])
        self.db.commit()
        self.db.refresh(self.user1)
        self.db.refresh(self.user2)

        self.client = TestClient(app)

        def override_get_db():
            try:
                yield self.db
            finally:
                pass

        app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        app.dependency_overrides.clear()
        self.db.close()
        Base.metadata.drop_all(bind=self.test_engine)

    def test_auto_create_profile_on_first_access(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1

        response = self.client.get("/users/me")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["firebase_uid"], "uid_user_1")
        self.assertEqual(data["email"], "sathya@example.com")
        self.assertEqual(data["full_name"], "Sathya Prakash")

        # Verify record exists in DB
        profile = self.db.query(UserProfile).filter(UserProfile.user_id == self.user1.id).first()
        self.assertIsNotNone(profile)
        self.assertEqual(profile.full_name, "Sathya Prakash")

    def test_update_profile_and_preserve_on_login(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1

        update_payload = {
            "full_name": "Sathya Prakash",
            "date_of_birth": "2004-11-15",
            "gender": "Male",
            "city": "Chennai",
            "institution": "Sri Sairam Engineering College",
            "degree": "B.E. (Information Technology)",
            "department": "Information Technology",
            "academic_year": "3rd Year",
            "semester": "5th Semester",
        }
        response = self.client.put("/users/me", json=update_payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["institution"], "Sri Sairam Engineering College")
        self.assertEqual(data["city"], "Chennai")
        self.assertEqual(data["academic_year"], "3rd Year")

        # Simulate subsequent login
        now = datetime.now(timezone.utc)
        self.user1.last_login_at = now
        self.db.commit()

        # Fetch again: previously saved profile must NOT be overwritten
        get_res = self.client.get("/users/me")
        self.assertEqual(get_res.status_code, 200)
        get_data = get_res.json()
        self.assertEqual(get_data["institution"], "Sri Sairam Engineering College")
        self.assertEqual(get_data["city"], "Chennai")
        self.assertEqual(get_data["degree"], "B.E. (Information Technology)")

    def test_reject_future_date_of_birth(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1

        tomorrow = (datetime.now(timezone.utc) + timedelta(days=2)).strftime("%Y-%m-%d")
        response = self.client.put("/users/me", json={"date_of_birth": tomorrow})
        self.assertEqual(response.status_code, 400)
        self.assertIn("future", response.json()["detail"].lower())

    def test_empty_optional_fields_allowed(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1

        response = self.client.put("/users/me", json={
            "full_name": "Sathya Prakash",
            "date_of_birth": "",
            "gender": "",
            "city": "",
            "institution": "",
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIsNone(data["date_of_birth"])
        self.assertIsNone(data["city"])

    def test_user_isolation(self):
        # User 1 updates profile
        app.dependency_overrides[get_current_user] = lambda: self.user1
        self.client.put("/users/me", json={
            "full_name": "Sathya Prakash",
            "city": "Chennai",
        })

        # Switch to User 2: must see User 2's profile, not User 1's
        app.dependency_overrides[get_current_user] = lambda: self.user2
        response2 = self.client.get("/users/me")
        self.assertEqual(response2.status_code, 200)
        data2 = response2.json()
        self.assertEqual(data2["firebase_uid"], "uid_user_2")
        self.assertNotEqual(data2["full_name"], "Sathya Prakash")
        self.assertIsNone(data2["city"])

    def test_learning_streak_calculation(self):
        # No activities yet
        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertEqual(streak.current_streak, 0)
        self.assertEqual(streak.longest_streak, 0)
        self.assertFalse(streak.active_today)
        self.assertEqual(streak.total_active_days, 0)

        # Record activity today
        today = datetime.now(timezone.utc)
        record_learning_activity(self.db, self.user1, "lesson_completion", entity_id=1, activity_datetime=today)
        self.db.commit()

        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertEqual(streak.current_streak, 1)
        self.assertEqual(streak.longest_streak, 1)
        self.assertTrue(streak.active_today)
        self.assertEqual(streak.total_active_days, 1)

        # Add second activity on same day (idempotent streak)
        record_learning_activity(self.db, self.user1, "lesson_completion", entity_id=2, activity_datetime=today)
        self.db.commit()
        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertEqual(streak.current_streak, 1)  # Same day does not increment streak count
        self.assertEqual(streak.total_active_days, 1)

    def test_consecutive_days_and_boundary_handling(self):
        # Add activities for yesterday, 2 days ago, 3 days ago
        base_date = datetime.now(timezone.utc)
        for days_ago in (1, 2, 3):
            past_dt = base_date - timedelta(days=days_ago)
            record_learning_activity(
                self.db,
                self.user1,
                "lesson_completion",
                entity_id=100 + days_ago,
                activity_datetime=past_dt,
            )
        self.db.commit()

        # No activity today yet, but active yesterday -> current streak is 3
        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertFalse(streak.active_today)
        self.assertEqual(streak.current_streak, 3)
        self.assertEqual(streak.longest_streak, 3)

        # Complete activity today -> current streak becomes 4
        record_learning_activity(self.db, self.user1, "lesson_completion", entity_id=200, activity_datetime=base_date)
        self.db.commit()
        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertTrue(streak.active_today)
        self.assertEqual(streak.current_streak, 4)
        self.assertEqual(streak.longest_streak, 4)

    def test_streak_breaks_after_missed_day(self):
        # Activity 3 days ago, but missed yesterday and today
        base_date = datetime.now(timezone.utc)
        past_dt = base_date - timedelta(days=3)
        record_learning_activity(self.db, self.user1, "lesson_completion", entity_id=300, activity_datetime=past_dt)
        self.db.commit()

        streak = calculate_user_streak(self.db, self.user1.id)
        self.assertEqual(streak.current_streak, 0)
        self.assertEqual(streak.longest_streak, 1)

    def test_lesson_completion_endpoint_records_activity(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1
        first_lesson = self.db.query(Lesson).first()

        res = self.client.post(f"/lessons/{first_lesson.id}/complete", json={"completed": True})
        self.assertEqual(res.status_code, 200)

        # Check streak endpoint
        streak_res = self.client.get("/users/me/streak")
        self.assertEqual(streak_res.status_code, 200)
        streak_data = streak_res.json()
        self.assertTrue(streak_data["active_today"])
        self.assertGreaterEqual(streak_data["current_streak"], 1)

    def test_profile_update_does_not_alter_streak(self):
        app.dependency_overrides[get_current_user] = lambda: self.user1
        first_lesson = self.db.query(Lesson).first()
        self.client.post(f"/lessons/{first_lesson.id}/complete", json={"completed": True})

        streak_before = self.client.get("/users/me/streak").json()

        # Update profile
        self.client.put("/users/me", json={"city": "Bengaluru"})

        streak_after = self.client.get("/users/me/streak").json()
        self.assertEqual(streak_before["current_streak"], streak_after["current_streak"])
        self.assertEqual(streak_before["total_active_days"], streak_after["total_active_days"])


if __name__ == "__main__":
    unittest.main()
