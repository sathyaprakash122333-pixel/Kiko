# Kiko Backend API

Kiko is a structured programming-learning platform for beginners, focusing on clear explanations, progressive lessons, learning progress tracking, assessments, and verifiable exam results.

Kiko is designed strictly as a standard educational platform, deliberately free of gamification elements (no XP, streaks, points, leaderboards, rewards, or achievements).

---

## Architecture Overview

- **Framework**: FastAPI (Python 3.14 / 3.12+)
- **Database**: SQLite with SQLAlchemy 2.0 ORM (`backend/kiko.db`)
- **Authentication**: Firebase Authentication with Bearer ID-token verification
- **Validation**: Pydantic v2 request/response schemas
- **Frontend Integration**: Flutter cross-platform app (`frontend/`)

---

## Directory Structure

```
backend/
├── auth.py              # Firebase token verification & get_current_user dependency
├── database.py          # SQLite engine, connection arguments, and SessionLocal
├── init_db.py           # Table initialization and safe column migrations
├── kiko.db              # SQLite database file
├── kiko.db.bak          # Database safety backup
├── main.py              # FastAPI application, routing, and business logic
├── models.py            # SQLAlchemy models (Courses, Lessons, Exams, Progress)
├── schemas.py           # Pydantic validation & response models
├── seed_data.py         # Seed script for real beginner course content
└── tests/
    ├── test_api.py      # Automated API, scoring, and progress test suite
    └── test_auth.py     # Token verification and auth behavior unit tests
```

---

## Configuration & Environment Variables

The backend works out-of-the-box with safe local defaults. You can configure it via environment variables:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `DATABASE_URL` | `sqlite:///<absolute_path>/kiko.db` | SQLAlchemy database connection string |
| `FIREBASE_PROJECT_ID` | `kiko-894c7` | Firebase project ID corresponding to the Flutter client |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | *(None)* | Optional path to a Google Cloud service account JSON file |
| `KIKO_AUTH_DEV_MODE` | `false` | When explicitly set to `true`, permits `dev:<uid>` tokens for offline testing |

---

## Setup & Run Commands

### 1. Activate Virtual Environment

```bash
cd backend
source .venv/bin/activate
```

*(Or use `.venv/bin/python` directly from the repository root).*

### 2. Verify Database Schema & Migrations

```bash
python init_db.py
```
This runs `Base.metadata.create_all` and verifies that all required columns (e.g. `created_at` on `users`, `completed_at` on `lesson_progress`, `exam_questions` table) are present without altering or losing existing records.

### 3. Populate Seed Course Content (Optional for Development)

```bash
python seed_data.py
```
This populates real starter courses ("Introduction to C Programming" and "Python Fundamentals for Beginners") with full lesson text and assessment questions.
> **Note**: Seed scripts strictly create courses, lessons, and exam questions. No fake users, mock progress records, or fake exam results are ever seeded.

### 4. Start the Development Server

```bash
uvicorn main:app --reload --port 8000
```

Once running, interactive documentation is available at:
- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## Automated Testing

Run the test suite using Python's built-in `unittest` framework:

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

All 12 automated unit tests run against an isolated in-memory SQLite database, ensuring test runs never modify or pollute the development database.

---

## API Endpoints

### Public Endpoints (Course & Lesson Content)

These endpoints allow students to browse curriculum and read lesson material without requiring authentication:

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/` | API welcome and version metadata |
| `GET` | `/health` | Service health status and database connectivity check |
| `GET` | `/courses` | List all published courses with lesson counts |
| `GET` | `/courses/{course_id}` | Retrieve course details and lesson syllabus |
| `GET` | `/courses/{course_id}/lessons` | List lessons for a specific course |
| `GET` | `/courses/{course_id}/exam` | Retrieve the final assessment exam for a course (*answers strictly omitted*) |
| `GET` | `/lessons/{lesson_id}` | Retrieve full lesson content, order, and exam attachment info |
| `GET` | `/exams/{exam_id}` | Retrieve assessment questions (*answers strictly omitted*) |
| `GET` | `/lessons/{lesson_id}/exam` | Retrieve the exam attached to a specific lesson |

### Protected Endpoints (User Data & Assessments)

These endpoints **require a valid Firebase Bearer token** (`Authorization: Bearer <token>`). Unauthenticated requests return `401 Unauthorized`.

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/users/me` | Retrieve the authenticated user's profile |
| `PATCH` | `/users/me` | Update permitted profile fields (display name) |
| `POST` | `/lessons/{lesson_id}/complete` | Mark a lesson as completed (or incomplete) for the current user |
| `GET` | `/courses/{course_id}/progress` | View lesson completion count and percentage for a course |
| `GET` | `/courses/{course_id}/attempts` | View authenticated user's attempts on a course's final assessment |
| `GET` | `/users/me/progress` | View overall learning progress across all enrolled courses |
| `POST` | `/exams/{exam_id}/submit` | Submit answers for server-side evaluation and score calculation |
| `GET` | `/exams/{exam_id}/attempts` | List past exam attempts and score history for current user |
| `GET` | `/exams/{exam_id}/latest-result` | Retrieve authenticated user's latest full exam result and question review |
| `GET` | `/exam-attempts/{attempt_id}` | Retrieve summary of a specific previous exam attempt |
| `GET` | `/exam-attempts/{attempt_id}/result` | Retrieve full question-by-question review for an exam attempt |

---

## Security & Server-Side Scoring Integrity

1. **Client Scores Never Trusted**:
   - Clients submit only their selected option indices:
     ```json
     {
       "answers": [
         {"question_id": 1, "selected_option_index": 2},
         {"question_id": 2, "selected_option_index": 0}
       ]
     }
     ```
   - The backend checks each answer against `correct_option_index`, calculates the percentage, determines pass/fail against `pass_percentage`, and creates an `ExamAttempt` database record.
2. **Answers Never Leaked Ahead of Time**:
   - `GET /exams/{exam_id}` uses `ExamQuestionPublicResponse`, which excludes `correct_option_index` and `explanation`.
   - Explanations and correct answers are only delivered in the `ExamResultResponse` after submission.
3. **Protected Private Data**:
   - Endpoints modifying progress or recording exam attempts require user authentication. Private records are isolated per `user_id`.

---

## Legacy Gamification Models & Safe Cleanup Plan

The original database schema contained three gamification tables:
- `user_stats` (`xp`, `current_streak`, `longest_streak`, `last_activity_date`)
- `achievements` (`code`, `title`, `description`)
- `user_achievements` (`user_id`, `achievement_id`, `earned_at`)

### Status & Policy:
1. **No Active Use**: Kiko has shifted to a clean, non-gamified educational model. None of the active APIs expose, query, or mutate these tables.
2. **Safe Retention**: Per instructions, existing database records and tables have **not** been dropped automatically to avoid unexpected data loss during active development.
3. **Migration Plan**:
   - **Phase 1 (Current)**: Legacy SQLAlchemy models are annotated as deprecated in `backend/models.py`.
   - **Phase 2 (Pre-Release)**: An explicit database migration script will be executed to drop `user_stats`, `achievements`, and `user_achievements` after verifying any production backup requirements.
