import os
import sys
import tempfile
import unittest
from datetime import datetime, timezone, timedelta
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from database import Base, engine as prod_engine
import models
from models import (
    User, UserProfile, UserLearningActivity, Lesson, Course, LessonProgress,
    Exam, ExamQuestion, ExamAttempt
)
from schemas import (
    UserProfileUpdatePayload, LessonCompletionRequest, ExamSubmissionRequest,
    QuestionAnswer
)
from main import app, get_db, record_learning_activity, calculate_user_streak
from auth import get_current_user, verify_firebase_token
from seed_data import seed_courses


class KikoPhase5ReliabilityTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create an isolated in-memory SQLite database
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

        # Create two test users
        now = datetime.now(timezone.utc)
        self.user_a = User(
            firebase_uid="uid_student_alpha",
            email="alpha@test.kiko.local",
            display_name="Student Alpha",
            created_at=now,
            last_login_at=now,
        )
        self.user_b = User(
            firebase_uid="uid_student_beta",
            email="beta@test.kiko.local",
            display_name="Student Beta",
            created_at=now,
            last_login_at=now,
        )
        self.db.add_all([self.user_a, self.user_b])
        self.db.commit()
        self.db.refresh(self.user_a)
        self.db.refresh(self.user_b)

        self.client = TestClient(app)

        def override_get_db():
            db = self.TestSessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db

    def tearDown(self):
        app.dependency_overrides.clear()
        self.db.close()
        Base.metadata.drop_all(bind=self.test_engine)

    # -------------------------------------------------------------------------
    # Scenario 1: New user signs in and receives the correct database profile
    # -------------------------------------------------------------------------
    def test_scenario_01_new_user_signin_receives_correct_profile(self):
        from unittest.mock import patch
        with patch("auth.verify_firebase_token") as mock_verify:
            mock_verify.return_value = {
                "uid": "uid_new_student_gamma",
                "email": "gamma@test.kiko.local",
                "name": "Student Gamma",
            }

            response = self.client.get(
                "/users/me",
                headers={"Authorization": "Bearer fake_token_gamma"},
            )
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["firebase_uid"], "uid_new_student_gamma")
            self.assertEqual(data["email"], "gamma@test.kiko.local")
            self.assertEqual(data["full_name"], "Student Gamma")

            # Verify DB records
            created_user = self.db.query(User).filter(User.firebase_uid == "uid_new_student_gamma").first()
            self.assertIsNotNone(created_user)
            self.assertIsNotNone(created_user.profile)
            self.assertEqual(created_user.profile.full_name, "Student Gamma")

    # -------------------------------------------------------------------------
    # Scenario 2: Existing user signs in again without creating duplicate records
    # -------------------------------------------------------------------------
    def test_scenario_02_existing_user_signin_does_not_duplicate(self):
        from unittest.mock import patch
        with patch("auth.verify_firebase_token") as mock_verify:
            mock_verify.return_value = {
                "uid": "uid_student_alpha",
                "email": "alpha@test.kiko.local",
                "name": "Student Alpha",
            }

            # Sign in 3 times
            for _ in range(3):
                res = self.client.get("/users/me", headers={"Authorization": "Bearer token_alpha"})
                self.assertEqual(res.status_code, 200)

            # Assert no duplicates
            user_count = self.db.query(User).filter(User.firebase_uid == "uid_student_alpha").count()
            profile_count = self.db.query(UserProfile).filter(UserProfile.firebase_uid == "uid_student_alpha").count()
            self.assertEqual(user_count, 1)
            self.assertEqual(profile_count, 1)

    # -------------------------------------------------------------------------
    # Scenario 3: User edits their profile and sees saved values after refreshing
    # -------------------------------------------------------------------------
    def test_scenario_03_profile_edits_persist_and_refresh(self):
        app.dependency_overrides[get_current_user] = lambda: self.user_a

        update_data = {
            "full_name": "Sathya Prakash Updated",
            "city": "Coimbatore",
            "institution": "KPR Institute of Engineering and Technology",
            "department": "Information Technology",
            "academic_year": "3rd Year",
            "semester": "6th Semester",
            "degree": "B.Tech IT",
            "gender": "Male",
        }

        put_res = self.client.put("/users/me", json=update_data)
        self.assertEqual(put_res.status_code, 200)

        # GET /users/me again (refresh)
        get_res = self.client.get("/users/me")
        self.assertEqual(get_res.status_code, 200)
        profile_data = get_res.json()

        self.assertEqual(profile_data["full_name"], "Sathya Prakash Updated")
        self.assertEqual(profile_data["city"], "Coimbatore")
        self.assertEqual(profile_data["institution"], "KPR Institute of Engineering and Technology")
        self.assertEqual(profile_data["department"], "Information Technology")
        self.assertEqual(profile_data["degree"], "B.Tech IT")

    # -------------------------------------------------------------------------
    # Scenario 4: Missing profile fields remain NULL / empty state
    # -------------------------------------------------------------------------
    def test_scenario_04_missing_profile_fields_remain_null(self):
        app.dependency_overrides[get_current_user] = lambda: self.user_b

        res = self.client.get("/users/me")
        self.assertEqual(res.status_code, 200)
        data = res.json()

        self.assertIsNone(data["city"])
        self.assertIsNone(data["institution"])
        self.assertIsNone(data["degree"])
        self.assertIsNone(data["department"])
        self.assertIsNone(data["academic_year"])
        self.assertIsNone(data["semester"])
        self.assertIsNone(data["date_of_birth"])

    # -------------------------------------------------------------------------
    # Scenario 5: Lesson completion persists and is reflected in progress
    # -------------------------------------------------------------------------
    def test_scenario_05_lesson_completion_persists_in_progress(self):
        app.dependency_overrides[get_current_user] = lambda: self.user_a
        c_course = self.db.query(Course).filter(Course.title == "Introduction to C Programming").first()
        self.assertIsNotNone(c_course)
        first_lesson = c_course.lessons[0]

        # Complete lesson
        complete_res = self.client.post(f"/lessons/{first_lesson.id}/complete", json={"completed": True})
        self.assertEqual(complete_res.status_code, 200)
        self.assertTrue(complete_res.json()["is_completed"])

        # Check course progress
        course_prog = self.client.get(f"/courses/{c_course.id}/progress").json()
        self.assertIn(first_lesson.id, course_prog["completed_lesson_ids"])
        self.assertEqual(course_prog["completed_lessons"], 1)
        self.assertGreater(course_prog["completion_percentage"], 0.0)

        # Check overall progress
        overall_prog = self.client.get("/users/me/progress").json()
        self.assertGreaterEqual(overall_prog["completed_lessons_count"], 1)

    # -------------------------------------------------------------------------
    # Scenario 6: Exam attempts and results persist correctly
    # -------------------------------------------------------------------------
    def test_scenario_06_exam_attempt_persists_and_computes_score(self):
        app.dependency_overrides[get_current_user] = lambda: self.user_a
        exam = self.db.query(Exam).first()
        self.assertIsNotNone(exam)

        # Submit answers (all correct)
        answers = [
            {"question_id": q.id, "selected_option_index": q.correct_option_index}
            for q in exam.questions
        ]
        submit_res = self.client.post(f"/exams/{exam.id}/submit", json={"answers": answers})
        self.assertEqual(submit_res.status_code, 200)
        result = submit_res.json()

        self.assertEqual(result["score"], len(exam.questions))
        self.assertEqual(result["percentage"], 100.0)
        self.assertTrue(result["passed"])

        # Check attempts history
        history_res = self.client.get(f"/exams/{exam.id}/attempts")
        self.assertEqual(history_res.status_code, 200)
        attempts = history_res.json()
        self.assertEqual(len(attempts), 1)
        self.assertEqual(attempts[0]["score"], len(exam.questions))

    # -------------------------------------------------------------------------
    # Scenario 7: Streak calculations handle repeated activity and date boundaries
    # -------------------------------------------------------------------------
    def test_scenario_07_streak_repeated_activity_and_consecutive_days(self):
        now = datetime.now(timezone.utc)
        yesterday = now - timedelta(days=1)

        # Day 1: Student completes Lesson 1 yesterday
        record_learning_activity(
            self.db, self.user_a, "lesson_completion", entity_id=1, activity_datetime=yesterday
        )
        self.db.commit()

        streak_yest = calculate_user_streak(self.db, self.user_a.id)
        self.assertEqual(streak_yest.current_streak, 1)
        self.assertFalse(streak_yest.active_today)

        # Day 2: Student REVIEWS the SAME Lesson 1 today!
        # (This tests the critical bug we fixed: repeating the same entity on day 2 MUST be recorded)
        record_learning_activity(
            self.db, self.user_a, "lesson_completion", entity_id=1, activity_datetime=now
        )
        self.db.commit()

        streak_today = calculate_user_streak(self.db, self.user_a.id)
        self.assertTrue(streak_today.active_today)
        self.assertEqual(streak_today.current_streak, 2)
        self.assertEqual(streak_today.longest_streak, 2)
        self.assertEqual(streak_today.total_active_days, 2)

        # Repeating on same day is idempotent
        record_learning_activity(
            self.db, self.user_a, "lesson_completion", entity_id=2, activity_datetime=now
        )
        self.db.commit()
        streak_repeat = calculate_user_streak(self.db, self.user_a.id)
        self.assertEqual(streak_repeat.current_streak, 2)
        self.assertEqual(streak_repeat.total_active_days, 2)

    # -------------------------------------------------------------------------
    # Scenario 8: One user cannot access another user's private records
    # -------------------------------------------------------------------------
    def test_scenario_08_idor_protection_between_users(self):
        # User A attempts an exam
        exam = self.db.query(Exam).first()
        answers = [{"question_id": q.id, "selected_option_index": q.correct_option_index} for q in exam.questions]

        app.dependency_overrides[get_current_user] = lambda: self.user_a
        sub_res = self.client.post(f"/exams/{exam.id}/submit", json={"answers": answers})
        attempt_id = sub_res.json()["attempt_id"]

        # User A can read their own attempt
        user_a_res = self.client.get(f"/exam-attempts/{attempt_id}")
        self.assertEqual(user_a_res.status_code, 200)

        # User B CANNOT read User A's attempt (must return 404 Not Found)
        app.dependency_overrides[get_current_user] = lambda: self.user_b
        user_b_res = self.client.get(f"/exam-attempts/{attempt_id}")
        self.assertEqual(user_b_res.status_code, 404)

        user_b_result = self.client.get(f"/exam-attempts/{attempt_id}/result")
        self.assertEqual(user_b_result.status_code, 404)

    # -------------------------------------------------------------------------
    # Scenario 9: Invalid authentication tokens are rejected
    # -------------------------------------------------------------------------
    def test_scenario_09_invalid_tokens_rejected(self):
        # Missing auth header
        res_no_auth = self.client.get("/users/me")
        self.assertEqual(res_no_auth.status_code, 401)

        # Malformed token
        res_bad_auth = self.client.get(
            "/users/me",
            headers={"Authorization": "Bearer totally_invalid_token_xyz"}
        )
        self.assertEqual(res_bad_auth.status_code, 401)

        # Verify dev token blocked in production
        old_env = os.environ.get("ENVIRONMENT")
        os.environ["ENVIRONMENT"] = "production"
        try:
            res_dev_prod = self.client.get(
                "/users/me",
                headers={"Authorization": "Bearer dev:test_hacker"}
            )
            self.assertEqual(res_dev_prod.status_code, 401)
        finally:
            if old_env is not None:
                os.environ["ENVIRONMENT"] = old_env
            else:
                os.environ.pop("ENVIRONMENT", None)

    # -------------------------------------------------------------------------
    # Scenario 10: Database failures do not leave partially updated records
    # -------------------------------------------------------------------------
    def test_scenario_10_transaction_rollback_prevents_partial_records(self):
        app.dependency_overrides[get_current_user] = lambda: self.user_a
        initial_name = self.user_a.display_name

        # Send invalid payload (empty whitespace string) which raises 400
        res = self.client.put("/users/me", json={"full_name": "   "})
        self.assertEqual(res.status_code, 400)

        # Verify DB remained unchanged
        refreshed_user = self.db.get(User, self.user_a.id)
        self.assertEqual(refreshed_user.display_name, initial_name)

    # -------------------------------------------------------------------------
    # Scenario 11: Existing database records survive application restarts
    # -------------------------------------------------------------------------
    def test_scenario_11_records_survive_application_restart(self):
        # Use a temporary file database to simulate a full application restart
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tmp:
            tmp_db_path = tmp.name

        try:
            disk_engine = create_engine(f"sqlite:///{tmp_db_path}")
            Base.metadata.create_all(bind=disk_engine)
            DiskSession = sessionmaker(bind=disk_engine)

            # Session 1: Create user and progress
            with DiskSession() as session:
                seed_courses(session)
                user = User(firebase_uid="uid_restart_test", email="restart@kiko.local")
                session.add(user)
                session.commit()
                user_id = user.id

            # SIMULATE APP RESTART: Dispose engine and connection pool
            disk_engine.dispose()

            # Session 2: Connect again with a brand new engine
            restarted_engine = create_engine(f"sqlite:///{tmp_db_path}")
            RestartedSession = sessionmaker(bind=restarted_engine)
            with RestartedSession() as session:
                persisted_user = session.get(User, user_id)
                self.assertIsNotNone(persisted_user)
                self.assertEqual(persisted_user.firebase_uid, "uid_restart_test")
                self.assertEqual(persisted_user.email, "restart@kiko.local")
            restarted_engine.dispose()

        finally:
            if os.path.exists(tmp_db_path):
                os.remove(tmp_db_path)

    # -------------------------------------------------------------------------
    # Scenario 12: Network & error responses handled gracefully
    # -------------------------------------------------------------------------
    def test_scenario_12_backend_error_responses_standardized(self):
        # Missing course returns 404 with JSON detail
        res_404_course = self.client.get("/courses/999999")
        self.assertEqual(res_404_course.status_code, 404)
        self.assertEqual(res_404_course.json()["detail"], "Course not found")

        # Missing lesson returns 404
        res_404_lesson = self.client.get("/lessons/999999")
        self.assertEqual(res_404_lesson.status_code, 404)
        self.assertEqual(res_404_lesson.json()["detail"], "Lesson not found")

        # Missing exam returns 404
        res_404_exam = self.client.get("/exams/999999")
        self.assertEqual(res_404_exam.status_code, 404)
        self.assertEqual(res_404_exam.json()["detail"], "Exam not found")

        # Future date of birth returns 400
        app.dependency_overrides[get_current_user] = lambda: self.user_a
        future_year = datetime.now(timezone.utc).year + 10
        res_dob = self.client.put("/users/me", json={"date_of_birth": f"{future_year}-01-01"})
        self.assertEqual(res_dob.status_code, 400)
        self.assertIn("future", res_dob.json()["detail"].lower())


if __name__ == "__main__":
    unittest.main()
