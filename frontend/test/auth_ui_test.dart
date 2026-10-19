import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/google_logo.dart';
import 'package:frontend/core/widgets/tactile_button.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';

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
  bool shouldFail = false;
  bool shouldFailFirestore = false;
  bool shouldCancel = false;

  void emitUser(User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<void> syncUserToFirestore(User user) async {
    if (shouldFailFirestore) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Permission denied by security rules',
      );
    }
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (shouldCancel) return null;
    if (shouldFail) {
      throw FirebaseAuthException(
        code: 'unauthorized-domain',
        message: 'Domain not authorized in Firebase Console.',
      );
    }
    final user = MockUser();
    if (shouldFailFirestore) {
      await syncUserToFirestore(user);
    }
    emitUser(user);
    return null;
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_id_token';
}

void main() {
  group('Google Sign-In Only LoginScreen Tests', () {
    late FakeAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeAuthService();
    });

    testWidgets('Unauthenticated view renders prominent Continue with Google button and Stitch components',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );

      // Verify Kiko branding and Stitch layout
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('7-DAY STREAK ACTIVE'), findsOneWidget);
      expect(find.text('Google Sign-In'), findsOneWidget);
      expect(find.text('Welcome back, hacker!'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('End-to-end encrypted session via Firebase Cloud'), findsOneWidget);

      // Verify prominent Continue with Google button and Google logo
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
      expect(find.byType(TactileButton), findsOneWidget);

      // Verify no email/password fields or signup forms exist
      expect(find.text('UNIVERSITY EMAIL'), findsNothing);
      expect(find.text('PASSWORD'), findsNothing);
      expect(find.text('Create an account'), findsNothing);
    });

    testWidgets('Shows error message when Google sign-in is cancelled', (tester) async {
      fakeAuthService.shouldCancel = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );

      final googleButtonFinder = find.text('Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Google sign-in was cancelled.'), findsOneWidget);
    });

    testWidgets('Shows descriptive error message when domain is unauthorized', (tester) async {
      fakeAuthService.shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );

      final googleButtonFinder = find.text('Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Configuration Error: This domain is not listed under Firebase Console -> Authentication -> Settings -> Authorized Domains.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Shows error message when Firestore sync fails and prevents false success',
        (tester) async {
      fakeAuthService.shouldFailFirestore = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );

      final googleButtonFinder = find.text('Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Firestore Sync Error: Unable to save user profile (Permission denied by security rules).',
        ),
        findsOneWidget,
      );
      // Ensure user profile is not displayed
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('Authenticated view displays Kiko Course Dashboard and Sign Out button',
        (tester) async {
      fakeAuthService.emitUser(MockUser());

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar displays greeting with real user display name
      expect(find.text('Hello, Alex Chen!'), findsOneWidget);
      expect(find.text('Ready to learn something amazing today?'), findsOneWidget);

      // Dashboard shows Your Courses section and banner
      expect(find.text('Your Courses'), findsOneWidget);
      expect(find.text('Welcome to Kiko'), findsOneWidget);

      // Sign out button is present
      final signOutFinder = find.text('Sign Out');
      expect(signOutFinder, findsOneWidget);

      // Tapping Sign Out resets back to unauthenticated login screen
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Hello, Alex Chen!'), findsNothing);
    });
  });
}
