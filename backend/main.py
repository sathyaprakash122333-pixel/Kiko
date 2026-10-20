import hmac
from fastapi import Request
import json
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta, date
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import SessionLocal, get_db
from init_db import init_database
from models import (
    Course, Lesson, Exam, ExamQuestion, ExamAttempt, LessonProgress, User,
    UserProfile, UserLearningActivity
)
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
    UserProfileDetailResponse,
    UserProfileUpdateRequest,
    UserProfileUpdatePayload,
    UserStreakResponse,
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


def record_learning_activity(
    db: Session,
    user: User,
    activity_type: str,
    entity_id: int | None = None,
    activity_datetime: datetime | None = None,
) -> UserLearningActivity:
    now = activity_datetime or datetime.now(timezone.utc)
    activity_date_str = now.strftime("%Y-%m-%d")

    existing = (
        db.query(UserLearningActivity)
        .filter(
            UserLearningActivity.user_id == user.id,
            UserLearningActivity.activity_date == activity_date_str,
            UserLearningActivity.activity_type == activity_type,
            UserLearningActivity.entity_id == entity_id,
        )
        .first()
    )
    if existing:
        return existing

    record = UserLearningActivity(
        user_id=user.id,
        firebase_uid=user.firebase_uid,
        activity_date=activity_date_str,
        activity_type=activity_type,
        entity_id=entity_id,
        created_at=now,
    )
    db.add(record)
    return record


def calculate_user_streak(db: Session, user_id: int) -> UserStreakResponse:
    # Query distinct activity dates from UserLearningActivity
    activity_dates_query = (
        db.query(UserLearningActivity.activity_date)
        .filter(UserLearningActivity.user_id == user_id)
        .distinct()
        .all()
    )
    active_date_strings = set(r[0] for r in activity_dates_query)

    # Include any existing LessonProgress completed_at dates
    lesson_progress_dates = (
        db.query(LessonProgress.completed_at)
        .filter(
            LessonProgress.user_id == user_id,
            LessonProgress.is_completed.is_(True),
            LessonProgress.completed_at.isnot(None),
        )
        .all()
    )
    for (dt,) in lesson_progress_dates:
        if dt:
            active_date_strings.add(dt.strftime("%Y-%m-%d"))

    # Include any passed ExamAttempts
    exam_dates = (
        db.query(ExamAttempt.attempted_at)
        .filter(
            ExamAttempt.user_id == user_id,
            ExamAttempt.passed.is_(True),
            ExamAttempt.attempted_at.isnot(None),
        )
        .all()
    )
    for (dt,) in exam_dates:
        if dt:
            active_date_strings.add(dt.strftime("%Y-%m-%d"))

    parsed_dates: list[date] = []
    for d_str in active_date_strings:
        try:
            parsed_dates.append(datetime.strptime(d_str, "%Y-%m-%d").date())
        except ValueError:
            pass

    parsed_dates.sort()

    if not parsed_dates:
        return UserStreakResponse(
            current_streak=0,
            longest_streak=0,
            last_activity_date=None,
            active_today=False,
            total_active_days=0,
            recent_active_dates=[],
        )

    today = datetime.now(timezone.utc).date()
    yesterday = today - timedelta(days=1)
    active_today = today in parsed_dates
    last_date = parsed_dates[-1]

    # Calculate longest streak
    longest_streak = 0
    current_run = 0
    prev_d = None
    for d in parsed_dates:
        if prev_d is None or d == prev_d + timedelta(days=1):
            current_run += 1
        elif d == prev_d:
            pass
        else:
            current_run = 1
        if current_run > longest_streak:
            longest_streak = current_run
        prev_d = d

    # Calculate current streak:
    # Rule 3: The current streak is the number of consecutive active calendar days
    # ending today, or yesterday if the user has not yet completed an activity today.
    # Rule 4: If the most recent qualifying activity is older than yesterday, current streak is zero.
    current_streak = 0
    if last_date == today or last_date == yesterday:
        date_set = set(parsed_dates)
        check_date = last_date
        while check_date in date_set:
            current_streak += 1
            check_date -= timedelta(days=1)
    else:
        current_streak = 0

    recent_strings = [d.strftime("%Y-%m-%d") for d in parsed_dates[-14:]]

    return UserStreakResponse(
        current_streak=current_streak,
        longest_streak=longest_streak,
        last_activity_date=last_date.strftime("%Y-%m-%d"),
        active_today=active_today,
        total_active_days=len(parsed_dates),
        recent_active_dates=recent_strings,
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

    if is_completed:
        record_learning_activity(
            db=db,
            user=current_user,
            activity_type="lesson_completion",
            entity_id=lesson_id,
            activity_datetime=now,
        )

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
        c_lang = (
            exam.course.language
            if exam and exam.course
            else (
                exam.lesson.course.language
                if exam and exam.lesson and exam.lesson.course
                else "General"
            )
        )
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
# User Profile & Streak Endpoints (Protected)
# ============================================================================

def get_or_create_profile(db: Session, user: User) -> UserProfile:
    profile = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
    if not profile:
        now = datetime.now(timezone.utc)
        profile = UserProfile(
            user_id=user.id,
            firebase_uid=user.firebase_uid,
            email=user.email,
            full_name=user.display_name,
            created_at=now,
            updated_at=now,
        )
        db.add(profile)
        try:
            db.commit()
            db.refresh(profile)
        except Exception as exc:
            db.rollback()
            import logging
            logging.getLogger("kiko").error("Failed to initialize user profile: %s", exc, exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to initialize user profile.",
            )
    return profile


def _build_profile_response(user: User, profile: UserProfile) -> UserProfileDetailResponse:
    raw_name = profile.full_name or user.display_name
    name = raw_name.strip() if (raw_name and raw_name.strip()) else None
    return UserProfileDetailResponse(
        id=profile.id,
        user_id=user.id,
        firebase_uid=user.firebase_uid,
        email=profile.email or user.email,
        full_name=name,
        display_name=name or (user.email.split("@")[0] if user.email else "Learner"),
        date_of_birth=profile.date_of_birth,
        gender=profile.gender,
        city=profile.city,
        institution=profile.institution,
        degree=profile.degree,
        department=profile.department,
        academic_year=profile.academic_year,
        semester=profile.semester,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
        last_login_at=user.last_login_at,
    )


@app.get(
    "/users/me",
    response_model=UserProfileDetailResponse,
    tags=["Users"],
    summary="Retrieve the authenticated user's complete profile",
)
def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = get_or_create_profile(db, current_user)
    return _build_profile_response(current_user, profile)


@app.put(
    "/users/me",
    response_model=UserProfileDetailResponse,
    tags=["Users"],
    summary="Update complete profile fields for the authenticated user",
)
@app.patch(
    "/users/me",
    response_model=UserProfileDetailResponse,
    tags=["Users"],
    summary="Update permitted profile fields for the authenticated user",
)
def update_user_profile(
    payload: UserProfileUpdatePayload,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    user = db.get(User, current_user.id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found in database.",
        )

    profile = get_or_create_profile(db, user)

    # Validate and update full name / display name
    new_name = None
    if payload.full_name is not None:
        trimmed = payload.full_name.strip()
        if not trimmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Full name cannot be empty or only whitespace.",
            )
        new_name = trimmed
    elif payload.display_name is not None:
        trimmed = payload.display_name.strip()
        if not trimmed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Display name cannot be empty or only whitespace.",
            )
        new_name = trimmed

    if new_name is not None:
        profile.full_name = new_name
        user.display_name = new_name

    # Validate date of birth (must not be in future)
    if payload.date_of_birth is not None:
        dob_raw = payload.date_of_birth.strip()
        if dob_raw:
            parsed_date = None
            for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d", "%b %d, %Y"):
                try:
                    parsed_date = datetime.strptime(dob_raw, fmt).date()
                    break
                except ValueError:
                    continue
            if parsed_date:
                today_utc = datetime.now(timezone.utc).date()
                if parsed_date > today_utc:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Date of birth cannot be in the future.",
                    )
                profile.date_of_birth = parsed_date.strftime("%b %d, %Y")
            else:
                profile.date_of_birth = dob_raw[:30]
        else:
            profile.date_of_birth = None

    # Update optional fields
    if payload.gender is not None:
        profile.gender = payload.gender.strip() if payload.gender.strip() else None
    if payload.city is not None:
        profile.city = payload.city.strip() if payload.city.strip() else None
    if payload.institution is not None:
        profile.institution = payload.institution.strip() if payload.institution.strip() else None
    if payload.degree is not None:
        profile.degree = payload.degree.strip() if payload.degree.strip() else None
    if payload.department is not None:
        profile.department = payload.department.strip() if payload.department.strip() else None
    if payload.academic_year is not None:
        profile.academic_year = payload.academic_year.strip() if payload.academic_year.strip() else None
    if payload.semester is not None:
        profile.semester = payload.semester.strip() if payload.semester.strip() else None

    profile.updated_at = datetime.now(timezone.utc)

    try:
        db.commit()
        db.refresh(profile)
        db.refresh(user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update user profile in database.",
        )

    return _build_profile_response(user, profile)


@app.get(
    "/users/me/streak",
    response_model=UserStreakResponse,
    tags=["Users"],
    summary="Get persistent learning streak data for the authenticated user",
)
def get_user_streak(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return calculate_user_streak(db, current_user.id)



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

    if passed:
        record_learning_activity(
            db=db,
            user=current_user,
            activity_type="exam_completion",
            entity_id=exam.id,
            activity_datetime=now,
        )

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

# Temporary protected content import endpoint
@app.post("/admin/import-content", tags=["Admin"])
async def import_content(
    request: Request,
    db: Session = Depends(get_db),
):
    expected_token = os.getenv("KIKO_IMPORT_TOKEN", "")
    supplied_token = request.headers.get("X-Import-Token", "")
    print(
    "IMPORT TOKEN CHECK:",
    "expected length:", len(expected_token),
    "supplied length:", len(supplied_token),
)

    

    if not expected_token or not hmac.compare_digest(
        supplied_token, expected_token
    ):
        raise HTTPException(status_code=403, detail="Forbidden")

    data = await request.json()

    required_tables = {
        "courses", "lessons", "exams", "exam_questions"
    }
    if not isinstance(data, dict) or set(data.keys()) != required_tables:
        raise HTTPException(status_code=400, detail="Invalid import data")

    try:
        for table in required_tables:
            if not isinstance(data[table], list):
                raise ValueError(f"{table} must be a list")

        # Validate relationships before changing anything.
        course_ids = {r["id"] for r in data["courses"]}
        lesson_ids = {r["id"] for r in data["lessons"]}
        exam_ids = {r["id"] for r in data["exams"]}

        if any(r["course_id"] not in course_ids for r in data["lessons"]):
            raise ValueError("A lesson references a missing course")
        if any(
            r["lesson_id"] not in lesson_ids
            or (
                r.get("course_id") is not None
                and r["course_id"] not in course_ids
            )
            for r in data["exams"]
        ):
            raise ValueError("An exam references missing content")
        if any(r["exam_id"] not in exam_ids for r in data["exam_questions"]):
            raise ValueError("A question references a missing exam")

        # Do not overwrite a database that already has course content.
        if (
            db.query(Course).count()
            or db.query(Lesson).count()
            or db.query(Exam).count()
            or db.query(ExamQuestion).count()
        ):
            raise HTTPException(
                status_code=409,
                detail="Database already contains course content; import cancelled",
            )

        # Insert in foreign-key order and preserve the original IDs.
        for row in data["courses"]:
            db.add(Course(**row))
        db.flush()

        for row in data["lessons"]:
            db.add(Lesson(**row))
        db.flush()

        for row in data["exams"]:
            db.add(Exam(**row))
        db.flush()

        for row in data["exam_questions"]:
            db.add(ExamQuestion(**row))

        db.commit()

        return {
            "status": "success",
            "imported": {
                table: len(data[table]) for table in sorted(required_tables)
            },
        }

    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Import failed; transaction rolled back: {type(exc).__name__}",
        )
