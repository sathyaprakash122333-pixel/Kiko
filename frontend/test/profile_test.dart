import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/profile/logic/profile_api_service.dart';
import 'package:frontend/features/profile/models/user_profile.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockFbUser implements fb.User {
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
    test('UserProfile.fromJson and toJson correctly roundtrip', () {
      final json = {
        'id': 1,
        'firebase_uid': 'firebase_uid_abc',
        'email': 'student@kiko.edu',
        'display_name': 'Kiko Student',
        'created_at': '2026-10-19T08:00:00Z',
        'last_login_at': '2026-10-19T10:30:00Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.firebaseUid, 'firebase_uid_abc');
      expect(profile.email, 'student@kiko.edu');
      expect(profile.displayName, 'Kiko Student');
      expect(profile.createdAt, DateTime.parse('2026-10-19T08:00:00Z'));
      expect(profile.lastLoginAt, DateTime.parse('2026-10-19T10:30:00Z'));

      final out = profile.toJson();
      expect(out['id'], 1);
      expect(out['firebase_uid'], 'firebase_uid_abc');
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
          'email': 'alex.chen@campus.mit.edu',
          'display_name': 'Alex Chen',
          'created_at': '2026-10-19T08:00:00Z',
          'last_login_at': '2026-10-19T10:30:00Z',
        };
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final profile = await service.fetchProfile();

      expect(profile.id, 42);
      expect(profile.displayName, 'Alex Chen');
      expect(profile.email, 'alex.chen@campus.mit.edu');
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
          'email': 'alex.chen@campus.mit.edu',
          'display_name': 'Alexander Chen',
          'created_at': '2026-10-19T08:00:00Z',
          'last_login_at': '2026-10-19T10:30:00Z',
        };
        return http.Response(jsonEncode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuth, client: mockClient, baseUrl: 'http://127.0.0.1:8000');
      final updated = await service.updateDisplayName('Alexander Chen');

      expect(updated.displayName, 'Alexander Chen');
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

    testWidgets('Renders student profile with dates, UID, email, and Sign Out', (tester) async {
      final mockClient = MockClient((request) async {
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'alex.chen@campus.mit.edu',
          'display_name': 'Alex Chen',
          'created_at': '2026-10-19T08:00:00Z',
          'last_login_at': '2026-10-19T10:30:00Z',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Student Profile'), findsOneWidget);

      // Verify User Details
      expect(find.text('Alex Chen'), findsOneWidget);
      expect(find.text('alex.chen@campus.mit.edu'), findsOneWidget);

      // Verify Account Information labels
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Member Since'), findsOneWidget);
      expect(find.text('Last Active Session'), findsOneWidget);

      // Verify Diagnostic UID
      expect(find.text('Diagnostic User Identifier (UID)'), findsOneWidget);
      expect(find.text('user_test_uid_12345678'), findsOneWidget);

      // Verify Sign Out button
      final signOutFinder = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(signOutFinder.evaluate().isNotEmpty ? signOutFinder : find.text('Sign Out'), findsWidgets);
    });

    testWidgets('Tapping Sign Out calls authService.signOut()', (tester) async {
      final mockClient = MockClient((request) async {
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'alex.chen@campus.mit.edu',
          'display_name': 'Alex Chen',
          'created_at': '2026-10-19T08:00:00Z',
          'last_login_at': '2026-10-19T10:30:00Z',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Sign Out').last;
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthService.signedOut, isTrue);
    });

    testWidgets('Shows error view and allows Retry when API fails', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Internal Server Error', 500);
        }
        final data = {
          'id': 101,
          'firebase_uid': 'user_test_uid_12345678',
          'email': 'alex.chen@campus.mit.edu',
          'display_name': 'Alex Chen',
          'created_at': '2026-10-19T08:00:00Z',
          'last_login_at': '2026-10-19T10:30:00Z',
        };
        return http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json'});
      });

      final service = ProfileApiService(authService: fakeAuthService, client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: ProfileScreen(
            authService: fakeAuthService,
            user: fakeAuthService.currentUser,
            profileApiService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Profile'), findsOneWidget);

      final retryBtn = find.text('Retry');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(find.text('Alex Chen'), findsOneWidget);
    });
  });
}
