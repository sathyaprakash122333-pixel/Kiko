import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/courses/models/course.dart';
import 'package:frontend/features/courses/models/course_detail.dart';
import 'package:frontend/features/courses/presentation/screens/course_detail_screen.dart';
import 'package:frontend/features/dashboard/presentation/widgets/course_card.dart';
import 'package:frontend/features/lessons/models/lesson_detail.dart';
import 'package:frontend/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockTestUser implements fb.User {
  @override
  String? get displayName => 'Alex Chen';
  @override
  String? get email => 'alex.chen@campus.mit.edu';
  @override
  String? get photoURL => null;
  @override
  String get uid => 'user_test_uid_12345678';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTestAuthService implements AuthService {
  final _controller = StreamController<fb.User?>.broadcast();
  fb.User? _currentUser;

  void emitUser(fb.User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<fb.User?> get authStateChanges => _controller.stream;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  Future<void> syncUserToFirestore(fb.User user) async {}

  @override
  Future<fb.UserCredential?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {
    emitUser(null);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_id_token';
}

void main() {
  group('Course & Lesson Models Tests', () {
    test('LessonSummary fromJson and toJson roundtrip', () {
      final json = {
        'id': 10,
        'course_id': 1,
        'title': 'Variables in C',
        'order_number': 2,
        'has_exam': true,
      };

      final lesson = LessonSummary.fromJson(json);
      expect(lesson.id, 10);
      expect(lesson.courseId, 1);
      expect(lesson.title, 'Variables in C');
      expect(lesson.orderNumber, 2);
      expect(lesson.hasExam, isTrue);

      final out = lesson.toJson();
      expect(out['id'], 10);
      expect(out['has_exam'], isTrue);
    });

    test('CourseDetail fromJson and toJson roundtrip', () {
      final json = {
        'id': 1,
        'title': 'C Programming',
        'description': 'Master C',
        'language': 'C',
        'lessons': [
          {
            'id': 1,
            'course_id': 1,
            'title': 'Hello World',
            'order_number': 1,
            'has_exam': false,
          },
        ],
      };

      final detail = CourseDetail.fromJson(json);
      expect(detail.id, 1);
      expect(detail.title, 'C Programming');
      expect(detail.lessons.length, 1);
      expect(detail.lessons.first.title, 'Hello World');

      final out = detail.toJson();
      expect(out['id'], 1);
      expect((out['lessons'] as List).length, 1);
    });

    test('LessonDetail fromJson and toJson roundtrip', () {
      final json = {
        'id': 5,
        'course_id': 1,
        'title': 'Loops in C',
        'content': '# Loops\n\n```c\nfor(;;){}\n```',
        'order_number': 3,
        'has_exam': true,
        'exam_id': 42,
      };

      final lesson = LessonDetail.fromJson(json);
      expect(lesson.id, 5);
      expect(lesson.courseId, 1);
      expect(lesson.title, 'Loops in C');
      expect(lesson.content, contains('# Loops'));
      expect(lesson.orderNumber, 3);
      expect(lesson.hasExam, isTrue);
      expect(lesson.examId, 42);

      final out = lesson.toJson();
      expect(out['id'], 5);
      expect(out['exam_id'], 42);
    });
  });

  group('CourseApiService Course and Lesson Detail Tests', () {
    test('fetchCourseDetail returns course detail on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/courses/1');
        final data = {
          'id': 1,
          'title': 'Introduction to C Programming',
          'description': 'Fundamentals of C',
          'language': 'C',
          'lessons': [
            {
              'id': 101,
              'course_id': 1,
              'title': 'Hello World',
              'order_number': 1,
              'has_exam': false,
            },
            {
              'id': 102,
              'course_id': 1,
              'title': 'Variables',
              'order_number': 2,
              'has_exam': true,
            },
          ],
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final detail = await service.fetchCourseDetail(1);

      expect(detail.id, 1);
      expect(detail.title, 'Introduction to C Programming');
      expect(detail.lessons.length, 2);
      expect(detail.lessons[0].title, 'Hello World');
      expect(detail.lessons[1].hasExam, isTrue);
    });

    test('fetchCourseDetail throws on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Course not found"}', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      expect(() => service.fetchCourseDetail(99999), throwsException);
    });

    test('fetchLessonDetail returns lesson detail on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/lessons/101');
        final data = {
          'id': 101,
          'course_id': 1,
          'title': 'Hello World',
          'content': '# Hello World\n\n- Point 1\n- Point 2\n\n```c\nprintf("Hello");\n```',
          'order_number': 1,
          'has_exam': false,
          'exam_id': null,
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final lesson = await service.fetchLessonDetail(101);

      expect(lesson.id, 101);
      expect(lesson.title, 'Hello World');
      expect(lesson.content, contains('# Hello World'));
      expect(lesson.hasExam, isFalse);
    });

    test('fetchLessonDetail throws on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Lesson not found"}', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      expect(() => service.fetchLessonDetail(99999), throwsException);
    });

    test('fetchCourseProgress returns CourseProgressDetail on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/courses/1/progress');
        final data = {
          'course_id': 1,
          'course_title': 'Introduction to C Programming',
          'total_lessons': 10,
          'completed_lessons': 4,
          'completion_percentage': 40.0,
          'is_completed': false,
          'completed_lesson_ids': [101, 102, 103, 104],
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final prog = await service.fetchCourseProgress(1, token: 'mock_token');

      expect(prog.courseId, 1);
      expect(prog.completedLessons, 4);
      expect(prog.totalLessons, 10);
      expect(prog.completionPercentage, 40.0);
      expect(prog.completedLessonIds, [101, 102, 103, 104]);
    });

    test('completeLesson posts completion and returns LessonProgressResult', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/lessons/101/complete');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['completed'], isTrue);
        final data = {
          'lesson_id': 101,
          'is_completed': true,
          'completed_at': '2026-10-19T14:00:00Z',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final res = await service.completeLesson(101, token: 'mock_token', completed: true);

      expect(res.lessonId, 101);
      expect(res.isCompleted, isTrue);
      expect(res.completedAt, isNotNull);
    });
  });

  group('CourseCard Widget Tests', () {
    testWidgets('Tapping anywhere on CourseCard triggers onTap', (tester) async {
      var tapped = false;
      const course = Course(
        id: 1,
        title: 'Introduction to C Programming',
        description: 'Learn C from scratch.',
        language: 'C',
        lessonCount: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: Scaffold(
            body: CourseCard(
              course: course,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Introduction to C Programming'), findsOneWidget);
      expect(find.text('4 lessons'), findsOneWidget);
      expect(find.text('View Course'), findsOneWidget);

      await tester.tap(find.text('Introduction to C Programming'));
      expect(tapped, isTrue);
    });
  });

  group('CourseDetailScreen Widget Tests', () {
    testWidgets('Renders course details and syllabus lessons', (tester) async {
      final mockClient = MockClient((request) async {
        final data = {
          'id': 1,
          'title': 'Introduction to C Programming',
          'description': 'A foundational course covering C.',
          'language': 'C',
          'lessons': [
            {
              'id': 101,
              'course_id': 1,
              'title': 'Structure of a C Program',
              'order_number': 1,
              'has_exam': false,
            },
            {
              'id': 102,
              'course_id': 1,
              'title': 'Variables & Data Types',
              'order_number': 2,
              'has_exam': true,
            },
          ],
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
          ),
        ),
      );

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify header details
      expect(find.text('Introduction to C Programming'), findsWidgets);
      expect(find.text('A foundational course covering C.'), findsOneWidget);
      expect(find.text('Course Syllabus'), findsOneWidget);
      expect(find.text('2 Modules'), findsOneWidget);

      // Verify lessons list
      expect(find.text('Structure of a C Program'), findsOneWidget);
      expect(find.text('Variables & Data Types'), findsOneWidget);
      expect(find.text('Assessment Included'), findsOneWidget);
    });

    testWidgets('Shows error view and allows Retry on API failure', (tester) async {
      var attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('Internal Server Error', 500);
        }
        final data = {
          'id': 1,
          'title': 'Introduction to C Programming',
          'description': 'Success after retry',
          'language': 'C',
          'lessons': [],
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Course'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Success after retry'), findsOneWidget);
      expect(find.text('No Lessons Available'), findsOneWidget);
    });

    testWidgets('CourseDetailScreen loads and displays live backend progress and completion checkmarks', (tester) async {
      final mockAuth = FakeTestAuthService();
      mockAuth.emitUser(MockTestUser());

      final courseData = {
        'id': 1,
        'title': 'Introduction to C Programming',
        'description': 'A foundational course covering C.',
        'language': 'C',
        'lessons': [
          {'id': 101, 'course_id': 1, 'title': 'Structure of a C Program', 'order_number': 1, 'has_exam': false},
          {'id': 102, 'course_id': 1, 'title': 'Variables & Data Types', 'order_number': 2, 'has_exam': false},
        ],
      };

      final progressData = {
        'course_id': 1,
        'course_title': 'Introduction to C Programming',
        'total_lessons': 2,
        'completed_lessons': 1,
        'completion_percentage': 50.0,
        'is_completed': false,
        'completed_lesson_ids': [101],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1') {
          return http.Response(jsonEncode(courseData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/attempts') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
            authService: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify completion count and percentage
      expect(find.text('1 / 2 lessons completed'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // Verify checkmark for 101 and radio button for 102
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('CourseDetailScreen toggling lesson completion calls POST /lessons/{id}/complete and updates state', (tester) async {
      final mockAuth = FakeTestAuthService();
      mockAuth.emitUser(MockTestUser());

      final courseData = {
        'id': 1,
        'title': 'Introduction to C Programming',
        'description': 'A foundational course covering C.',
        'language': 'C',
        'lessons': [
          {'id': 101, 'course_id': 1, 'title': 'Structure of a C Program', 'order_number': 1, 'has_exam': false},
          {'id': 102, 'course_id': 1, 'title': 'Variables & Data Types', 'order_number': 2, 'has_exam': false},
        ],
      };

      final progressData = {
        'course_id': 1,
        'course_title': 'Introduction to C Programming',
        'total_lessons': 2,
        'completed_lessons': 1,
        'completion_percentage': 50.0,
        'is_completed': false,
        'completed_lesson_ids': [101],
      };

      var completePostCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1') {
          return http.Response(jsonEncode(courseData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/attempts') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/lessons/102/complete' && request.method == 'POST') {
          completePostCalled = true;
          return http.Response(jsonEncode({'lesson_id': 102, 'is_completed': true}), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
            authService: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('1 / 2 lessons completed'), findsOneWidget);

      // Tap on radio button for lesson 102
      final radioFinder = find.byIcon(Icons.radio_button_unchecked);
      await tester.ensureVisible(radioFinder);
      await tester.pumpAndSettle();
      await tester.tap(radioFinder);
      await tester.pumpAndSettle();

      expect(completePostCalled, isTrue);
      expect(find.text('2 / 2 lessons completed'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    });

    testWidgets('CourseDetailScreen failed completion shows error SnackBar and does not falsely mark completed', (tester) async {
      final mockAuth = FakeTestAuthService();
      mockAuth.emitUser(MockTestUser());

      final courseData = {
        'id': 1,
        'title': 'Introduction to C Programming',
        'description': 'A foundational course covering C.',
        'language': 'C',
        'lessons': [
          {'id': 101, 'course_id': 1, 'title': 'Structure of a C Program', 'order_number': 1, 'has_exam': false},
          {'id': 102, 'course_id': 1, 'title': 'Variables & Data Types', 'order_number': 2, 'has_exam': false},
        ],
      };

      final progressData = {
        'course_id': 1,
        'course_title': 'Introduction to C Programming',
        'total_lessons': 2,
        'completed_lessons': 0,
        'completion_percentage': 0.0,
        'is_completed': false,
        'completed_lesson_ids': [],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1') {
          return http.Response(jsonEncode(courseData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/attempts') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/lessons/101/complete') {
          return http.Response('Server Error', 500);
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
            authService: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('0 / 2 lessons completed'), findsOneWidget);

      // Tap on radio button for lesson 101
      final radioFinder = find.byIcon(Icons.radio_button_unchecked).first;
      await tester.ensureVisible(radioFinder);
      await tester.pumpAndSettle();
      await tester.tap(radioFinder);
      await tester.pumpAndSettle();

      // Error message shown and progress NOT falsely incremented
      expect(find.textContaining('Failed to update lesson completion'), findsOneWidget);
      expect(find.text('0 / 2 lessons completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });

  group('LessonScreen Widget Tests', () {
    testWidgets('Renders structured lesson markdown and code blocks', (tester) async {
      final mockClient = MockClient((request) async {
        final data = {
          'id': 101,
          'course_id': 1,
          'title': 'Structure of a C Program',
          'content': '# Introduction to C\n\nC is a compiled language.\n\n## Code Example\n\n```c\nprintf("Hello, World!");\n```\n\n- Preprocessor directive\n- Entry point function',
          'order_number': 1,
          'has_exam': false,
          'exam_id': null,
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LessonScreen(
            lessonId: 101,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & headings
      expect(find.text('Structure of a C Program'), findsOneWidget);
      expect(find.text('Introduction to C'), findsOneWidget);
      expect(find.text('Code Example'), findsOneWidget);

      // Verify code block rendered
      expect(find.text('C'), findsWidgets);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('printf("Hello, World!");'), findsOneWidget);

      // Verify bullet items
      expect(find.text('Preprocessor directive'), findsOneWidget);
      expect(find.text('Entry point function'), findsOneWidget);
    });

    testWidgets('Clearly reports missing lesson content from database', (tester) async {
      final mockClient = MockClient((request) async {
        final data = {
          'id': 102,
          'course_id': 1,
          'title': 'Empty Lesson',
          'content': '',
          'order_number': 2,
          'has_exam': false,
          'exam_id': null,
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LessonScreen(
            lessonId: 102,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify clear missing content notice
      expect(find.text('No Learning Content Available'), findsOneWidget);
      expect(find.textContaining('has not been added to the database yet'), findsOneWidget);
    });

    testWidgets('Shows error view and allows Retry on failure', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Not Found', 404);
        }
        final data = {
          'id': 101,
          'course_id': 1,
          'title': 'Retried Lesson',
          'content': 'Success after error',
          'order_number': 1,
          'has_exam': false,
          'exam_id': null,
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LessonScreen(
            lessonId: 101,
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Lesson'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retried Lesson'), findsOneWidget);
      expect(find.text('Success after error'), findsOneWidget);
    });

    testWidgets('Next lesson navigation switches to next lesson', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/lessons/101') {
          final data = {
            'id': 101,
            'course_id': 1,
            'title': 'Lesson 1',
            'content': 'Content of Lesson 1',
            'order_number': 1,
            'has_exam': false,
            'exam_id': null,
          };
          return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
        } else {
          final data = {
            'id': 102,
            'course_id': 1,
            'title': 'Lesson 2',
            'content': 'Content of Lesson 2',
            'order_number': 2,
            'has_exam': false,
            'exam_id': null,
          };
          return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
        }
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      const allLessons = [
        LessonSummary(id: 101, courseId: 1, title: 'Lesson 1', orderNumber: 1, hasExam: false),
        LessonSummary(id: 102, courseId: 1, title: 'Lesson 2', orderNumber: 2, hasExam: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LessonScreen(
            lessonId: 101,
            courseTitle: 'Introduction to C',
            allLessons: allLessons,
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Content of Lesson 1'), findsOneWidget);
      expect(find.text('Next: Lesson 2'), findsOneWidget);

      await tester.tap(find.text('Next: Lesson 2'));
      await tester.pumpAndSettle();

      expect(find.text('Content of Lesson 2'), findsOneWidget);
    });

    testWidgets('LessonScreen displays Mark Complete button and updates on click', (tester) async {
      final mockAuth = FakeTestAuthService();
      mockAuth.emitUser(MockTestUser());

      var completeCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/lessons/101') {
          final data = {
            'id': 101,
            'course_id': 1,
            'title': 'Structure of a C Program',
            'content': '# Lesson 1 Content',
            'order_number': 1,
            'has_exam': false,
            'exam_id': null,
          };
          return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/progress') {
          final prog = {
            'course_id': 1,
            'course_title': 'Introduction to C',
            'total_lessons': 2,
            'completed_lessons': 0,
            'completion_percentage': 0.0,
            'is_completed': false,
            'completed_lesson_ids': [],
          };
          return http.Response(jsonEncode(prog), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/lessons/101/complete' && request.method == 'POST') {
          completeCalled = true;
          return http.Response(jsonEncode({'lesson_id': 101, 'is_completed': true}), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LessonScreen(
            lessonId: 101,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
            authService: mockAuth,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mark Complete'), findsOneWidget);

      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
      expect(find.text('Completed'), findsOneWidget);
    });
  });
}
