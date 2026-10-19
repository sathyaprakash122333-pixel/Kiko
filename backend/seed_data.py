import json
from sqlalchemy.orm import Session
from database import SessionLocal
from models import Course, Lesson, Exam, ExamQuestion
from course_data import (
    C_COURSE_METADATA,
    C_LESSONS,
    C_EXAM_QUESTIONS,
    PYTHON_COURSE_METADATA,
    PYTHON_LESSONS,
    PYTHON_EXAM_QUESTIONS,
)


def _seed_single_course(
    db: Session,
    meta: dict,
    lessons_data: list[dict],
    exam_questions_data: list[dict],
    default_exam_title: str,
) -> Course:
    # 1. Get or create Course
    course = (
        db.query(Course)
        .filter((Course.title == meta["title"]) | (Course.language == meta["language"]))
        .first()
    )
    if not course:
        course = Course(
            title=meta["title"],
            description=meta["description"],
            language=meta["language"],
            is_published=meta["is_published"],
        )
        db.add(course)
        db.flush()
    else:
        course.title = meta["title"]
        course.description = meta["description"]
        course.language = meta["language"]
        course.is_published = meta["is_published"]
        db.flush()

    # 2. Upsert lessons preserving IDs
    lessons_by_order: dict[int, Lesson] = {}
    for l_data in lessons_data:
        order = l_data["order_number"]
        lesson = (
            db.query(Lesson)
            .filter(Lesson.course_id == course.id, Lesson.order_number == order)
            .first()
        )
        if lesson:
            lesson.title = l_data["title"]
            lesson.content = l_data["content"]
        else:
            lesson = Lesson(
                course_id=course.id,
                title=l_data["title"],
                content=l_data["content"],
                order_number=order,
            )
            db.add(lesson)
        db.flush()
        lessons_by_order[order] = lesson

    # 3. Final lesson (e.g. Lesson 10) holds the final exam association
    final_order = max(lessons_by_order.keys())
    final_lesson = lessons_by_order[final_order]

    # 4. Get or create Exam for this course
    exam = (
        db.query(Exam)
        .filter((Exam.course_id == course.id) | (Exam.lesson_id == final_lesson.id))
        .first()
    )
    if not exam:
        # Check if an exam was previously attached to an earlier lesson in this course
        earlier_lesson_ids = [l.id for l in lessons_by_order.values()]
        exam = (
            db.query(Exam)
            .filter(Exam.lesson_id.in_(earlier_lesson_ids))
            .first()
        )

    if not exam:
        exam = Exam(
            lesson_id=final_lesson.id,
            course_id=course.id,
            title=default_exam_title,
            pass_percentage=70,
        )
        db.add(exam)
        db.flush()
    else:
        exam.lesson_id = final_lesson.id
        exam.course_id = course.id
        exam.title = default_exam_title
        exam.pass_percentage = 70
        db.flush()

    # 5. Upsert 20 Questions
    for q_data in exam_questions_data:
        order = q_data["order_number"]
        q = (
            db.query(ExamQuestion)
            .filter(ExamQuestion.exam_id == exam.id, ExamQuestion.order_number == order)
            .first()
        )
        options_json = json.dumps(q_data["options"])
        if q:
            q.question_text = q_data["question_text"]
            q.options = options_json
            q.correct_option_index = q_data["correct_option_index"]
            q.explanation = q_data.get("explanation", "")
        else:
            q = ExamQuestion(
                exam_id=exam.id,
                question_text=q_data["question_text"],
                options=options_json,
                correct_option_index=q_data["correct_option_index"],
                explanation=q_data.get("explanation", ""),
                order_number=order,
            )
            db.add(q)

    db.flush()
    return course


def seed_courses(db: Session) -> None:
    """
    Seeds comprehensive educational courses, 10 lessons each, and 20-question final exams.
    Idempotent: updates existing lessons and questions in-place, never duplicates records.
    """
    c_course = _seed_single_course(
        db=db,
        meta=C_COURSE_METADATA,
        lessons_data=C_LESSONS,
        exam_questions_data=C_EXAM_QUESTIONS,
        default_exam_title="C Programming Comprehensive Final Assessment",
    )

    py_course = _seed_single_course(
        db=db,
        meta=PYTHON_COURSE_METADATA,
        lessons_data=PYTHON_LESSONS,
        exam_questions_data=PYTHON_EXAM_QUESTIONS,
        default_exam_title="Python Fundamentals Comprehensive Final Assessment",
    )

    db.commit()

    c_lessons_count = db.query(Lesson).filter(Lesson.course_id == c_course.id).count()
    py_lessons_count = db.query(Lesson).filter(Lesson.course_id == py_course.id).count()
    c_exam = db.query(Exam).filter(Exam.course_id == c_course.id).first()
    py_exam = db.query(Exam).filter(Exam.course_id == py_course.id).first()
    c_q_count = len(c_exam.questions) if c_exam else 0
    py_q_count = len(py_exam.questions) if py_exam else 0

    print(
        f"Seed data updated successfully: C Course ({c_lessons_count} lessons, {c_q_count} questions), "
        f"Python Course ({py_lessons_count} lessons, {py_q_count} questions)."
    )


if __name__ == "__main__":
    db = SessionLocal()
    try:
        seed_courses(db)
    finally:
        db.close()
