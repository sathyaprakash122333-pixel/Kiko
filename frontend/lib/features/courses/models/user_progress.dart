/// Domain model for comprehensive student learning progress
class CourseProgressItem {
  final int courseId;
  final String courseTitle;
  final String language;
  final int totalLessons;
  final int completedLessons;
  final double completionPercentage;
  final String testStatus; // 'not_attempted', 'passed', 'failed'
  final int? testScore;
  final int? testTotalQuestions;
  final int? examId;

  const CourseProgressItem({
    required this.courseId,
    required this.courseTitle,
    required this.language,
    required this.totalLessons,
    required this.completedLessons,
    required this.completionPercentage,
    required this.testStatus,
    this.testScore,
    this.testTotalQuestions,
    this.examId,
  });

  factory CourseProgressItem.fromJson(Map<String, dynamic> json) {
    return CourseProgressItem(
      courseId: json['course_id'] as int,
      courseTitle: json['course_title'] as String? ?? 'Course',
      language: json['language'] as String? ?? 'General',
      totalLessons: json['total_lessons'] as int? ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      testStatus: json['test_status'] as String? ?? 'not_attempted',
      testScore: json['test_score'] as int?,
      testTotalQuestions: json['test_total_questions'] as int?,
      examId: json['exam_id'] as int?,
    );
  }
}

class RecentTestAttemptItem {
  final int attemptId;
  final int examId;
  final int courseId;
  final String courseTitle;
  final String language;
  final int score;
  final int totalQuestions;
  final double percentage;
  final bool passed;
  final DateTime attemptedAt;

  const RecentTestAttemptItem({
    required this.attemptId,
    required this.examId,
    required this.courseId,
    required this.courseTitle,
    required this.language,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    required this.attemptedAt,
  });

  factory RecentTestAttemptItem.fromJson(Map<String, dynamic> json) {
    return RecentTestAttemptItem(
      attemptId: json['attempt_id'] as int,
      examId: json['exam_id'] as int,
      courseId: json['course_id'] as int? ?? 1,
      courseTitle: json['course_title'] as String? ?? 'Course Test',
      language: json['language'] as String? ?? 'General',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      attemptedAt: DateTime.tryParse(json['attempted_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class UserOverallProgress {
  final int userId;
  final int totalEnrolledCourses;
  final int completedLessonsCount;
  final int passedExamsCount;
  final int totalPublishedLessons;
  final int totalPublishedExams;
  final double overallCompletionPercentage;
  final double averageTestScore;
  final List<CourseProgressItem> courseProgress;
  final List<RecentTestAttemptItem> recentTestAttempts;

  const UserOverallProgress({
    required this.userId,
    required this.totalEnrolledCourses,
    required this.completedLessonsCount,
    required this.passedExamsCount,
    required this.totalPublishedLessons,
    required this.totalPublishedExams,
    required this.overallCompletionPercentage,
    required this.averageTestScore,
    required this.courseProgress,
    required this.recentTestAttempts,
  });

  factory UserOverallProgress.fromJson(Map<String, dynamic> json) {
    final rawCourseProgress = json['course_progress'] as List<dynamic>? ?? [];
    final rawAttempts = json['recent_test_attempts'] as List<dynamic>? ?? [];

    return UserOverallProgress(
      userId: json['user_id'] as int? ?? 0,
      totalEnrolledCourses: json['total_enrolled_courses'] as int? ?? 0,
      completedLessonsCount: json['completed_lessons_count'] as int? ?? 0,
      passedExamsCount: json['passed_exams_count'] as int? ?? 0,
      totalPublishedLessons: json['total_published_lessons'] as int? ?? 20,
      totalPublishedExams: json['total_published_exams'] as int? ?? 2,
      overallCompletionPercentage: (json['overall_completion_percentage'] as num?)?.toDouble() ?? 0.0,
      averageTestScore: (json['average_test_score'] as num?)?.toDouble() ?? 0.0,
      courseProgress: rawCourseProgress
          .map((item) => CourseProgressItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentTestAttempts: rawAttempts
          .map((item) => RecentTestAttemptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory UserOverallProgress.empty() {
    return const UserOverallProgress(
      userId: 0,
      totalEnrolledCourses: 0,
      completedLessonsCount: 0,
      passedExamsCount: 0,
      totalPublishedLessons: 20,
      totalPublishedExams: 2,
      overallCompletionPercentage: 0.0,
      averageTestScore: 0.0,
      courseProgress: [],
      recentTestAttempts: [],
    );
  }
}

/// Course-level progress with specific completed lesson IDs matching GET /courses/{course_id}/progress
class CourseProgressDetail {
  final int courseId;
  final String courseTitle;
  final int totalLessons;
  final int completedLessons;
  final double completionPercentage;
  final bool isCompleted;
  final List<int> completedLessonIds;

  const CourseProgressDetail({
    required this.courseId,
    required this.courseTitle,
    required this.totalLessons,
    required this.completedLessons,
    required this.completionPercentage,
    required this.isCompleted,
    required this.completedLessonIds,
  });

  factory CourseProgressDetail.fromJson(Map<String, dynamic> json) {
    final rawIds = json['completed_lesson_ids'] as List<dynamic>? ?? [];
    return CourseProgressDetail(
      courseId: json['course_id'] as int? ?? 0,
      courseTitle: json['course_title'] as String? ?? '',
      totalLessons: json['total_lessons'] as int? ?? 0,
      completedLessons: json['completed_lessons'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedLessonIds: rawIds.map((e) => e as int).toList(),
    );
  }

  factory CourseProgressDetail.empty(int courseId) {
    return CourseProgressDetail(
      courseId: courseId,
      courseTitle: '',
      totalLessons: 0,
      completedLessons: 0,
      completionPercentage: 0.0,
      isCompleted: false,
      completedLessonIds: const [],
    );
  }
}

/// Result from POST /lessons/{lesson_id}/complete
class LessonProgressResult {
  final int lessonId;
  final bool isCompleted;
  final DateTime? completedAt;

  const LessonProgressResult({
    required this.lessonId,
    required this.isCompleted,
    this.completedAt,
  });

  factory LessonProgressResult.fromJson(Map<String, dynamic> json) {
    return LessonProgressResult(
      lessonId: json['lesson_id'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }
}
