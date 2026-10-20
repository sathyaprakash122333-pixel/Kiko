import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/google_logo.dart';
import 'package:frontend/features/auth/logic/auth_service.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:frontend/features/auth/presentation/widgets/hero_illustration.dart';

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
        message:
            'Configuration Error: Current domain is not authorized in Firebase Console -> Authentication -> Settings -> Authorized Domains.',
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
  group('Kiko Redesigned Login Screen Tests', () {
    late FakeAuthService fakeAuthService;

    setUp(() {
      fakeAuthService = FakeAuthService();
    });

    testWidgets('Unauthenticated view renders hero illustration, heading, subtitle, Google button, and campus notice',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hero Illustration
      expect(find.byType(HeroIllustration), findsOneWidget);

      // Verify Heading: "Let's get started!"
      expect(find.textContaining("Let's get"), findsOneWidget);
      expect(find.textContaining('started!'), findsOneWidget);

      // Verify Subtitle: "Sign in to continue your\nlearning journey."
      expect(
        find.text('Sign in to continue your\nlearning journey.'),
        findsOneWidget,
      );

      // Verify Google button and Google logo
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);

      // Verify Campus-only notice
      expect(
        find.text('Google Sign-In only for Kiko campus cohorts.'),
        findsOneWidget,
      );

      // Verify old templates/elements are gone
      expect(find.text('UNIVERSITY EMAIL'), findsNothing);
      expect(find.text('PASSWORD'), findsNothing);
      expect(find.text('Create an account'), findsNothing);
      expect(find.text('Welcome back, hacker!'), findsNothing);
      expect(find.text('Welcome back,'), findsNothing);
      expect(find.text('programmer!'), findsNothing);
      expect(find.text('7-DAY STREAK ACTIVE'), findsNothing);
    });

    testWidgets('Renders properly without overflow on narrow mobile (320px width)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining("Let's get"), findsOneWidget);
      expect(find.text('Google Sign-In only for Kiko campus cohorts.'), findsOneWidget);
    });

    testWidgets('Renders centered layout on tablet/desktop (800px width)', (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroIllustration), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining("Let's get"), findsOneWidget);
      expect(find.text('Google Sign-In only for Kiko campus cohorts.'), findsOneWidget);
    });

    testWidgets('Shows error message when Google sign-in is cancelled', (tester) async {
      fakeAuthService.shouldCancel = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      final googleButtonFinder = find.text('Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Current domain is not authorized in Firebase Console'),
        findsOneWidget,
      );
    });

    testWidgets('Shows error message when Firestore sync fails', (tester) async {
      fakeAuthService.shouldFailFirestore = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: LoginScreen(authService: fakeAuthService),
        ),
      );
      await tester.pumpAndSettle();

      final googleButtonFinder = find.text('Continue with Google');
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Firestore Sync Error: Unable to save user profile'),
        findsOneWidget,
      );
    });

    testWidgets('Authenticated view transitions to Kiko Course Dashboard and Sign Out works',
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
