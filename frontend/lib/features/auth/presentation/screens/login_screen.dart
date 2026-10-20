import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../logic/auth_service.dart';
import '../widgets/background_accents.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/hero_illustration.dart';

/// Redesigned Kiko Login Screen adhering to the centralized Light Theme:
/// - Clean white backdrop (#FFFFFF) with subtle pale-mint corner geometric accents
/// - PRESERVED centered coding mascot owl hero illustration with code editor window, </> symbol, and books
/// - Bold headline: "Let's get started!" with "Let's get" in dark primary text (#26352D) and "started!" in forest green (#174D36)
/// - Subtitle: "Sign in to continue your\nlearning journey." in secondary text (#66756C)
/// - High-contrast white rounded "Continue with Google" button with official Google logo and soft border
/// - Technical campus-cohort notice with forest-green indicator dot
/// - Authentic Firebase Google Sign-In with Firestore synchronization & error handling
/// - Fully responsive across mobile, tablet, and desktop viewports
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService,
  });

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return; // Prevent repeated clicks

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null && mounted) {
        // User closed or dismissed the Google account selector
        setState(() {
          _errorMessage = 'Google sign-in was cancelled.';
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[LoginScreen] FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      if (mounted) {
        setState(() {
          _errorMessage = _mapFirebaseAuthError(e);
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '[LoginScreen] FirebaseException: plugin=${e.plugin}, code=${e.code}, message=${e.message}',
      );
      if (mounted) {
        setState(() {
          if (e.plugin == 'cloud_firestore' ||
              e.code == 'permission-denied' ||
              e.code == 'unavailable') {
            _errorMessage =
                'Firestore Sync Error: Unable to save user profile (${e.message ?? e.code}).';
          } else {
            _errorMessage = e.message ?? 'Authentication error (${e.code}).';
          }
        });
      }
    } catch (e) {
      debugPrint('[LoginScreen] Unexpected error during Google sign-in: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _mapGeneralAuthError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maps Firebase Authentication error codes to helpful, user-friendly messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled: account selector closed.';
      case 'cancelled-popup-request':
        return 'Sign-in cancelled: another request was initiated.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked by your browser. Please allow popups for this site and try again.';
      case 'unauthorized-domain':
        return 'Configuration Error: Current domain is not authorized in Firebase Console -> Authentication -> Settings -> Authorized Domains.';
      case 'operation-not-allowed':
        return 'Configuration Error: Google Sign-in provider is disabled in Firebase Console -> Authentication -> Sign-in method.';
      case 'network-request-failed':
        return 'Network Error: Unable to reach Google authentication servers. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  /// Diagnoses platform-specific or unexpected exceptions
  String _mapGeneralAuthError(dynamic e) {
    final str = e.toString();
    if (str.contains('10') ||
        str.contains('DEVELOPER_ERROR') ||
        str.contains('developer_error')) {
      return 'Android Configuration Error (Code 10: Developer Error). '
          'Verify that your SHA-1 signing fingerprint is registered for package "com.example.frontend" in Firebase Console.';
    }
    if (str.contains('network') || str.contains('SocketException')) {
      return 'Network Error: Please check your internet connection and try again.';
    }
    return 'Sign-in failed: $str';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // If authenticated, transition into the Kiko Learning Dashboard
        if (user != null) {
          return DashboardScreen(
            authService: _authService,
            user: user,
          );
        }

        // Unauthenticated: render the redesigned Kiko Login Screen in light theme
        return Scaffold(
          backgroundColor: KikoColors.background,
          body: BackgroundAccents(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 24.0,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // PRESERVED Coding Mascot Owl Illustration
                                const HeroIllustration(maxWidth: 360.0),

                                const SizedBox(height: 32.0),

                                // Headline: "Let's get started!"
                                _buildHeading(),

                                const SizedBox(height: 12.0),

                                // Subtitle: "Sign in to continue your\nlearning journey."
                                _buildSubtitle(),

                                const SizedBox(height: 36.0),

                                // Error Banner (if any)
                                if (_errorMessage != null) ...[
                                  _buildErrorBanner(),
                                  const SizedBox(height: 16.0),
                                ],

                                // Google Sign-In Pill Button
                                GoogleSignInButton(
                                  onPressed: _handleGoogleSignIn,
                                  isLoading: _isLoading,
                                ),

                                const SizedBox(height: 20.0),

                                // Campus-only cohort notice
                                _buildCampusNotice(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Headline: "Let's get started!" with "Let's get" in dark primary text (#26352D) and "started!" in forest green (#174D36)
  Widget _buildHeading() {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 34.0,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          height: 1.15,
        ),
        children: const [
          TextSpan(
            text: "Let's get ",
            style: TextStyle(color: KikoColors.textPrimary),
          ),
          TextSpan(
            text: 'started!',
            style: TextStyle(color: KikoColors.primaryForest),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Subtitle: "Sign in to continue your\nlearning journey."
  Widget _buildSubtitle() {
    return Text(
      'Sign in to continue your\nlearning journey.',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        color: KikoColors.textSecondary,
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Campus-only notice: Forest green circular dot + "Google Sign-In only for Kiko campus cohorts."
  Widget _buildCampusNotice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: const BoxDecoration(
            color: KikoColors.primaryForest,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Flexible(
          child: Text(
            'Google Sign-In only for Kiko campus cohorts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: KikoColors.textSecondary,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  /// Informative, user-friendly error banner with dismiss action in light theme
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: KikoColors.errorContainer,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: KikoColors.error.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.error_outline_rounded,
              color: KikoColors.error,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                color: KikoColors.onErrorContainer,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          InkWell(
            onTap: () => setState(() => _errorMessage = null),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.close_rounded,
                color: KikoColors.error,
                size: 18.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
