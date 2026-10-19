import os
import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

# Ensure backend directory is in path
backend_dir = str(Path(__file__).resolve().parent.parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from database import Base
import models
from models import User, Course, Lesson, Exam, ExamQuestion, ExamAttempt, LessonProgress
from schemas import LessonCompletionRequest, ExamSubmissionRequest, QuestionAnswer
from main import app, get_db
from auth import get_current_user
from seed_data import seed_courses


class KikoApiTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Create an in-memory SQLite database shared across threads for testing
        cls.test_engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        cls.TestSessionLocal = sessionmaker(
            bind=cls.test_engine, autoflush=False, autocommit=False
        )

    def setUp(self):
        # Create all tables cleanly for each test run
        Base.metadata.create_all(bind=self.test_engine)

        self.db = self.TestSessionLocal()
        # Seed educational course content
        seed_courses(self.db)

        # Override get_db dependency
        def override_get_db():
            db = self.TestSessionLocal()
            try:
                yield db
            finally:
                db.close()

        app.dependency_overrides[get_db] = override_get_db
        self.client = TestClient(app)

        # Create a test user in DB
        self.test_user = User(
            firebase_uid="test_firebase_uid_123",
            email="teststudent@example.com",
            display_name="Test Student",
        )
        self.db.add(self.test_user)
        self.db.commit()
        self.db.refresh(self.test_user)

    def tearDown(self):
        self.db.close()
        app.dependency_overrides.clear()
        Base.metadata.drop_all(bind=self.test_engine)

    def test_health_and_root(self):
        res_root = self.client.get("/")
        self.assertEqual(res_root.status_code, 200)
        self.assertIn("message", res_root.json())

        res_health = self.client.get("/health")
        self.assertEqual(res_health.status_code, 200)
        self.assertEqual(res_health.json()["status"], "ok")

    def test_list_courses(self):
        res = self.client.get("/courses")
        self.assertEqual(res.status_code, 200)
        courses = res.json()
        self.assertGreaterEqual(len(courses), 2)
        titles = [c["title"] for c in courses]
        self.assertIn("Introduction to C Programming", titles)
        self.assertIn("Python Fundamentals for Beginners", titles)

    def test_course_detail_and_lessons(self):
        course = self.db.query(Course).filter(Course.title == "Introduction to C Programming").first()
        self.assertIsNotNone(course)

        # Get course detail
        res = self.client.get(f"/courses/{course.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["title"], course.title)
        self.assertEqual(len(data["lessons"]), 10)
        self.assertIsNotNone(data.get("exam_id"))
        self.assertIn("Comprehensive", data.get("exam_title", ""))

        # Get course lessons list
        res_lessons = self.client.get(f"/courses/{course.id}/lessons")
        self.assertEqual(res_lessons.status_code, 200)
        self.assertEqual(len(res_lessons.json()), 10)

        # Nonexistent course
        res_404 = self.client.get("/courses/99999")
        self.assertEqual(res_404.status_code, 404)

    def test_lesson_detail(self):
        lesson = self.db.query(Lesson).filter(Lesson.order_number == 1).first()
        self.assertIsNotNone(lesson)

        res = self.client.get(f"/lessons/{lesson.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["id"], lesson.id)
        self.assertEqual(data["title"], lesson.title)
        self.assertTrue(len(data["content"]) > 0)

        # 404 for invalid lesson
        res_404 = self.client.get("/lessons/99999")
        self.assertEqual(res_404.status_code, 404)

    def test_lesson_empty_content(self):
        course = self.db.query(Course).first()
        empty_lesson = Lesson(
            course_id=course.id,
            title="Empty Content Test Lesson",
            content="",
            order_number=99,
        )
        self.db.add(empty_lesson)
        self.db.commit()
        self.db.refresh(empty_lesson)

        res = self.client.get(f"/lessons/{empty_lesson.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["id"], empty_lesson.id)
        self.assertEqual(data["title"], "Empty Content Test Lesson")
        self.assertEqual(data["content"], "")

    def test_unpublished_course_and_lesson_returns_404(self):
        draft_course = Course(
            title="Draft Unpublished Course",
            description="Draft",
            language="Rust",
            is_published=False,
        )
        self.db.add(draft_course)
        self.db.flush()

        draft_lesson = Lesson(
            course_id=draft_course.id,
            title="Draft Lesson",
            content="Some draft content",
            order_number=1,
        )
        self.db.add(draft_lesson)
        self.db.commit()

        # Both course and its lesson must return 404
        res_course = self.client.get(f"/courses/{draft_course.id}")
        self.assertEqual(res_course.status_code, 404)

        res_lesson = self.client.get(f"/lessons/{draft_lesson.id}")
        self.assertEqual(res_lesson.status_code, 404)

    def test_exam_retrieval_does_not_leak_answers(self):
        exam = self.db.query(Exam).first()
        self.assertIsNotNone(exam)

        res = self.client.get(f"/exams/{exam.id}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["id"], exam.id)
        self.assertGreaterEqual(data["question_count"], 1)

        # CRITICAL TEST: Verify no question exposes correct_option_index or explanation
        for q in data["questions"]:
            self.assertNotIn("correct_option_index", q)
            self.assertNotIn("explanation", q)
            self.assertIn("question_text", q)
            self.assertIn("options", q)
            self.assertIsInstance(q["options"], list)

        # Also verify via lesson route /lessons/{lesson_id}/exam
        res_lesson_exam = self.client.get(f"/lessons/{exam.lesson_id}/exam")
        self.assertEqual(res_lesson_exam.status_code, 200)
        self.assertEqual(res_lesson_exam.json()["id"], exam.id)

    def test_unauthenticated_requests_blocked(self):
        # Protected endpoints must return 401 when unauthenticated
        lesson = self.db.query(Lesson).first()
        exam = self.db.query(Exam).first()

        res1 = self.client.post(f"/lessons/{lesson.id}/complete", json={"completed": True})
        self.assertEqual(res1.status_code, 401)

        res2 = self.client.get(f"/courses/{lesson.course_id}/progress")
        self.assertEqual(res2.status_code, 401)

        res3 = self.client.get("/users/me/progress")
        self.assertEqual(res3.status_code, 401)

        res4 = self.client.post(f"/exams/{exam.id}/submit", json={"answers": [{"question_id": 1, "selected_option_index": 0}]})
        self.assertEqual(res4.status_code, 401)

        res5 = self.client.get(f"/exams/{exam.id}/attempts")
        self.assertEqual(res5.status_code, 401)

        res6 = self.client.get("/exam-attempts/1")
        self.assertEqual(res6.status_code, 401)

        res7 = self.client.get("/users/me")
        self.assertEqual(res7.status_code, 401)

        res8 = self.client.patch("/users/me", json={"display_name": "Hacker"})
        self.assertEqual(res8.status_code, 401)

    def test_user_profile_crud(self):
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        # GET /users/me
        res = self.client.get("/users/me")
        self.assertEqual(res.status_code, 200)
        profile = res.json()
        self.assertEqual(profile["id"], self.test_user.id)
        self.assertEqual(profile["firebase_uid"], self.test_user.firebase_uid)
        self.assertEqual(profile["email"], self.test_user.email)
        self.assertEqual(profile["display_name"], self.test_user.display_name)
        self.assertIn("created_at", profile)

        # PATCH /users/me (valid update)
        res_update = self.client.patch("/users/me", json={"display_name": "Updated Name"})
        self.assertEqual(res_update.status_code, 200)
        self.assertEqual(res_update.json()["display_name"], "Updated Name")

        # Verify DB reflected change
        self.db.refresh(self.test_user)
        self.assertEqual(self.test_user.display_name, "Updated Name")

        # PATCH /users/me with whitespace name -> 400
        res_empty = self.client.patch("/users/me", json={"display_name": "   "})
        self.assertIn(res_empty.status_code, [400, 422])

    def test_lesson_completion_and_progress_tracking(self):
        # Override get_current_user to simulate authenticated student
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        course = self.db.query(Course).filter(Course.title == "Introduction to C Programming").first()
        lessons = course.lessons
        self.assertEqual(len(lessons), 10)

        # Initially 0% progress
        res_initial = self.client.get(f"/courses/{course.id}/progress")
        self.assertEqual(res_initial.status_code, 200)
        self.assertEqual(res_initial.json()["completed_lessons"], 0)
        self.assertEqual(res_initial.json()["completion_percentage"], 0.0)

        # Complete lesson 1: 1 of 10 completed = 10%
        res_complete1 = self.client.post(f"/lessons/{lessons[0].id}/complete", json={"completed": True})
        self.assertEqual(res_complete1.status_code, 200)
        self.assertTrue(res_complete1.json()["is_completed"])

        # Check course progress: 1 of 10 completed = 10%
        res_prog1 = self.client.get(f"/courses/{course.id}/progress")
        self.assertEqual(res_prog1.status_code, 200)
        self.assertEqual(res_prog1.json()["completed_lessons"], 1)
        self.assertEqual(res_prog1.json()["completion_percentage"], 10.0)
        self.assertFalse(res_prog1.json()["is_completed"])

        # Complete remaining 9 lessons
        for l in lessons[1:]:
            self.client.post(f"/lessons/{l.id}/complete")

        # Now 100% completed
        res_prog_full = self.client.get(f"/courses/{course.id}/progress")
        self.assertEqual(res_prog_full.json()["completed_lessons"], 10)
        self.assertEqual(res_prog_full.json()["completion_percentage"], 100.0)
        self.assertTrue(res_prog_full.json()["is_completed"])

        # Check overall user progress
        res_overall = self.client.get("/users/me/progress")
        self.assertEqual(res_overall.status_code, 200)
        self.assertEqual(res_overall.json()["completed_lessons_count"], 10)
        self.assertEqual(res_overall.json()["total_enrolled_courses"], 1)

    def test_exam_server_scoring_passed(self):
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        exam = self.db.query(Exam).filter(Exam.title == "C Programming Comprehensive Final Assessment").first()
        self.assertIsNotNone(exam)
        self.assertEqual(len(exam.questions), 20)

        # Test GET /courses/{course_id}/exam without leaking answers
        course = self.db.get(Course, exam.course_id)
        res_course_exam = self.client.get(f"/courses/{course.id}/exam")
        self.assertEqual(res_course_exam.status_code, 200)
        course_exam_data = res_course_exam.json()
        self.assertEqual(course_exam_data["id"], exam.id)
        self.assertEqual(len(course_exam_data["questions"]), 20)
        for q in course_exam_data["questions"]:
            self.assertNotIn("correct_option_index", q)
            self.assertNotIn("explanation", q)

        # Submit all correct answers
        submission_payload = {
            "answers": [
                {"question_id": q.id, "selected_option_index": q.correct_option_index}
                for q in exam.questions
            ]
        }

        res = self.client.post(f"/exams/{exam.id}/submit", json=submission_payload)
        self.assertEqual(res.status_code, 200)
        result = res.json()

        # Check that server computed full score (20/20, 100%)
        total = len(exam.questions)
        self.assertEqual(result["score"], 20)
        self.assertEqual(result["total_questions"], 20)
        self.assertEqual(result["percentage"], 100.0)
        self.assertTrue(result["passed"])
        self.assertEqual(len(result["details"]), 20)

        # Verify attempt is saved in DB with answers_summary
        attempt_id = result["attempt_id"]
        attempt = self.db.get(ExamAttempt, attempt_id)
        self.assertIsNotNone(attempt)
        self.assertEqual(attempt.score, 20)
        self.assertTrue(attempt.passed)
        self.assertIsNotNone(attempt.answers_summary)

        # Check exam attempt history
        res_attempts = self.client.get(f"/exams/{exam.id}/attempts")
        self.assertEqual(res_attempts.status_code, 200)
        self.assertEqual(len(res_attempts.json()), 1)
        self.assertEqual(res_attempts.json()[0]["attempt_id"], attempt_id)

        # Check course-level attempt history: GET /courses/{course_id}/attempts
        res_course_attempts = self.client.get(f"/courses/{course.id}/attempts")
        self.assertEqual(res_course_attempts.status_code, 200)
        self.assertEqual(len(res_course_attempts.json()), 1)
        self.assertEqual(res_course_attempts.json()[0]["attempt_id"], attempt_id)

        # Check GET /exam-attempts/{attempt_id}/result (persistent review)
        res_attempt_review = self.client.get(f"/exam-attempts/{attempt_id}/result")
        self.assertEqual(res_attempt_review.status_code, 200)
        review_data = res_attempt_review.json()
        self.assertEqual(review_data["score"], 20)
        self.assertEqual(len(review_data["details"]), 20)
        for detail in review_data["details"]:
            self.assertTrue(detail["is_correct"])
            self.assertIsNotNone(detail["explanation"])

        # Check GET /exams/{exam_id}/latest-result
        res_latest = self.client.get(f"/exams/{exam.id}/latest-result")
        self.assertEqual(res_latest.status_code, 200)
        self.assertEqual(res_latest.json()["attempt_id"], attempt_id)

    def test_exam_server_scoring_failed(self):
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        exam = self.db.query(Exam).filter(Exam.title == "C Programming Comprehensive Final Assessment").first()
        self.assertIsNotNone(exam)

        # Submit all intentionally wrong answers
        submission_payload = {
            "answers": [
                {"question_id": q.id, "selected_option_index": (q.correct_option_index + 1) % len(q.get_options_list())}
                for q in exam.questions
            ]
        }

        res = self.client.post(f"/exams/{exam.id}/submit", json=submission_payload)
        self.assertEqual(res.status_code, 200)
        result = res.json()

        self.assertEqual(result["score"], 0)
        self.assertEqual(result["percentage"], 0.0)
        self.assertFalse(result["passed"])

    def test_exam_submission_validation_errors(self):
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        exam = self.db.query(Exam).first()

        # Question ID does not belong to this exam
        res_invalid_qid = self.client.post(
            f"/exams/{exam.id}/submit",
            json={"answers": [{"question_id": 99999, "selected_option_index": 0}]},
        )
        self.assertEqual(res_invalid_qid.status_code, 400)

        # Selected option out of bounds
        q = exam.questions[0]
        res_oob = self.client.post(
            f"/exams/{exam.id}/submit",
            json={"answers": [{"question_id": q.id, "selected_option_index": 999}]},
        )
        self.assertEqual(res_oob.status_code, 400)

    def test_exam_user_isolation(self):
        # Create a second user
        other_user = User(
            firebase_uid="firebase_user_other",
            email="other@kiko.edu",
            display_name="Other Student",
        )
        self.db.add(other_user)
        self.db.commit()
        self.db.refresh(other_user)

        # Submit as test_user
        app.dependency_overrides[get_current_user] = lambda: self.test_user
        exam = self.db.query(Exam).first()
        sub_res = self.client.post(
            f"/exams/{exam.id}/submit",
            json={"answers": [{"question_id": exam.questions[0].id, "selected_option_index": 0}]},
        )
        attempt_id = sub_res.json()["attempt_id"]

        # Switch to other_user
        app.dependency_overrides[get_current_user] = lambda: other_user

        # Other user cannot access test_user's attempt summary (404/403 security isolation)
        res_summary = self.client.get(f"/exam-attempts/{attempt_id}")
        self.assertIn(res_summary.status_code, [403, 404])

        # Other user cannot access test_user's attempt detailed result
        res_detail = self.client.get(f"/exam-attempts/{attempt_id}/result")
        self.assertIn(res_detail.status_code, [403, 404])

        # Other user has no attempts on this exam
        res_other_attempts = self.client.get(f"/exams/{exam.id}/attempts")
        self.assertEqual(res_other_attempts.status_code, 200)
        self.assertEqual(len(res_other_attempts.json()), 0)

    def test_repeated_seeding_idempotency(self):
        from seed_data import seed_courses
        # Re-run seed_courses on the test db
        seed_courses(self.db)
        seed_courses(self.db)

        # Assert no duplicates: 2 courses, 20 lessons, 2 exams, 40 questions
        courses_count = self.db.query(Course).count()
        lessons_count = self.db.query(Lesson).count()
        exams_count = self.db.query(Exam).count()
        questions_count = self.db.query(ExamQuestion).count()

        self.assertEqual(courses_count, 2)
        self.assertEqual(lessons_count, 20)
        self.assertEqual(exams_count, 2)
        self.assertEqual(questions_count, 40)

    def test_detailed_user_progress_aggregation(self):
        app.dependency_overrides[get_current_user] = lambda: self.test_user

        # Initially: 0 lessons completed, 0 exams attempted
        res_empty = self.client.get("/users/me/progress")
        self.assertEqual(res_empty.status_code, 200)
        data_empty = res_empty.json()
        self.assertEqual(data_empty["completed_lessons_count"], 0)
        self.assertEqual(data_empty["total_published_lessons"], 20)
        self.assertEqual(data_empty["total_published_exams"], 2)
        self.assertEqual(data_empty["overall_completion_percentage"], 0.0)
        self.assertEqual(data_empty["average_test_score"], 0.0)
        self.assertEqual(len(data_empty["course_progress"]), 2)
        self.assertEqual(data_empty["course_progress"][0]["test_status"], "not_attempted")

        # Complete 2 lessons in Course 1 (C)
        c_course = self.db.query(Course).filter(Course.title == "Introduction to C Programming").first()
        self.client.post(f"/lessons/{c_course.lessons[0].id}/complete")
        self.client.post(f"/lessons/{c_course.lessons[1].id}/complete")

        # Submit exam attempt for C course: 16/20 = 80% (Passed)
        exam = c_course.exam
        answers = [
            {"question_id": q.id, "selected_option_index": q.correct_option_index if i < 16 else (q.correct_option_index + 1) % 4}
            for i, q in enumerate(exam.questions)
        ]
        res_sub = self.client.post(f"/exams/{exam.id}/submit", json={"answers": answers})
        self.assertEqual(res_sub.status_code, 200)

        # Check detailed progress
        res = self.client.get("/users/me/progress")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["completed_lessons_count"], 2)
        self.assertEqual(data["overall_completion_percentage"], 10.0)  # 2 of 20 = 10%
        self.assertEqual(data["passed_exams_count"], 1)
        self.assertEqual(data["average_test_score"], 80.0)
        self.assertEqual(len(data["recent_test_attempts"]), 1)
        self.assertEqual(data["recent_test_attempts"][0]["score"], 16)
        self.assertTrue(data["recent_test_attempts"][0]["passed"])

        # Course progress breakdown for C
        c_prog = next(cp for cp in data["course_progress"] if cp["course_id"] == c_course.id)
        self.assertEqual(c_prog["completed_lessons"], 2)
        self.assertEqual(c_prog["total_lessons"], 10)
        self.assertEqual(c_prog["completion_percentage"], 20.0)
        self.assertEqual(c_prog["test_status"], "passed")
        self.assertEqual(c_prog["test_score"], 16)

    def test_persistent_user_specific_progress_system(self):
        """
        Comprehensive test covering Phase 6 requirements:
        1. A new user begins with zero completed lessons.
        2. Completing a lesson persists in the database.
        3. The completed lesson remains completed after fetching the course again.
        4. Repeating a completion request does not double-count the lesson (idempotence).
        5. Course progress is correct for partial and complete courses.
        6. Overall progress is correct across multiple courses.
        7. Different users see only their own completion records (isolation).
        8. Unauthenticated requests are rejected.
        """
        # Step 8: Unauthenticated requests are rejected
        app.dependency_overrides.pop(get_current_user, None)
        c_course = self.db.query(Course).filter(Course.title == "Introduction to C Programming").first()
        c_lesson1 = c_course.lessons[0]

        res_unauth_complete = self.client.post(f"/lessons/{c_lesson1.id}/complete", json={"completed": True})
        self.assertEqual(res_unauth_complete.status_code, 401)

        res_unauth_course_prog = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_unauth_course_prog.status_code, 401)

        res_unauth_overall = self.client.get("/users/me/progress")
        self.assertEqual(res_unauth_overall.status_code, 401)

        # Create two distinct test users in DB
        now = datetime.now(timezone.utc)
        user_a = User(firebase_uid="uid_student_alpha", email="alpha@kiko.edu", display_name="Student Alpha", created_at=now)
        user_b = User(firebase_uid="uid_student_beta", email="beta@kiko.edu", display_name="Student Beta", created_at=now)
        self.db.add_all([user_a, user_b])
        self.db.commit()
        self.db.refresh(user_a)
        self.db.refresh(user_b)

        # Step 1: New user begins with zero completed lessons
        app.dependency_overrides[get_current_user] = lambda: user_a
        res_a_init = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_init.status_code, 200)
        self.assertEqual(res_a_init.json()["completed_lessons"], 0)
        self.assertEqual(res_a_init.json()["completion_percentage"], 0.0)
        self.assertEqual(res_a_init.json()["completed_lesson_ids"], [])

        res_a_overall_init = self.client.get("/users/me/progress")
        self.assertEqual(res_a_overall_init.status_code, 200)
        self.assertEqual(res_a_overall_init.json()["completed_lessons_count"], 0)
        self.assertEqual(res_a_overall_init.json()["overall_completion_percentage"], 0.0)

        # Step 2: Completing a lesson persists in the database
        res_comp1 = self.client.post(f"/lessons/{c_lesson1.id}/complete", json={"completed": True})
        self.assertEqual(res_comp1.status_code, 200)
        self.assertTrue(res_comp1.json()["is_completed"])
        self.assertEqual(res_comp1.json()["lesson_id"], c_lesson1.id)

        # Verify directly in SQLite database
        lp_db = self.db.query(LessonProgress).filter(
            LessonProgress.user_id == user_a.id,
            LessonProgress.lesson_id == c_lesson1.id,
        ).first()
        self.assertIsNotNone(lp_db)
        self.assertTrue(lp_db.is_completed)

        # Step 3: Completed lesson remains completed after fetching the course again
        res_a_fetch = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_fetch.status_code, 200)
        self.assertEqual(res_a_fetch.json()["completed_lessons"], 1)
        self.assertEqual(res_a_fetch.json()["completed_lesson_ids"], [c_lesson1.id])
        self.assertEqual(res_a_fetch.json()["completion_percentage"], 10.0)

        # Step 4: Repeating a completion request does not double-count (idempotent)
        for _ in range(3):
            res_repeat = self.client.post(f"/lessons/{c_lesson1.id}/complete", json={"completed": True})
            self.assertEqual(res_repeat.status_code, 200)

        res_a_after_repeat = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_after_repeat.json()["completed_lessons"], 1)
        self.assertEqual(res_a_after_repeat.json()["completion_percentage"], 10.0)
        # Ensure only 1 record exists in database
        records_count = self.db.query(LessonProgress).filter(
            LessonProgress.user_id == user_a.id,
            LessonProgress.lesson_id == c_lesson1.id,
        ).count()
        self.assertEqual(records_count, 1)

        # Step 5: Partial and complete courses
        # Complete 4 lessons in C (10 lessons total) -> 40.0%
        for l in c_course.lessons[1:4]:
            self.client.post(f"/lessons/{l.id}/complete")
        res_a_partial = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_partial.json()["completed_lessons"], 4)
        self.assertEqual(res_a_partial.json()["completion_percentage"], 40.0)
        self.assertFalse(res_a_partial.json()["is_completed"])

        # Complete remaining 6 lessons -> 100.0%
        for l in c_course.lessons[4:]:
            self.client.post(f"/lessons/{l.id}/complete")
        res_a_complete = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_complete.json()["completed_lessons"], 10)
        self.assertEqual(res_a_complete.json()["completion_percentage"], 100.0)
        self.assertTrue(res_a_complete.json()["is_completed"])

        # Step 6: Multi-course overall progress
        # Complete 4 lessons in Python course (10 lessons total)
        py_course = self.db.query(Course).filter(Course.title == "Python Fundamentals for Beginners").first()
        for l in py_course.lessons[:4]:
            self.client.post(f"/lessons/{l.id}/complete")

        # Total completed = 10 (C) + 4 (Python) = 14 out of 20 published lessons = 70.0%
        res_a_overall_multi = self.client.get("/users/me/progress")
        self.assertEqual(res_a_overall_multi.status_code, 200)
        self.assertEqual(res_a_overall_multi.json()["completed_lessons_count"], 14)
        self.assertEqual(res_a_overall_multi.json()["overall_completion_percentage"], 70.0)

        # Step 7: Different users see only their own completion records (User Isolation)
        app.dependency_overrides[get_current_user] = lambda: user_b
        res_b_c_prog = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_b_c_prog.json()["completed_lessons"], 0)
        self.assertEqual(res_b_c_prog.json()["completed_lesson_ids"], [])
        self.assertEqual(res_b_c_prog.json()["completion_percentage"], 0.0)

        res_b_overall = self.client.get("/users/me/progress")
        self.assertEqual(res_b_overall.json()["completed_lessons_count"], 0)
        self.assertEqual(res_b_overall.json()["overall_completion_percentage"], 0.0)

        # Complete 1 lesson as user_b
        self.client.post(f"/lessons/{c_lesson1.id}/complete")
        res_b_after = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_b_after.json()["completed_lessons"], 1)

        # Switch back to user_a: user_a's 14 completed lessons are completely preserved and unaffected
        app.dependency_overrides[get_current_user] = lambda: user_a
        res_a_verify = self.client.get(f"/courses/{c_course.id}/progress")
        self.assertEqual(res_a_verify.json()["completed_lessons"], 10)
        res_a_overall_verify = self.client.get("/users/me/progress")
        self.assertEqual(res_a_overall_verify.json()["completed_lessons_count"], 14)


if __name__ == "__main__":
    unittest.main()
