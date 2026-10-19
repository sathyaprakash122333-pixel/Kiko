/// Domain model representing detailed lesson content and metadata
class LessonDetail {
  final int id;
  final int courseId;
  final String title;
  final String content;
  final int orderNumber;
  final bool hasExam;
  final int? examId;

  const LessonDetail({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.orderNumber,
    required this.hasExam,
    this.examId,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
      id: json['id'] as int,
      courseId: json['course_id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      orderNumber: json['order_number'] as int? ?? 1,
      hasExam: json['has_exam'] as bool? ?? false,
      examId: json['exam_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'content': content,
      'order_number': orderNumber,
      'has_exam': hasExam,
      'exam_id': examId,
    };
  }
}
