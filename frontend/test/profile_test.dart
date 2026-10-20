import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/profile/logic/profile_api_service.dart';
import 'package:frontend/features/profile/models/user_profile.dart';
import 'package:frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockFbUser implements fb.User {
  @override
  String? get displayName => 'Sathya Prakash';

  @override
  String? get email => 'sathyaprakash122333@gmail.com';

  @override
  String? get photoURL => null;

  @override
  String get uid => 'user_test_uid_12345678';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfileAuthService implements AuthService {
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
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_test_token';
}

void main() {
  group('UserProfile Model & ProfileApiService Tests', () {
    test('UserProfile.fromJson and toJson correctly roundtrip all fields', () {
      final json = {
        'id': 1,
        'firebase_uid': 'firebase_uid_abc',
        'email': 'sathya@example.com',
        'full_name': 'Sathya Prakash',
        'display_name': 'Sathya Prakash',
        'date_of_birth': 'Nov 15, 2004',
        'gender': 'Male',
        'city': 'Chennai',
        'institution': 'Sri Sairam Engineering College',
        'degree': 'B.E. (Information Technology)',
        'department': 'Information Technology',
        'academic_year': '3rd Year',
        'semester': '5th Semester',
        'created_at': '2026-10-19T08:00:00Z',
        'last_login_at': '2026-10-19T10:30:00Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.firebaseUid, 'firebase_uid_abc');
      expect(profile.email, 'sathya@example.com');
      expect(profile.fullName, 'Sathya Prakash');
      expect(profile.effectiveName, 'Sathya Prakash');
      expect(profile.institution, 'Sri Sairam Engineering College');
      expect(profile.city, 'Chennai');
      expect(profile.degree, 'B.E. (Information Technology)');
      expect(profile.academicYear, '3rd Year');
      expect(profile.semester, '5th Semester');

      final out = profile.toJson();
      expect(out['id'], 1);
      expect(out['institution'], 'Sri Sairam Engineering College');
    });

    test('UserStreak.fromJson parses streak information', () {
      final json = {
        'current_streak': 5,
        'longest_streak': 12,
        'last_activity_date': '2026-10-20',
        'active_today': true,
        'total_active_days': 15,
        'recent_active_dates': ['2026-10-19', '2026-10-20'],
      };

      final streak = UserStreak.fromJson(json);
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 12);
      expect(streak.activeToday, true);
      expect(streak.totalActiveDays, 15);
    });

    test('ProfileApiService.fetchProfile passes Bearer token and parses profile', () async {
      final fakeAuth = FakeProfileAuthService();
      fakeAuth.emitUser(MockFbUser());

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/me');
        expect(request.headers['Authorization'], 'Bearer mock_test_token');
        final responseData = {
          'id': 42,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'full_name': 'Sathya Prakash',
          'display_name': 'Sathya Prakash',
          'institution': 'Sri Sairam Engineering College',
        };
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final profile = await service.fetchProfile();

      expect(profile.id, 42);
      expect(profile.fullName, 'Sathya Prakash');
      expect(profile.institution, 'Sri Sairam Engineering College');
    });

    test('ProfileApiService.updateDisplayName sends PATCH with updated name', () async {
      final fakeAuth = FakeProfileAuthService();
      fakeAuth.emitUser(MockFbUser());

      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/users/me');
        expect(request.headers['Authorization'], 'Bearer mock_test_token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['display_name'], 'Alexander Chen');

        final responseData = {
          'id': 42,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'display_name': 'Alexander Chen',
          'full_name': 'Alexander Chen',
        };
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final updated = await service.updateDisplayName('Alexander Chen');

      expect(updated.effectiveName, 'Alexander Chen');
    });

    test('ProfileApiService.updateProfile sends PUT with full payload', () async {
      final fakeAuth = FakeProfileAuthService();
      fakeAuth.emitUser(MockFbUser());

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/users/me');
        expect(request.headers['Authorization'], 'Bearer mock_test_token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['city'], 'Chennai');
        expect(body['institution'], 'Sri Sairam Engineering College');

        final responseData = {
          'id': 42,
          'firebase_uid': 'user_test_uid_12345678',
          'full_name': 'Sathya Prakash',
          'city': 'Chennai',
          'institution': 'Sri Sairam Engineering College',
        };
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final updated = await service.updateProfile({
        'full_name': 'Sathya Prakash',
        'city': 'Chennai',
        'institution': 'Sri Sairam Engineering College',
      });

      expect(updated.city, 'Chennai');
      expect(updated.institution, 'Sri Sairam Engineering College');
    });

    test('ProfileApiService throws when session expired (401)', () async {
      final fakeAuth = FakeProfileAuthService();
      fakeAuth.emitUser(MockFbUser());

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      expect(() => service.fetchProfile(), throwsException);
    });
  });

  group('ProfileScreen Widget Tests', () {
    late FakeProfileAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeProfileAuthService();
      fakeAuthService.emitUser(MockFbUser());
    });

    testWidgets('Renders student profile with personal, academic, streak, and security info', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/streak') {

          final streakData = {
            'current_streak': 5,
            'longest_streak': 10,
            'active_today': true,
            'total_active_days': 15,
          };
          return http.Response(jsonEncode(streakData), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/users/me/progress') {
          final progressData = {
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
          };
          return http.Response(jsonEncode(progressData), 200, headers: {'content-type': 'application/json'});
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'full_name': 'Sathya Prakash',
          'date_of_birth': 'Nov 15, 2004',
          'gender': 'Male',
          'city': 'Chennai',
          'institution': 'Sri Sairam Engineering College',
          'degree': 'B.E. (Information Technology)',
          'department': 'Information Technology',
          'academic_year': '3rd Year',
          'semester': '5th Semester',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
            courseApiService: courseService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Sathya Prakash'), findsWidgets);
      expect(find.text('sathyaprakash122333@gmail.com'), findsOneWidget);
      expect(find.text('Google Account'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // Verify Personal Information card
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Nov 15, 2004'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Chennai'), findsOneWidget);

      // Verify Academic Information card
      expect(find.text('Academic Information'), findsOneWidget);
      expect(find.text('Sri Sairam Engineering College'), findsOneWidget);
      expect(find.text('B.E. (Information Technology)'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      expect(find.text('5th Semester'), findsOneWidget);

      // Verify Learning Overview card
      expect(find.text('Learning Overview'), findsOneWidget);
      expect(find.text('Courses Enrolled'), findsOneWidget);
      expect(find.text('Lessons Completed'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);

      // Verify Account & Security card
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Sign-in provider'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Email verification'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Displays "Not provided" empty-state label for missing profile fields without fabricated defaults',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/streak') {
          return http.Response(
            jsonEncode({'current_streak': 0, 'longest_streak': 0, 'active_today': false, 'total_active_days': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/users/me/progress') {
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        // Minimal profile with NO optional fields filled
        final data = {
          'id': 102,
          'firebase_uid': 'user_test_uid_empty',
          'email': 'newstudent@kiko.com',
          'full_name': null,
          'display_name': null,
          'date_of_birth': null,
          'gender': null,
          'city': null,
          'institution': null,
          'degree': null,
          'department': null,
          'academic_year': null,
          'semester': null,
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(
        authService: fakeAuthService,
        client: mockClient,
        baseUrl: 'http://127.0.0.1:8000',
      );
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: null,
            profileApiService: service,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Missing fields must display 'Not provided'
      expect(find.text('Not provided'), findsWidgets);
      // At least 8 optional fields should display 'Not provided'
      expect(find.text('Not provided'), findsNWidgets(9));

      // Old fabricated or improper strings must NOT exist
      expect(find.text('Not added'), findsNothing);
      expect(find.text('Programmer'), findsNothing);
      expect(find.text('Sri Sairam Engineering College'), findsNothing);
      expect(find.text('Chennai'), findsNothing);
    });

    testWidgets('Tapping Edit Profile navigates to EditProfileScreen', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/streak') {
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/users/me/progress') {
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'full_name': 'Sathya Prakash',
          'city': 'Chennai',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editBtn = find.text('Edit Profile');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify EditProfileScreen is pushed
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Tapping Sign Out calls authService.signOut()', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.url.path == '/users/me/streak' || request.url.path == '/users/me/progress') {

          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'full_name': 'Sathya Prakash',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Sign Out');
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthService.signedOut, isTrue);
    });

    testWidgets('Shows error view and allows Try Again when API fails', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1 && request.url.path == '/users/me') {
          return http.Response('Internal Server Error', 500);
        }
        if (request.url.path == '/users/me/streak' || request.url.path == '/users/me/progress') {
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'sathyaprakash122333@gmail.com',
          'full_name': 'Sathya Prakash',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final courseService = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
            courseApiService: courseService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load profile'), findsOneWidget);

      final retryBtn = find.text('Try Again');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sathya Prakash'), findsWidgets);
    });
  });

  group('EditProfileScreen Widget Tests', () {
    late FakeProfileAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeProfileAuthService();
      fakeAuthService.emitUser(MockFbUser());
    });

    testWidgets('Validates required full name and saves updates', (tester) async {
      var didSave = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT') {
          didSave = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['full_name'], 'Sathya Updated');
          return http.Response(jsonEncode(body..['id'] = 1..['firebase_uid'] = 'uid'), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      const initial = UserProfile(
        id: 1,
        firebaseUid: 'uid',
        fullName: 'Sathya Prakash',
        city: 'Chennai',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        authService: fakeAuthService,
                        user: fakeAuthService.currentUser,
                        initialProfile: initial,
                        profileApiService: service,
                      ),
                    ),
                  );
                },
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open EditProfileScreen
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      // Find full name field and edit it
      final nameField = find.widgetWithText(TextFormField, 'Sathya Prakash');
      expect(nameField, findsOneWidget);

      await tester.enterText(nameField, 'Sathya Updated');
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(didSave, isTrue);
    });
  });
}
