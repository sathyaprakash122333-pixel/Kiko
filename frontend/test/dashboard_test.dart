import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/courses/models/course.dart';
import 'package:frontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/dashboard/presentation/widgets/course_card.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockUser implements User {
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

class FakeAuthService implements AuthService {
  final _controller = StreamController<User?>.broadcast();
  User? _currentUser;
  bool signedOut = false;
  bool shouldFailSignOut = false;
  Completer<void>? signOutCompleter;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<void> syncUserToFirestore(User user) async {}

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {
    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }
    if (shouldFailSignOut) {
      throw Exception('Network disconnected during sign out');
    }
    signedOut = true;
    emitUser(null);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_id_token';
}

void main() {
  group('Course Model & CourseApiService Tests', () {
    test('Course.fromJson correctly parses API JSON payload', () {
      final json = {
        'id': 1,
        'title': 'Introduction to C Programming',
        'description': 'A foundational course covering C.',
        'language': 'C',
        'lesson_count': 4,
      };

      final course = Course.fromJson(json);

      expect(course.id, 1);
      expect(course.title, 'Introduction to C Programming');
      expect(course.description, 'A foundational course covering C.');
      expect(course.language, 'C');
      expect(course.lessonCount, 4);
    });

    test('CourseApiService.fetchCourses succeeds with 200 and parses courses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/courses');
        final responseData = [
          {
            'id': 1,
            'title': 'Introduction to C Programming',
            'description': 'Learn C',
            'language': 'C',
            'lesson_count': 4,
          },
          {
            'id': 2,
            'title': 'Python Fundamentals',
            'description': 'Learn Python',
            'language': 'Python',
            'lesson_count': 2,
          },
        ];
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courses = await service.fetchCourses();

      expect(courses.length, 2);
      expect(courses[0].title, 'Introduction to C Programming');
      expect(courses[1].title, 'Python Fundamentals');
    });

    test('CourseApiService.fetchCourses throws on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      expect(() => service.fetchCourses(), throwsException);
    });
  });

  group('DashboardScreen Widget Tests', () {
    late FakeAuthService fakeAuthService;
    final sampleCourses = [
      const Course(
        id: 1,
        title: 'Introduction to C Programming',
        description: 'A foundational course covering memory and pointers.',
        language: 'C',
        lessonCount: 4,
      ),
      const Course(
        id: 2,
        title: 'Python Fundamentals for Beginners',
        description: 'Learn clean, readable programming concepts with Python.',
        language: 'Python',
        lessonCount: 2,
      ),
    ];

    setUp(() {
      fakeAuthService = FakeAuthService();
      fakeAuthService.emitUser(MockUser());
    });

    testWidgets('Renders courses, badges, lessons count, and welcome banner', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleCourses.map((c) => c.toJson()).toList()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );

      // Settle loading and async futures
      await tester.pumpAndSettle();

      // Banner & Headings
      expect(find.text('Welcome to Kiko'), findsOneWidget);
      expect(find.text('Your Courses'), findsOneWidget);
      expect(find.text('Hello, Alex Chen!'), findsOneWidget);

      // Course Cards rendered
      expect(find.byType(CourseCard), findsNWidgets(2));
      expect(find.text('Introduction to C Programming'), findsOneWidget);
      expect(find.text('Python Fundamentals for Beginners'), findsOneWidget);
      expect(find.text('4 lessons'), findsOneWidget);
      expect(find.text('2 lessons'), findsOneWidget);
      expect(find.text('C Language'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
    });

    testWidgets('Search query filters displayed courses', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode(sampleCourses.map((c) => c.toJson()).toList()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CourseCard), findsNWidgets(2));

      // Type "Python" in search field
      await tester.enterText(find.byType(TextField), 'Python');
      await tester.pumpAndSettle();

      // Only Python course card should now be visible
      expect(find.text('Python Fundamentals for Beginners'), findsOneWidget);
      expect(find.text('Introduction to C Programming'), findsNothing);
    });

    testWidgets('Displays error state and allows Retry when API fails', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Server Unavailable', 503);
        }
        return http.Response(
          jsonEncode(sampleCourses.map((c) => c.toJson()).toList()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error state displayed
      expect(find.text('Unable to Load Courses'), findsOneWidget);
      final retryFinder = find.text('Retry Connection');
      expect(retryFinder, findsOneWidget);

      // Scroll to button and tap Retry Connection
      await tester.ensureVisible(retryFinder);
      await tester.tap(retryFinder);
      await tester.pumpAndSettle();

      // Now courses are loaded successfully
      expect(find.byType(CourseCard), findsNWidgets(2));
      expect(find.text('Introduction to C Programming'), findsOneWidget);
    });

    testWidgets('Tapping Sign Out on Dashboard calls authService.signOut(), navigates to LoginScreen, and prevents back navigation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': 'Introduction to C Programming',
              'description': 'A foundational course covering C.',
              'language': 'C',
              'lesson_count': 4,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('dashboard_sign_out_button'));
      expect(signOutBtn, findsOneWidget);

      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Sign out was called
      expect(fakeAuthService.signedOut, isTrue);

      // Navigated to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Back navigation is prevented (stack cleared)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('Failed Sign Out on Dashboard displays error SnackBar and does not falsely navigate', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeAuthService.shouldFailSignOut = true;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('dashboard_sign_out_button'));
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Sign out failed
      expect(fakeAuthService.signedOut, isFalse);

      // Error SnackBar shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Network disconnected during sign out'), findsOneWidget);

      // User remains on DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Dashboard Sign Out button disables during logout to prevent duplicate requests', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<void>();
      fakeAuthService.signOutCompleter = completer;

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
      });
      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('dashboard_sign_out_button'));
      await tester.tap(signOutBtn);
      await tester.pump(); // Start async sign out

      // While in progress, button shows 'Signing out...' and is disabled
      expect(find.text('Signing out...'), findsOneWidget);
      final buttonWidget = tester.widget<OutlinedButton>(signOutBtn);
      expect(buttonWidget.onPressed, isNull);

      // Complete sign-out
      completer.complete();
      await tester.pumpAndSettle();

      expect(fakeAuthService.signedOut, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
