from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# User Schemas
# ---------------------------------------------------------------------------

class UserBase(BaseModel):
    firebase_uid: str
    email: str | None = None
    display_name: str | None = None


class UserResponse(UserBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserProfileResponse(BaseModel):
    id: int
    user_id: int | None = None
    firebase_uid: str
    email: str | None = None
    display_name: str | None = None
    full_name: str | None = None
    date_of_birth: str | None = None
    gender: str | None = None
    city: str | None = None
    institution: str | None = None
    degree: str | None = None
    department: str | None = None
    academic_year: str | None = None
    semester: str | None = None
    created_at: datetime
    updated_at: datetime | None = None
    last_login_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class UserProfileDetailResponse(UserProfileResponse):
    pass


class UserProfileUpdateRequest(BaseModel):
    display_name: str | None = Field(
        None,
        min_length=1,
        max_length=150,
        description="Updated display name",
    )
    full_name: str | None = Field(
        None,
        min_length=1,
        max_length=150,
        description="Updated full name",
    )
    date_of_birth: str | None = Field(
        None,
        max_length=30,
        description="Date of birth (ISO or formatted string)",
    )
    gender: str | None = Field(
        None,
        max_length=50,
        description="Gender selection",
    )
    city: str | None = Field(
        None,
        max_length=100,
        description="City of residence",
    )
    institution: str | None = Field(
        None,
        max_length=200,
        description="College or institution name",
    )
    degree: str | None = Field(
        None,
        max_length=150,
        description="Degree or course of study",
    )
    department: str | None = Field(
        None,
        max_length=150,
        description="Academic department",
    )
    academic_year: str | None = Field(
        None,
        max_length=50,
        description="Current academic year (e.g. 3rd Year)",
    )
    semester: str | None = Field(
        None,
        max_length=50,
        description="Current semester (e.g. 5th Semester)",
    )


class UserProfileUpdatePayload(UserProfileUpdateRequest):
    pass


class UserStreakResponse(BaseModel):
    current_streak: int
    longest_streak: int
    last_activity_date: str | None = None
    active_today: bool
    total_active_days: int
    recent_active_dates: list[str] = []

    model_config = ConfigDict(from_attributes=True)



# ---------------------------------------------------------------------------
# Lesson Schemas
# ---------------------------------------------------------------------------

class LessonSummaryResponse(BaseModel):
    id: int
    course_id: int
    title: str
    order_number: int
    has_exam: bool = False

    model_config = ConfigDict(from_attributes=True)


class LessonDetailResponse(BaseModel):
    id: int
    course_id: int
    title: str
    content: str
    order_number: int
    has_exam: bool = False
    exam_id: int | None = None

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Course Schemas
# ---------------------------------------------------------------------------

class CourseSummaryResponse(BaseModel):
    id: int
    title: str
    description: str
    language: str
    lesson_count: int

    model_config = ConfigDict(from_attributes=True)


class CourseDetailResponse(BaseModel):
    id: int
    title: str
    description: str
    language: str
    lessons: list[LessonSummaryResponse]
    exam_id: int | None = None
    exam_title: str | None = None

    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Progress Schemas
# ---------------------------------------------------------------------------

class LessonCompletionRequest(BaseModel):
    completed: bool = True


class LessonProgressResponse(BaseModel):
    lesson_id: int
    is_completed: bool
    completed_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class CourseProgressResponse(BaseModel):
    course_id: int
    course_title: str
    total_lessons: int
    completed_lessons: int
    completion_percentage: float
    is_completed: bool
    completed_lesson_ids: list[int]


class CourseProgressItem(BaseModel):
    course_id: int
    course_title: str
    language: str
    total_lessons: int
    completed_lessons: int
    completion_percentage: float
    test_status: str  # 'not_attempted', 'passed', 'failed'
    test_score: int | None = None
    test_total_questions: int | None = None
    exam_id: int | None = None


class RecentTestAttemptItem(BaseModel):
    attempt_id: int
    exam_id: int
    course_id: int
    course_title: str
    language: str
    score: int
    total_questions: int
    percentage: float
    passed: bool
    attempted_at: datetime


class UserOverallProgressResponse(BaseModel):
    user_id: int
    total_enrolled_courses: int
    completed_lessons_count: int
    passed_exams_count: int
    recent_completed_lessons: list[LessonProgressResponse] = []
    total_published_lessons: int = 0
    total_published_exams: int = 0
    overall_completion_percentage: float = 0.0
    average_test_score: float = 0.0
    course_progress: list[CourseProgressItem] = []
    recent_test_attempts: list[RecentTestAttemptItem] = []


# ---------------------------------------------------------------------------
# Exam & Question Schemas
# ---------------------------------------------------------------------------

class ExamQuestionPublicResponse(BaseModel):
    """
    Public representation of a question shown to students taking an exam.
    NOTE: correct_option_index and explanation are strictly omitted.
    """
    id: int
    question_text: str
    options: list[str]
    order_number: int

    model_config = ConfigDict(from_attributes=True)


class ExamPublicResponse(BaseModel):
    """
    Exam details with questions provided for taking an assessment.
    """
    id: int
    lesson_id: int
    title: str
    pass_percentage: int
    question_count: int
    questions: list[ExamQuestionPublicResponse]

    model_config = ConfigDict(from_attributes=True)


class QuestionAnswer(BaseModel):
    question_id: int
    selected_option_index: int = Field(ge=0, description="0-based index of selected option")


class ExamSubmissionRequest(BaseModel):
    answers: list[QuestionAnswer] = Field(min_length=1, description="List of question answers")


class QuestionResultDetail(BaseModel):
    question_id: int
    question_text: str
    options: list[str]
    selected_option_index: int | None
    correct_option_index: int
    is_correct: bool
    explanation: str | None = None


class ExamResultResponse(BaseModel):
    attempt_id: int
    exam_id: int
    exam_title: str
    score: int
    total_questions: int
    percentage: float
    pass_percentage: int
    passed: bool
    attempted_at: datetime
    details: list[QuestionResultDetail]


class ExamAttemptSummaryResponse(BaseModel):
    attempt_id: int
    exam_id: int
    score: int
    total_questions: int
    percentage: float
    passed: bool
    attempted_at: datetime

    model_config = ConfigDict(from_attributes=True)
