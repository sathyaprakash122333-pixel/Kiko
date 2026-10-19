/// Domain model representing a programming course in Kiko
class Course {
  final int id;
  final String title;
  final String description;
  final String language;
  final int lessonCount;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.lessonCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'General',
      lessonCount: json['lesson_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'lesson_count': lessonCount,
    };
  }
}
