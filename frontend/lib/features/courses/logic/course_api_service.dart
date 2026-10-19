import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../lessons/models/lesson_detail.dart';
import '../models/course.dart';
import '../models/course_detail.dart';
import '../models/exam.dart';
import '../models/user_progress.dart';

/// Service responsible for fetching courses, course details, and lessons from FastAPI
class CourseApiService {
  CourseApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _customBaseUrl = baseUrl;

  final http.Client _client;
  final String? _customBaseUrl;

  String get baseUrl => _customBaseUrl ?? ApiConfig.baseUrl;

  /// Fetches published courses from `GET /courses`
  Future<List<Course>> fetchCourses() async {
    final uri = Uri.parse('$baseUrl/courses');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => Course.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw const FormatException('Unexpected response format: expected a JSON list');
      } else {
        throw HttpException(
          'Backend returned status ${response.statusCode}: ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Unable to reach Kiko backend at $baseUrl. Ensure FastAPI is running on port 8000. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out while fetching courses from $baseUrl.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error connecting to Kiko backend at $baseUrl: ${e.message}',
      );
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load courses: $e');
    }
  }

  /// Fetches detailed course data including lesson syllabus from `GET /courses/{id}`
  Future<CourseDetail> fetchCourseDetail(int courseId) async {
    final uri = Uri.parse('$baseUrl/courses/$courseId');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CourseDetail.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format: expected JSON object');
      } else if (response.statusCode == 404) {
        throw HttpException('Course not found', uri: uri);
      } else {
        throw HttpException(
          'Failed to load course (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Unable to reach Kiko backend at $baseUrl. Ensure FastAPI is running. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out while fetching course details from $baseUrl.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error connecting to Kiko backend at $baseUrl: ${e.message}',
      );
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load course details: $e');
    }
  }

  /// Fetches full lesson content from `GET /lessons/{id}`
  Future<LessonDetail> fetchLessonDetail(int lessonId) async {
    final uri = Uri.parse('$baseUrl/lessons/$lessonId');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return LessonDetail.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format: expected JSON object');
      } else if (response.statusCode == 404) {
        throw HttpException('Lesson not found', uri: uri);
      } else {
        throw HttpException(
          'Failed to load lesson (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Unable to reach Kiko backend at $baseUrl. Ensure FastAPI is running. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out while fetching lesson from $baseUrl.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error connecting to Kiko backend at $baseUrl: ${e.message}',
      );
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load lesson: $e');
    }
  }

  /// Fetches public course assessment from `GET /courses/{course_id}/exam`
  Future<ExamPublic> fetchCourseExam(int courseId) async {
    final uri = Uri.parse('$baseUrl/courses/$courseId/exam');

    try {
      final response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ExamPublic.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format: expected JSON object');
      } else if (response.statusCode == 404) {
        throw HttpException('Course assessment not found or not published', uri: uri);
      } else {
        throw HttpException(
          'Failed to load exam (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception('Unable to reach Kiko backend at $baseUrl. ($e)');
    } on TimeoutException {
      throw Exception('Connection timed out while fetching course test.');
    } on http.ClientException catch (e) {
      throw Exception('Network error connecting to backend: ${e.message}');
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load assessment: $e');
    }
  }

  /// Fetches authenticated user's attempts on this course assessment
  Future<List<ExamAttemptSummary>> fetchCourseExamAttempts(
    int courseId, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/courses/$courseId/attempts');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => ExamAttemptSummary.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        return [];
      } else {
        throw HttpException(
          'Failed to load attempts (status ${response.statusCode})',
          uri: uri,
        );
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      return [];
    }
  }

  /// Submits student answers to `POST /exams/{exam_id}/submit`
  Future<ExamResult> submitExam(
    int examId,
    Map<int, int> answers, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/exams/$examId/submit');

    final payload = {
      'answers': answers.entries
          .map((e) => {
                'question_id': e.key,
                'selected_option_index': e.value,
              })
          .toList(),
    };

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ExamResult.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for assessment results.');
      } else if (response.statusCode == 400) {
        final dynamic decoded = jsonDecode(response.body);
        final detail = decoded is Map ? decoded['detail'] ?? 'Invalid submission' : 'Invalid submission';
        throw HttpException('Submission validation error: $detail', uri: uri);
      } else if (response.statusCode == 401) {
        throw HttpException('Authentication expired. Please sign in to submit.', uri: uri);
      } else {
        throw HttpException(
          'Failed to submit assessment (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error connecting to backend: $e');
    } on TimeoutException {
      throw Exception('Submission timed out. Please check your connection and retry.');
    } on http.ClientException catch (e) {
      throw Exception('Network error during submission: ${e.message}');
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to submit assessment: $e');
    }
  }

  /// Fetches persistent result review for an attempt from `GET /exam-attempts/{attempt_id}/result`
  Future<ExamResult> fetchExamAttemptResult(
    int attemptId, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/exam-attempts/$attemptId/result');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ExamResult.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for exam result.');
      } else if (response.statusCode == 404) {
        throw HttpException('Result not found', uri: uri);
      } else {
        throw HttpException('Failed to load result (status ${response.statusCode})', uri: uri);
      }
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException {
      throw Exception('Request timed out while loading assessment results.');
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load assessment result: $e');
    }
  }

  /// Fetches latest result for an exam from `GET /exams/{exam_id}/latest-result`
  Future<ExamResult?> fetchLatestExamResult(
    int examId, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/exams/$examId/latest-result');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ExamResult.fromJson(decoded);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw HttpException('Failed to load latest result (${response.statusCode})', uri: uri);
      }
    } catch (e) {
      if (e is HttpException && responseStatusCodeIs(e, 404)) return null;
      rethrow;
    }
  }

  /// Fetches authenticated user's overall learning progress from `GET /users/me/progress`
  Future<UserOverallProgress> fetchOverallProgress({String? token}) async {
    final uri = Uri.parse('$baseUrl/users/me/progress');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return UserOverallProgress.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for user progress.');
      } else if (response.statusCode == 401) {
        return UserOverallProgress.empty();
      } else {
        throw HttpException(
          'Failed to load progress (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception('Unable to reach Kiko backend at $baseUrl. ($e)');
    } on TimeoutException {
      throw Exception('Connection timed out while fetching learning progress.');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw Exception('Failed to load progress: $e');
    }
  }

  /// Fetches learning progress for a specific course from `GET /courses/{course_id}/progress`
  Future<CourseProgressDetail> fetchCourseProgress(
    int courseId, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/courses/$courseId/progress');

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CourseProgressDetail.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for course progress.');
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        return CourseProgressDetail.empty(courseId);
      } else {
        throw HttpException(
          'Failed to load course progress (status ${response.statusCode})',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception('Unable to reach Kiko backend at $baseUrl. ($e)');
    } on TimeoutException {
      throw Exception('Connection timed out while fetching course progress.');
    } catch (e) {
      if (e is HttpException) rethrow;
      return CourseProgressDetail.empty(courseId);
    }
  }

  /// Saves lesson completion status to `POST /lessons/{lesson_id}/complete`
  Future<LessonProgressResult> completeLesson(
    int lessonId, {
    String? token,
    bool completed = true,
  }) async {
    final uri = Uri.parse('$baseUrl/lessons/$lessonId/complete');

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final payload = jsonEncode({'completed': completed});

      final response = await _client
          .post(uri, headers: headers, body: payload)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return LessonProgressResult.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for lesson completion.');
      } else if (response.statusCode == 401) {
        throw HttpException(
          'Authentication required to save lesson progress.',
          uri: uri,
        );
      } else if (response.statusCode == 404) {
        throw HttpException('Lesson not found', uri: uri);
      } else {
        throw HttpException(
          'Failed to save lesson progress (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception('Unable to reach Kiko backend at $baseUrl. ($e)');
    } on TimeoutException {
      throw Exception('Connection timed out while saving lesson completion.');
    } catch (e) {
      if (e is HttpException || e is FormatException) rethrow;
      throw Exception('Failed to update lesson completion: $e');
    }
  }

  bool responseStatusCodeIs(HttpException e, int code) => false;
}
