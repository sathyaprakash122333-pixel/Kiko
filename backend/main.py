import json
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import SessionLocal
from init_db import init_database
from models import Course, Lesson, Exam, ExamQuestion, ExamAttempt, LessonProgress, User
from schemas import (
    CourseSummaryResponse,
    CourseDetailResponse,
    LessonSummaryResponse,
    LessonDetailResponse,
    LessonCompletionRequest,
    LessonProgressResponse,
    CourseProgressResponse,
    UserOverallProgressResponse,
    CourseProgressItem,
    RecentTestAttemptItem,
    ExamPublicResponse,
    ExamQuestionPublicResponse,
    ExamSubmissionRequest,
    ExamResultResponse,
    QuestionResultDetail,
    ExamAttemptSummaryResponse,
    UserProfileResponse,
    UserProfileUpdateRequest,
)
from auth import get_current_user


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure database tables and columns are verified on startup
    init_database()
    yield


app = FastAPI(
    title="Kiko Educational API",
    description="Backend API for Kiko, a structured programming-learning platform for beginners.",
    version="0.4.0",
    lifespan=lifespan,
)

# Explicit local development origins for Flutter web server and dev clients
DEFAULT_ALLOWED_ORIGINS = [
    "http://127.0.0.1:5000",
    "http://localhost:5000",
    "http://127.0.0.1:8000",
    "http://localhost:8000",
    "http://127.0.0.1:3000",
    "http://localhost:3000",
    "http://127.0.0.1:8080",
    "http://localhost:8080",
]
env_origins = os.getenv("ALLOWED_ORIGINS", "")
allowed_origins = [o.strip() for o in env_origins.split(",") if o.strip()] if env_origins else DEFAULT_ALLOWED_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================================================
# General & Health Endpoints
# ============================================================================

@app.get("/", tags=["General"])
def home():
    return {
        "message": "Welcome to Kiko Educational API",
        "version": "0.4.0",
        "docs_url": "/docs",
    }


@app.get("/health", tags=["General"])
def health_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {
        "status": "ok",
        "service": "kiko-api",
        "database": "connected",
    }


# ============================================================================
# Courses Endpoints (Public)
# ============================================================================

@app.get(
    "/courses",
    response_model=list[CourseSummaryResponse],
    tags=["Courses"],
    summary="List all published courses",
)
def list_courses(db: Session = Depends(get_db)):
    courses = (
        db.query(Course)
        .filter(Course.is_published.is_(True))
        .order_by(Course.id)
        .all()
    )
    return [
        CourseSummaryResponse(
            id=course.id,
            title=course.title,
            description=course.description,
            language=course.language,
            lesson_count=len(course.lessons),
        )
        for course in courses
    ]


@app.get(
    "/courses/{course_id}",
    response_model=CourseDetailResponse,
    tags=["Courses"],
    summary="Retrieve course details and lesson syllabus",
)
def get_course_detail(course_id: int, db: Session = Depends(get_db)):
    course = db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    lessons = [
        LessonSummaryResponse(
            id=l.id,
            course_id=l.course_id,
            title=l.title,
            order_number=l.order_number,
            has_exam=bool(l.exam is not None),
        )
        for l in course.lessons
    ]

    exam = course.exam or next((l.exam for l in reversed(course.lessons) if l.exam), None)

    return CourseDetailResponse(
        id=course.id,
        title=course.title,
        description=course.description,
        language=course.language,
        lessons=lessons,
        exam_id=exam.id if exam else None,
        exam_title=exam.title if exam else None,
    )


@app.get(
    "/courses/{course_id}/lessons",
    response_model=list[LessonSummaryResponse],
    tags=["Courses"],
    summary="List lessons of a specific course",
)
def list_course_lessons(course_id: int, db: Session = Depends(get_db)):
    course = db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    lessons = (
        db.query(Lesson)
        .filter(Lesson.course_id == course_id)
        .order_by(Lesson.order_number)
        .all()
    )

    return [
        LessonSummaryResponse(
            id=lesson.id,
            course_id=lesson.course_id,
            title=lesson.title,
            order_number=lesson.order_number,
            has_exam=bool(lesson.exam is not None),
        )
        for lesson in lessons
    ]


# ============================================================================
# Lessons Endpoints
# ============================================================================

@app.get(
    "/lessons/{lesson_id}",
    response_model=LessonDetailResponse,
    tags=["Lessons"],
    summary="Retrieve lesson content and metadata",
)
def get_lesson(lesson_id: int, db: Session = Depends(get_db)):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None or lesson.course is None or not lesson.course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )

    return LessonDetailResponse(
        id=lesson.id,
        course_id=lesson.course_id,
        title=lesson.title,
        content=lesson.content,
        order_number=lesson.order_number,
        has_exam=bool(lesson.exam is not None),
        exam_id=lesson.exam.id if lesson.exam else None,
    )


@app.post(
    "/lessons/{lesson_id}/complete",
    response_model=LessonProgressResponse,
    tags=["Lessons", "Progress"],
    summary="Save lesson completion status for the authenticated user",
)
def complete_lesson(
    lesson_id: int,
    payload: Optional[LessonCompletionRequest] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None or not lesson.course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )

    is_completed = payload.completed if payload is not None else True

    progress = (
        db.query(LessonProgress)
        .filter(
            LessonProgress.user_id == current_user.id,
            LessonProgress.lesson_id == lesson_id,
        )
        .first()
    )

    now = datetime.now(timezone.utc)

    if not progress:
        progress = LessonProgress(
            user_id=current_user.id,
            lesson_id=lesson_id,
            is_completed=is_completed,
            completed_at=now if is_completed else None,
        )
        db.add(progress)
    else:
        progress.is_completed = is_completed
        progress.completed_at = now if is_completed else None

    try:
        db.commit()
        db.refresh(progress)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update lesson completion progress",
        )

    return LessonProgressResponse(
        lesson_id=progress.lesson_id,
        is_completed=progress.is_completed,
        completed_at=progress.completed_at,
    )


# ============================================================================
# Learning Progress Endpoints (Protected)
# ============================================================================

@app.get(
    "/courses/{course_id}/progress",
    response_model=CourseProgressResponse,
    tags=["Progress"],
    summary="View learning progress for a specific course",
)
def get_course_progress(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    course = db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    total_lessons = (
        db.query(Lesson)
        .filter(Lesson.course_id == course_id)
        .count()
    )

    completed_records = (
        db.query(LessonProgress)
        .join(Lesson, Lesson.id == LessonProgress.lesson_id)
        .filter(
            Lesson.course_id == course_id,
            LessonProgress.user_id == current_user.id,
            LessonProgress.is_completed.is_(True),
        )
        .all()
    )

    completed_ids = sorted(list({r.lesson_id for r in completed_records}))
    completed_count = len(completed_ids)
    percentage = (
        round((completed_count / total_lessons) * 100.0, 1)
        if total_lessons > 0
        else 0.0
    )

    return CourseProgressResponse(
        course_id=course.id,
        course_title=course.title,
        total_lessons=total_lessons,
        completed_lessons=completed_count,
        completion_percentage=percentage,
        is_completed=bool(total_lessons > 0 and completed_count == total_lessons),
        completed_lesson_ids=completed_ids,
    )


@app.get(
    "/users/me/progress",
    response_model=UserOverallProgressResponse,
    tags=["Progress"],
    summary="View overall learning progress for the authenticated user",
)
def get_overall_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Total completed published lessons
    completed_progress = (
        db.query(LessonProgress)
        .join(Lesson, Lesson.id == LessonProgress.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .filter(
            LessonProgress.user_id == current_user.id,
            LessonProgress.is_completed.is_(True),
            Course.is_published.is_(True),
        )
        .order_by(LessonProgress.completed_at.desc().nullslast())
        .all()
    )

    completed_lesson_ids_set = {p.lesson_id for p in completed_progress}
    completed_lessons_count = len(completed_lesson_ids_set)

    # Distinct published courses where user has completed at least one lesson
    course_ids = (
        db.query(Lesson.course_id)
        .join(LessonProgress, LessonProgress.lesson_id == Lesson.id)
        .join(Course, Course.id == Lesson.course_id)
        .filter(
            LessonProgress.user_id == current_user.id,
            LessonProgress.is_completed.is_(True),
            Course.is_published.is_(True),
        )
        .distinct()
        .count()
    )

    # Total published lessons and exams
    total_published_lessons = (
        db.query(Lesson)
        .join(Course, Course.id == Lesson.course_id)
        .filter(Course.is_published.is_(True))
        .count()
    )

    total_published_exams = (
        db.query(Exam)
        .join(Course, Course.id == Exam.course_id)
        .filter(Course.is_published.is_(True))
        .count()
    )

    overall_percentage = (
        round((completed_lessons_count / total_published_lessons) * 100.0, 1)
        if total_published_lessons > 0
        else 0.0
    )

    # Passed distinct exams
    passed_exams_count = (
        db.query(ExamAttempt.exam_id)
        .filter(
            ExamAttempt.user_id == current_user.id,
            ExamAttempt.passed.is_(True),
        )
        .distinct()
        .count()
    )

    # All user test attempts (ordered by date desc)
    user_attempts = (
        db.query(ExamAttempt)
        .filter(ExamAttempt.user_id == current_user.id)
        .order_by(ExamAttempt.attempted_at.desc())
        .all()
    )

    valid_attempts = [a for a in user_attempts if a.total_questions > 0]
    avg_score = (
        round(
            sum((a.score / a.total_questions) * 100.0 for a in valid_attempts)
            / len(valid_attempts),
            1,
        )
        if valid_attempts
        else 0.0
    )

    # Per-course progress breakdown
    published_courses = (
        db.query(Course)
        .filter(Course.is_published.is_(True))
        .order_by(Course.id)
        .all()
    )

    course_progress_list: list[CourseProgressItem] = []
    for c in published_courses:
        c_total = len(c.lessons)
        c_completed = len([l for l in c.lessons if l.id in completed_lesson_ids_set])
        c_pct = (
            round((c_completed / c_total) * 100.0, 1) if c_total > 0 else 0.0
        )

        exam = c.exam or next(
            (l.exam for l in reversed(c.lessons) if l.exam), None
        )
        test_status = "not_attempted"
        test_score = None
        test_total_questions = None
        exam_id = exam.id if exam else None

        if exam:
            latest_course_attempt = (
                db.query(ExamAttempt)
                .filter(
                    ExamAttempt.exam_id == exam.id,
                    ExamAttempt.user_id == current_user.id,
                )
                .order_by(ExamAttempt.attempted_at.desc())
                .first()
            )
            if latest_course_attempt:
                test_status = "passed" if latest_course_attempt.passed else "failed"
                test_score = latest_course_attempt.score
                test_total_questions = latest_course_attempt.total_questions

        course_progress_list.append(
            CourseProgressItem(
                course_id=c.id,
                course_title=c.title,
                language=c.language,
                total_lessons=c_total,
                completed_lessons=c_completed,
                completion_percentage=c_pct,
                test_status=test_status,
                test_score=test_score,
                test_total_questions=test_total_questions,
                exam_id=exam_id,
            )
        )

    # Recent test attempts breakdown
    recent_attempts_list: list[RecentTestAttemptItem] = []
    for a in user_attempts[:10]:
        exam = a.exam
        c_title = (
            exam.course.title
            if exam and exam.course
            else (
                exam.lesson.course.title
                if exam and exam.lesson and exam.lesson.course
                else (exam.title if exam else "Assessment")
            )
        )
        c_id = (
            exam.course.id
            if exam and exam.course
            else (
                exam.lesson.course.id
                if exam and exam.lesson and exam.lesson.course
                else 1
            )
        )
        c_lang = exam.course.language if exam and exam.course else "General"
        pct = (
            round((a.score / a.total_questions) * 100.0, 1)
            if a.total_questions > 0
            else 0.0
        )
        recent_attempts_list.append(
            RecentTestAttemptItem(
                attempt_id=a.id,
                exam_id=a.exam_id,
                course_id=c_id,
                course_title=c_title,
                language=c_lang,
                score=a.score,
                total_questions=a.total_questions,
                percentage=pct,
                passed=a.passed,
                attempted_at=a.attempted_at,
            )
        )

    recent_completed = [
        LessonProgressResponse(
            lesson_id=p.lesson_id,
            is_completed=p.is_completed,
            completed_at=p.completed_at,
        )
        for p in completed_progress[:10]
    ]

    return UserOverallProgressResponse(
        user_id=current_user.id,
        total_enrolled_courses=course_ids,
        completed_lessons_count=completed_lessons_count,
        passed_exams_count=passed_exams_count,
        recent_completed_lessons=recent_completed,
        total_published_lessons=total_published_lessons,
        total_published_exams=total_published_exams,
        overall_completion_percentage=overall_percentage,
        average_test_score=avg_score,
        course_progress=course_progress_list,
        recent_test_attempts=recent_attempts_list,
    )


# ============================================================================
# User Profile Endpoints (Protected)
# ============================================================================

@app.get(
    "/users/me",
    response_model=UserProfileResponse,
    tags=["Users"],
    summary="Retrieve the authenticated user's profile",
)
def get_user_profile(
    current_user: User = Depends(get_current_user),
):
    return current_user


@app.patch(
    "/users/me",
    response_model=UserProfileResponse,
    tags=["Users"],
    summary="Update permitted profile fields (display name) for the authenticated user",
)
def update_user_profile(
    payload: UserProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trimmed_name = payload.display_name.strip()
    if not trimmed_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Display name cannot be empty or only whitespace.",
        )

    # Ensure user is attached to the active database session
    user = db.get(User, current_user.id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found in database.",
        )

    user.display_name = trimmed_name
    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile in database.",
        )

    return user


# ============================================================================
# Exam Endpoints
# ============================================================================

def is_exam_published(exam: Exam) -> bool:
    if exam.course is not None:
        return bool(exam.course.is_published)
    if exam.lesson is not None and exam.lesson.course is not None:
        return bool(exam.lesson.course.is_published)
    return False


@app.get(
    "/exams/{exam_id}",
    response_model=ExamPublicResponse,
    tags=["Exams"],
    summary="Retrieve exam questions to take assessment (correct answers omitted)",
)
def get_exam(exam_id: int, db: Session = Depends(get_db)):
    exam = db.get(Exam, exam_id)
    if exam is None or not is_exam_published(exam):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam not found",
        )

    # Questions are returned strictly without correct answers or explanations
    questions = [
        ExamQuestionPublicResponse(
            id=q.id,
            question_text=q.question_text,
            options=q.get_options_list(),
            order_number=q.order_number,
        )
        for q in exam.questions
    ]

    return ExamPublicResponse(
        id=exam.id,
        lesson_id=exam.lesson_id,
        title=exam.title,
        pass_percentage=exam.pass_percentage,
        question_count=len(questions),
        questions=questions,
    )


@app.get(
    "/courses/{course_id}/exam",
    response_model=ExamPublicResponse,
    tags=["Exams", "Courses"],
    summary="Retrieve the final course assessment exam (correct answers omitted)",
)
def get_course_exam(course_id: int, db: Session = Depends(get_db)):
    course = db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    exam = course.exam or next((l.exam for l in reversed(course.lessons) if l.exam), None)
    if not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No assessment exam is configured for this course",
        )

    return get_exam(exam_id=exam.id, db=db)


@app.get(
    "/lessons/{lesson_id}/exam",
    response_model=ExamPublicResponse,
    tags=["Exams"],
    summary="Retrieve the exam attached to a specific lesson",
)
def get_lesson_exam(lesson_id: int, db: Session = Depends(get_db)):
    lesson = db.get(Lesson, lesson_id)
    if lesson is None or not lesson.course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found",
        )

    if not lesson.exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No assessment exam is configured for this lesson",
        )

    return get_exam(exam_id=lesson.exam.id, db=db)


@app.post(
    "/exams/{exam_id}/submit",
    response_model=ExamResultResponse,
    tags=["Exams"],
    summary="Submit exam answers and receive server-calculated score and results",
)
def submit_exam(
    exam_id: int,
    submission: ExamSubmissionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    exam = db.get(Exam, exam_id)
    if exam is None or not is_exam_published(exam):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam not found",
        )

    questions = exam.questions
    if not questions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This exam has no configured questions.",
        )

    # Map user answers
    submitted_answers: dict[int, int] = {
        item.question_id: item.selected_option_index
        for item in submission.answers
    }

    # Verify that all submitted question IDs belong to this exam
    question_map = {q.id: q for q in questions}
    for q_id in submitted_answers:
        if q_id not in question_map:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Question ID {q_id} does not belong to this exam.",
            )

    # Calculate score strictly on the backend
    score = 0
    question_details: list[QuestionResultDetail] = []

    for q in questions:
        options = q.get_options_list()
        selected_index = submitted_answers.get(q.id)

        # Validate selected option range
        if selected_index is not None and (selected_index < 0 or selected_index >= len(options)):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Selected option index {selected_index} is out of bounds for question ID {q.id}.",
            )

        is_correct = (selected_index is not None and selected_index == q.correct_option_index)
        if is_correct:
            score += 1

        question_details.append(
            QuestionResultDetail(
                question_id=q.id,
                question_text=q.question_text,
                options=options,
                selected_option_index=selected_index,
                correct_option_index=q.correct_option_index,
                is_correct=is_correct,
                explanation=q.explanation,
            )
        )

    total_questions = len(questions)
    percentage = round((score / total_questions) * 100.0, 2)
    passed = percentage >= exam.pass_percentage
    now = datetime.now(timezone.utc)

    attempt = ExamAttempt(
        user_id=current_user.id,
        exam_id=exam.id,
        score=score,
        total_questions=total_questions,
        passed=passed,
        attempted_at=now,
        answers_summary=json.dumps(submitted_answers),
    )
    db.add(attempt)

    try:
        db.commit()
        db.refresh(attempt)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record exam attempt in database.",
        )

    return ExamResultResponse(
        attempt_id=attempt.id,
        exam_id=exam.id,
        exam_title=exam.title,
        score=score,
        total_questions=total_questions,
        percentage=percentage,
        pass_percentage=exam.pass_percentage,
        passed=passed,
        attempted_at=attempt.attempted_at,
        details=question_details,
    )


@app.get(
    "/exams/{exam_id}/attempts",
    response_model=list[ExamAttemptSummaryResponse],
    tags=["Exams"],
    summary="View previous exam attempts and results for the authenticated user",
)
def get_exam_attempts(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    exam = db.get(Exam, exam_id)
    if exam is None or not is_exam_published(exam):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam not found",
        )

    attempts = (
        db.query(ExamAttempt)
        .filter(
            ExamAttempt.exam_id == exam_id,
            ExamAttempt.user_id == current_user.id,
        )
        .order_by(ExamAttempt.attempted_at.desc())
        .all()
    )

    return [
        ExamAttemptSummaryResponse(
            attempt_id=a.id,
            exam_id=a.exam_id,
            score=a.score,
            total_questions=a.total_questions,
            percentage=(
                round((a.score / a.total_questions) * 100.0, 2)
                if a.total_questions > 0
                else 0.0
            ),
            passed=a.passed,
            attempted_at=a.attempted_at,
        )
        for a in attempts
    ]


@app.get(
    "/courses/{course_id}/attempts",
    response_model=list[ExamAttemptSummaryResponse],
    tags=["Exams", "Courses"],
    summary="View authenticated user's attempts on this course's assessment",
)
def get_course_exam_attempts(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    course = db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    exam = course.exam or next((l.exam for l in reversed(course.lessons) if l.exam), None)
    if not exam:
        return []

    return get_exam_attempts(exam_id=exam.id, current_user=current_user, db=db)


@app.get(
    "/exam-attempts/{attempt_id}",
    response_model=ExamAttemptSummaryResponse,
    tags=["Exams"],
    summary="Retrieve summary of a specific exam attempt",
)
def get_exam_attempt_detail(
    attempt_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    attempt = db.get(ExamAttempt, attempt_id)
    if attempt is None or attempt.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam attempt not found",
        )

    percentage = (
        round((attempt.score / attempt.total_questions) * 100.0, 2)
        if attempt.total_questions > 0
        else 0.0
    )

    return ExamAttemptSummaryResponse(
        attempt_id=attempt.id,
        exam_id=attempt.exam_id,
        score=attempt.score,
        total_questions=attempt.total_questions,
        percentage=percentage,
        passed=attempt.passed,
        attempted_at=attempt.attempted_at,
    )


@app.get(
    "/exam-attempts/{attempt_id}/result",
    response_model=ExamResultResponse,
    tags=["Exams"],
    summary="Retrieve full question-by-question review for an exam attempt",
)
def get_exam_attempt_result(
    attempt_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    attempt = db.get(ExamAttempt, attempt_id)
    if attempt is None or attempt.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam attempt not found",
        )

    exam = attempt.exam
    submitted_answers: dict[int, int] = {}
    if attempt.answers_summary:
        try:
            submitted_answers = {
                int(k): v for k, v in json.loads(attempt.answers_summary).items()
            }
        except Exception:
            pass

    question_details: list[QuestionResultDetail] = []
    for q in exam.questions:
        options = q.get_options_list()
        selected_index = submitted_answers.get(q.id)
        is_correct = selected_index is not None and selected_index == q.correct_option_index
        question_details.append(
            QuestionResultDetail(
                question_id=q.id,
                question_text=q.question_text,
                options=options,
                selected_option_index=selected_index,
                correct_option_index=q.correct_option_index,
                is_correct=is_correct,
                explanation=q.explanation,
            )
        )

    total_questions = attempt.total_questions or len(exam.questions)
    percentage = (
        round((attempt.score / total_questions) * 100.0, 2)
        if total_questions > 0
        else 0.0
    )

    return ExamResultResponse(
        attempt_id=attempt.id,
        exam_id=exam.id,
        exam_title=exam.title,
        score=attempt.score,
        total_questions=total_questions,
        percentage=percentage,
        pass_percentage=exam.pass_percentage,
        passed=attempt.passed,
        attempted_at=attempt.attempted_at,
        details=question_details,
    )


@app.get(
    "/exams/{exam_id}/latest-result",
    response_model=ExamResultResponse,
    tags=["Exams"],
    summary="Retrieve the authenticated user's latest full exam result and review",
)
def get_latest_exam_result(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    latest_attempt = (
        db.query(ExamAttempt)
        .filter(
            ExamAttempt.exam_id == exam_id,
            ExamAttempt.user_id == current_user.id,
        )
        .order_by(ExamAttempt.attempted_at.desc())
        .first()
    )
    if not latest_attempt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No previous attempts found for this exam.",
        )

    return get_exam_attempt_result(attempt_id=latest_attempt.id, current_user=current_user, db=db)

