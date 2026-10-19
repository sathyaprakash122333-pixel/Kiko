/// Domain models representing public exams, attempts, scoring, and reviews
class ExamQuestionPublic {
  final int id;
  final String questionText;
  final List<String> options;
  final int orderNumber;

  const ExamQuestionPublic({
    required this.id,
    required this.questionText,
    required this.options,
    required this.orderNumber,
  });

  factory ExamQuestionPublic.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return ExamQuestionPublic(
      id: json['id'] as int,
      questionText: json['question_text'] as String? ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      orderNumber: json['order_number'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'options': options,
      'order_number': orderNumber,
    };
  }
}

/// Public exam structure delivered to the client without answer leakage
class ExamPublic {
  final int id;
  final int? courseId;
  final int? lessonId;
  final String title;
  final double passPercentage;
  final int questionCount;
  final List<ExamQuestionPublic> questions;

  const ExamPublic({
    required this.id,
    this.courseId,
    this.lessonId,
    required this.title,
    required this.passPercentage,
    required this.questionCount,
    required this.questions,
  });

  factory ExamPublic.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return ExamPublic(
      id: json['id'] as int,
      courseId: json['course_id'] as int?,
      lessonId: json['lesson_id'] as int?,
      title: json['title'] as String? ?? 'Course Assessment',
      passPercentage: (json['pass_percentage'] as num?)?.toDouble() ?? 70.0,
      questionCount: json['question_count'] as int? ?? rawQuestions.length,
      questions: rawQuestions
          .map((q) => ExamQuestionPublic.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Question result breakdown showing user selection, answer key, and explanation
class QuestionResultDetail {
  final int questionId;
  final String questionText;
  final List<String> options;
  final int? selectedOptionIndex;
  final int correctOptionIndex;
  final bool isCorrect;
  final String explanation;

  const QuestionResultDetail({
    required this.questionId,
    required this.questionText,
    required this.options,
    this.selectedOptionIndex,
    required this.correctOptionIndex,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionResultDetail.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return QuestionResultDetail(
      questionId: json['question_id'] as int,
      questionText: json['question_text'] as String? ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      selectedOptionIndex: json['selected_option_index'] as int?,
      correctOptionIndex: json['correct_option_index'] as int? ?? 0,
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

/// Complete assessment score and review
class ExamResult {
  final int attemptId;
  final int examId;
  final String examTitle;
  final int score;
  final int totalQuestions;
  final double percentage;
  final double passPercentage;
  final bool passed;
  final DateTime attemptedAt;
  final List<QuestionResultDetail> details;

  const ExamResult({
    required this.attemptId,
    required this.examId,
    required this.examTitle,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passPercentage,
    required this.passed,
    required this.attemptedAt,
    required this.details,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] as List<dynamic>? ?? [];
    return ExamResult(
      attemptId: json['attempt_id'] as int,
      examId: json['exam_id'] as int,
      examTitle: json['exam_title'] as String? ?? 'Assessment',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? rawDetails.length,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passPercentage: (json['pass_percentage'] as num?)?.toDouble() ?? 70.0,
      passed: json['passed'] as bool? ?? false,
      attemptedAt: DateTime.tryParse(json['attempted_at'] as String? ?? '') ?? DateTime.now(),
      details: rawDetails
          .map((d) => QuestionResultDetail.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Summary item for attempt history
class ExamAttemptSummary {
  final int attemptId;
  final int examId;
  final int score;
  final int totalQuestions;
  final double percentage;
  final bool passed;
  final DateTime attemptedAt;

  const ExamAttemptSummary({
    required this.attemptId,
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    required this.attemptedAt,
  });

  factory ExamAttemptSummary.fromJson(Map<String, dynamic> json) {
    return ExamAttemptSummary(
      attemptId: json['attempt_id'] as int,
      examId: json['exam_id'] as int,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      attemptedAt: DateTime.tryParse(json['attempted_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
