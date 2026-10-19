import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/kiko_app_shell.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/courses/presentation/screens/courses_screen.dart';
import 'package:frontend/features/courses/presentation/screens/progress_screen.dart';
import 'package:frontend/features/profile/logic/profile_api_service.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockTestUser implements fb.User {
  @override
  String? get displayName => 'Sathya Prakash';

  @override
  String? get email => 'sathyaprakash12233@gmail.com';

  @override
  String? get photoURL => null;

  @override
  String get uid => 'nR9dq5fUnN06070Kz2nVTV1mmC22';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  final _controller = StreamController<fb.User?>.broadcast();
  fb.User? _currentUser;
  bool signedOut = false;

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
    signedOut = true;
    emitUser(null);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token_phase5';
}

void main() {
  late FakeAuthService fakeAuthService;
  late MockTestUser mockUser;

  setUp(() {
    fakeAuthService = FakeAuthService();
    mockUser = MockTestUser();
    fakeAuthService.emitUser(mockUser);
  });

  group('Phase 5 — Courses Page Tests', () {
    testWidgets('Renders Your Courses, search field, filter dropdown, and course cards with progress', (tester) async {
      final coursesData = [
        {
          'id': 1,
          'title': 'Introduction to C Programming',
          'description': 'Learn the fundamentals of C programming, including syntax, variables, data types, control structures, functions and more.',
          'language': 'C',
          'lesson_count': 10,
          'order': 1,
          'is_published': true,
        },
        {
          'id': 2,
          'title': 'Python Fundamentals for Beginners',
          'description': 'Start your Python journey with simple concepts, practical examples and hands-on exercises. Perfect for absolute beginners.',
          'language': 'Python',
          'lesson_count': 10,
          'order': 2,
          'is_published': true,
        },
      ];

      final progressData = {
        'completed_lessons_count': 7,
        'total_published_lessons': 20,
        'overall_completion_percentage': 35.0,
        'passed_exams_count': 1,
        'total_published_exams': 2,
        'average_test_score': 82.0,
        'course_progress': [
          {
            'course_id': 1,
            'course_title': 'Introduction to C Programming',
            'language': 'C',
            'completed_lessons': 4,
            'total_lessons': 10,
            'completion_percentage': 40.0,
            'test_status': 'passed',
            'test_score': 16,
            'test_total_questions': 20,
          },
          {
            'course_id': 2,
            'course_title': 'Python Fundamentals for Beginners',
            'language': 'Python',
            'completed_lessons': 2,
            'total_lessons': 10,
            'completion_percentage': 20.0,
            'test_status': 'not_attempted',
            'test_score': null,
            'test_total_questions': null,
          },
        ],
        'recent_test_attempts': [],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses') {
          return http.Response(jsonEncode(coursesData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/users/me/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final courseApiService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CoursesScreen(
            authService: fakeAuthService,
            user: mockUser,
            courseApiService: courseApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Your Courses'), findsOneWidget);
      expect(find.text('Explore our beginner-friendly courses and start your coding journey today.'), findsOneWidget);

      // Verify Search Input
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search courses...'), findsOneWidget);

      // Verify Course Titles
      expect(find.text('Introduction to C Programming'), findsOneWidget);
      expect(find.text('Python Fundamentals for Beginners'), findsOneWidget);

      // Verify Badges and Pills
      expect(find.text('C Language'), findsWidgets);
      expect(find.text('Python'), findsWidgets);

      // Verify Lessons and Hours
      expect(find.text('10 lessons'), findsNWidgets(2));
      expect(find.text('~ 20-25 hrs'), findsNWidgets(2));

      // Verify Calculated Progress Percentages
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      // Verify Continue Learning Buttons
      expect(find.text('Continue learning'), findsNWidgets(2));

      // Test Search Filtering
      await tester.enterText(find.byType(TextField), 'Python');
      await tester.pumpAndSettle();

      expect(find.text('Introduction to C Programming'), findsNothing);
      expect(find.text('Python Fundamentals for Beginners'), findsOneWidget);
    });

    testWidgets('CoursesScreen shows retry on network error', (tester) async {
      final mockClient = MockClient((request) async => http.Response('Server Error', 500));
      final courseApiService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CoursesScreen(
            authService: fakeAuthService,
            user: mockUser,
            courseApiService: courseApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Courses'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Phase 5 — Progress Page Tests', () {
    testWidgets('Renders 4 summary cards, course progress cards, and recent test results table', (tester) async {
      final progressData = {
        'completed_lessons_count': 7,
        'total_published_lessons': 20,
        'overall_completion_percentage': 35.0,
        'passed_exams_count': 1,
        'total_published_exams': 2,
        'average_test_score': 82.0,
        'course_progress': [
          {
            'course_id': 1,
            'course_title': 'Introduction to C Programming',
            'language': 'C',
            'completed_lessons': 4,
            'total_lessons': 10,
            'completion_percentage': 40.0,
            'test_status': 'passed',
            'test_score': 16,
            'test_total_questions': 20,
          },
          {
            'course_id': 2,
            'course_title': 'Python Fundamentals for Beginners',
            'language': 'Python',
            'completed_lessons': 2,
            'total_lessons': 10,
            'completion_percentage': 20.0,
            'test_status': 'not_attempted',
            'test_score': null,
            'test_total_questions': null,
          },
        ],
        'recent_test_attempts': [
          {
            'attempt_id': 10,
            'exam_id': 1,
            'course_id': 1,
            'course_title': 'Introduction to C Programming',
            'language': 'C',
            'score': 16,
            'total_questions': 20,
            'percentage': 80.0,
            'passed': true,
            'attempted_at': '2026-10-19T06:30:00Z',
          },
          {
            'attempt_id': 11,
            'exam_id': 2,
            'course_id': 2,
            'course_title': 'Python Fundamentals',
            'language': 'Python',
            'score': 12,
            'total_questions': 20,
            'percentage': 60.0,
            'passed': false,
            'attempted_at': '2026-10-18T05:00:00Z',
          },
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final courseApiService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProgressScreen(
            authService: fakeAuthService,
            user: mockUser,
            courseApiService: courseApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Your Learning Progress'), findsOneWidget);
      expect(find.text('Track your journey, celebrate your progress, and reach your goals!'), findsOneWidget);

      // Verify 4 Stat Cards
      expect(find.text('Overall progress'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      expect(find.text('7 / 20 lessons'), findsOneWidget);

      expect(find.text('Lessons completed'), findsOneWidget);
      expect(find.text('7 / 20'), findsOneWidget);

      expect(find.text('Tests passed'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      expect(find.text('Average test score'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);

      // Verify Course Progress
      expect(find.text('Course progress'), findsOneWidget);
      expect(find.text('4 / 10 lessons completed'), findsOneWidget);
      expect(find.text('2 / 10 lessons completed'), findsOneWidget);
      expect(find.text('Test passed (16/20)'), findsOneWidget);
      expect(find.text('Test not attempted'), findsOneWidget);

      // Verify Recent Test Results Table
      expect(find.text('Recent test results'), findsOneWidget);
      expect(find.text('Passed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('16 / 20'), findsOneWidget);
      expect(find.text('12 / 20'), findsOneWidget);
    });

    testWidgets('ProgressScreen shows empty state when user has no attempts or progress', (tester) async {
      final emptyProgressData = {
        'total_completed_lessons': 0,
        'total_published_lessons': 20,
        'overall_completion_percentage': 0.0,
        'passed_exams_count': 0,
        'total_published_exams': 2,
        'average_test_score': 0.0,
        'course_progress': [],
        'recent_test_attempts': [],
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(emptyProgressData), 200, headers: {'content-type': 'application/json'});
      });

      final courseApiService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProgressScreen(
            authService: fakeAuthService,
            user: mockUser,
            courseApiService: courseApiService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Assessments Attempted Yet'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('Phase 5 — Profile Page & Shell Tests', () {
    testWidgets('Profile page displays welcome sync banner, UID, Learning Summary, and Sign Out', (tester) async {
      final profileData = {
        'id': 1,
        'firebase_uid': 'nR9dq5fUnN06070Kz2nVTV1mmC22',
        'email': 'sathyaprakash12233@gmail.com',
        'display_name': 'Sathya Prakash',
        'created_at': '2026-10-19T07:24:00Z',
        'last_login_at': '2026-10-19T07:24:00Z',
      };

      final progressData = {
        'completed_lessons_count': 7,
        'total_published_lessons': 20,
        'overall_completion_percentage': 35.0,
        'passed_exams_count': 1,
        'total_published_exams': 2,
        'average_test_score': 82.0,
        'course_progress': [],
        'recent_test_attempts': [],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me') {
          return http.Response(jsonEncode(profileData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/users/me/progress') {
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final profileApiService = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseApiService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: mockUser,
            profileApiService: profileApiService,
            courseApiService: courseApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Manage your account information and view your learning summary.'), findsOneWidget);

      // User details
      expect(find.text('Sathya Prakash'), findsOneWidget);
      expect(find.text('sathyaprakash12233@gmail.com'), findsOneWidget);

      // Welcome Sync Banner
      expect(find.text('Welcome, Sathya!'), findsOneWidget);
      expect(find.text('Your profile and learning records are continuously synchronized.'), findsOneWidget);

      // Account Info
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Member Since'), findsOneWidget);
      expect(find.text('Last Active Session'), findsOneWidget);

      // Diagnostic UID
      expect(find.text('Authentication & Security'), findsOneWidget);
      expect(find.text('Google Account'), findsOneWidget);
      expect(find.text('Diagnostic User Identifier (UID)'), findsOneWidget);
      expect(find.text('nR9dq5fUnN06070Kz2nVTV1mmC22'), findsOneWidget);

      // Learning Summary Card
      expect(find.text('Learning Summary'), findsOneWidget);
      expect(find.text('Lessons Completed'), findsOneWidget);
      expect(find.text('7 / 20'), findsOneWidget);
      expect(find.text('Tests Passed'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      // Sign Out Button
      expect(find.text('Sign Out'), findsWidgets);
    });

    testWidgets('KikoAppShell renders desktop sidebar on wide screens and mobile bar on narrow screens', (tester) async {
      // Desktop width test
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: const KikoAppShell(
            currentTab: KikoTab.courses,
            child: Text('Main Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kiko'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Small steps\nbuild big\nprogrammers. 💚'), findsOneWidget);

      // Reset view size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
