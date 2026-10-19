import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/mascot_speech_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tactile_button.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../logic/auth_service.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_header.dart';

/// Google-Only Login Screen
/// Renders the Google sign-in interface when signed out, and automatically
/// switches to the Kiko Course Dashboard upon successful authentication.
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
        // User closed or dismissed the picker
        setState(() {
          _errorMessage = 'Google sign-in was cancelled.';
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '[LoginScreen] FirebaseException caught: plugin=${e.plugin}, code=${e.code}, message=${e.message}',
      );
      if (mounted) {
        setState(() {
          if (e.plugin == 'cloud_firestore' ||
              e.code == 'permission-denied' ||
              e.code == 'unavailable') {
            _errorMessage =
                'Firestore Sync Error: Unable to save user profile (${e.message ?? e.code}).';
          } else if (e.code == 'popup-closed-by-user') {
            _errorMessage = 'Sign-in cancelled: The Google sign-in popup was closed.';
          } else if (e.code == 'cancelled-popup-request') {
            _errorMessage = 'Sign-in cancelled: A newer sign-in request was initiated.';
          } else if (e.code == 'unauthorized-domain') {
            _errorMessage =
                'Configuration Error: This domain is not listed under Firebase Console -> Authentication -> Settings -> Authorized Domains.';
          } else if (e.code == 'operation-not-allowed') {
            _errorMessage =
                'Configuration Error: Google Sign-in provider is not enabled in Firebase Console -> Authentication -> Sign-in method.';
          } else {
            _errorMessage = e.message ?? 'Authentication error (${e.code}).';
          }
        });
      }
    } catch (e) {
      debugPrint('[LoginScreen] Unexpected error during Google sign-in: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign-in failed: ${e.toString()}';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // If authenticated, show the Kiko Learning Dashboard
        if (user != null) {
          return DashboardScreen(
            authService: _authService,
            user: user,
          );
        }

        // Otherwise, show the Google sign-in interface
        return Scaffold(
          backgroundColor: KikoColors.background,
          appBar: const AuthHeader(
            title: 'Login',
            showBackButton: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Status Badges
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        spacing: 8,
                        children: const [
                          StatusPill(
                            label: '7-Day Streak Active',
                            icon: Icons.local_fire_department,
                            variant: StatusPillVariant.primaryAccent,
                          ),
                          StatusPill(
                            label: 'Google Sign-In',
                            icon: Icons.lock_outline,
                            variant: StatusPillVariant.subtle,
                            useCaps: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mascot Greeting Section
                      const MascotSpeechCard(
                        title: 'Welcome back, hacker!',
                        message:
                            'Sign in with your Google account to sync your modules and track your streak.',
                      ),
                      const SizedBox(height: 16),

                      // Primary Sign-In Card
                      AuthCard(
                        title: 'Sign In',
                        subtitle:
                            'Continue with your Google account to access your modules.',
                        securityBannerText:
                            'End-to-end encrypted session via Firebase Cloud',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error Message Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: KikoColors.errorContainer
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: KikoColors.error
                                        .withValues(alpha: 0.8),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 18,
                                      color: KikoColors.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: KikoTypography.bodySm(
                                          color: KikoColors.onErrorContainer,
                                        ).copyWith(fontSize: 13, height: 1.35),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () =>
                                          setState(() => _errorMessage = null),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: KikoColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Prominent Continue with Google Button
                            TactileButton(
                              text: 'Continue with Google',
                              variant: TactileButtonVariant.google,
                              leadingIcon: const GoogleLogo(size: 20),
                              isLoading: _isLoading,
                              onPressed: _handleGoogleSignIn,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer
                      Center(
                        child: Text(
                          'Google Sign-In only for Kiko campus cohorts.',
                          style: KikoTypography.bodySm(
                            color: KikoColors.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ).copyWith(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Decorative Floating Progress Pill
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: KikoColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            'Ready for CS204: Data Structures & Trees',
                            style: KikoTypography.labelCode(
                              color: KikoColors.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
