import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/kiko_app_shell.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/courses/presentation/screens/courses_screen.dart';
import 'package:frontend/features/courses/presentation/screens/progress_screen.dart';
import 'package:frontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/profile/logic/profile_api_service.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:frontend/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockUser implements fb.User {
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
  final _controller = StreamController<fb.User?>.broadcast();
  fb.User? _currentUser;
  bool signedOut = false;
  bool shouldFailSignOut = false;

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
    if (shouldFailSignOut) {
      throw Exception('Sign-out failed due to network error');
    }
    signedOut = true;
    emitUser(null);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token';
}

void main() {
  group('Sign-Out & Protected Routes Navigation Tests', () {
    late FakeAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeAuthService();
    });

    testWidgets('Unauthenticated access to protected routes redirects to LoginScreen', (tester) async {
      // Ensure currentUser is null
      fakeAuthService.emitUser(null);

      await tester.pumpWidget(
        KikoApp(authService: fakeAuthService),
      );
      await tester.pumpAndSettle();

      // Root route displays LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      // Attempt to push named protected route /dashboard while logged out
      navigator.pushNamed('/dashboard');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Attempt to push named protected route /profile while logged out
      navigator.pushNamed('/profile');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);

      // Attempt to push named protected route /courses while logged out
      navigator.pushNamed('/courses');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CoursesScreen), findsNothing);

      // Attempt to push named protected route /progress while logged out
      navigator.pushNamed('/progress');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProgressScreen), findsNothing);
    });

    testWidgets('Authenticated user signs out from ProfileScreen: navigates to Login and prevents back navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeAuthService.emitUser(MockUser());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/streak') {
          return http.Response(
            jsonEncode({
              'current_streak': 5,
              'longest_streak': 10,
              'active_today': true,
              'total_active_days': 15,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/users/me/progress') {
          return http.Response(
            jsonEncode({
              'user_id': 101,
              'total_enrolled_courses': 2,
              'completed_lessons_count': 12,
              'passed_exams_count': 2,
              'total_published_lessons': 20,
              'total_published_exams': 2,
              'overall_completion_percentage': 42.0,
              'average_test_score': 85.0,
              'course_progress': [],
              'recent_test_attempts': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'alex@mit.edu',
          'full_name': 'Alex Chen',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final profileService = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (context) => LoginScreen(authService: fakeAuthService),
          },
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: profileService,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.byKey(const Key('profile_sign_out_button'));
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Successfully signed out
      expect(fakeAuthService.signedOut, isTrue);

      // Navigated to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);

      // Verify that the user cannot navigate back to ProfileScreen using back button
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('Authenticated user signs out from DashboardScreen: navigates to Login and prevents back navigation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeAuthService.emitUser(MockUser());

      final mockClient = MockClient((request) async {
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (context) => LoginScreen(authService: fakeAuthService),
          },
          home: DashboardScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);

      final signOutBtn = find.byKey(const Key('dashboard_sign_out_button'));
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthService.signedOut, isTrue);

      // Navigated to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Verify that the user cannot navigate back to DashboardScreen
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('KikoAppShell tab switching redirects to LoginScreen when unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // authService has currentUser == null
      fakeAuthService.emitUser(null);

      await tester.pumpWidget(
        MaterialApp(
          home: KikoAppShell(
            currentTab: KikoTab.home,
            authService: fakeAuthService,
            child: const Text('Shell Child'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Courses tab
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();

      // Redirects to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
