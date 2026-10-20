import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_service.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/courses/presentation/screens/courses_screen.dart';
import 'features/courses/presentation/screens/progress_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const KikoApp());
}

/// Root Application Widget for Kiko
class KikoApp extends StatelessWidget {
  const KikoApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();
    return MaterialApp(
      title: 'Kiko',
      debugShowCheckedModeBanner: false,
      theme: KikoTheme.lightTheme,
      home: LoginScreen(authService: auth),
      routes: {
        '/login': (context) => LoginScreen(authService: auth),
        '/dashboard': (context) => auth.currentUser == null
            ? LoginScreen(authService: auth)
            : DashboardScreen(authService: auth),
        '/courses': (context) => auth.currentUser == null
            ? LoginScreen(authService: auth)
            : CoursesScreen(authService: auth),
        '/progress': (context) => auth.currentUser == null
            ? LoginScreen(authService: auth)
            : ProgressScreen(authService: auth),
        '/profile': (context) => auth.currentUser == null
            ? LoginScreen(authService: auth)
            : ProfileScreen(authService: auth),
      },
    );
  }
}
