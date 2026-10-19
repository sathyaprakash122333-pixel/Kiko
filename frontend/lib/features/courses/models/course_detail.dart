/// Domain model representing a lesson summary item inside a course syllabus
class LessonSummary {
  final int id;
  final int courseId;
  final String title;
  final int orderNumber;
  final bool hasExam;

  const LessonSummary({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderNumber,
    required this.hasExam,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    return LessonSummary(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String? ?? '',
      orderNumber: json['order_number'] as int? ?? 1,
      hasExam: json['has_exam'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'order_number': orderNumber,
      'has_exam': hasExam,
    };
  }
}

/// Domain model representing detailed course data with full lesson syllabus
class CourseDetail {
  final int id;
  final String title;
  final String description;
  final String language;
  final int? examId;
  final String? examTitle;
  final List<LessonSummary> lessons;

  const CourseDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    this.examId,
    this.examTitle,
    required this.lessons,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];
    return CourseDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'General',
      examId: json['exam_id'] as int?,
      examTitle: json['exam_title'] as String?,
      lessons: lessonsJson
          .map((item) => LessonSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'exam_id': examId,
      'exam_title': examTitle,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}
