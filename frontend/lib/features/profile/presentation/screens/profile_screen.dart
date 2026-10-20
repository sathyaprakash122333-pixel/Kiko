import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/kiko_app_shell.dart';
import '../../../auth/logic/auth_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../courses/logic/course_api_service.dart';
import '../../../courses/models/user_progress.dart';
import '../../logic/profile_api_service.dart';
import '../../models/user_profile.dart';
import 'edit_profile_screen.dart';

/// Student Profile overview page displaying personal and academic details,
/// real learning statistics, and account security options.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    this.user,
    this.profileApiService,
    this.courseApiService,
  });

  final AuthService authService;
  final fb.User? user;
  final ProfileApiService? profileApiService;
  final CourseApiService? courseApiService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileApiService _apiService;
  late final CourseApiService _courseApiService;

  UserProfile? _profile;
  UserOverallProgress? _progress;
  UserStreak? _streak;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.profileApiService ??
        ProfileApiService(authService: widget.authService);
    _courseApiService = widget.courseApiService ?? CourseApiService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _apiService.fetchProfile();
      final streakFuture = _apiService.fetchStreak();

      final token = await widget.authService.getIdToken();
      final progressFuture = _courseApiService
          .fetchOverallProgress(token: token)
          .catchError((_) => UserOverallProgress.empty());

      final results = await Future.wait([
        profileFuture,
        streakFuture,
        progressFuture,
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile;
          _streak = results[1] as UserStreak;
          _progress = results[2] as UserOverallProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          authService: widget.authService,
          user: widget.user,
          initialProfile: _profile,
          profileApiService: _apiService,
        ),
      ),
    );

    if (updated == true) {
      _loadProfile();
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(authService: widget.authService),
            settings: const RouteSettings(name: '/login'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-out error: $e'),
            backgroundColor: KikoColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KikoAppShell(
      currentTab: KikoTab.profile,
      authService: widget.authService,
      user: widget.user,
      child: Scaffold(
        backgroundColor: KikoColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header bar
              _buildTopBar(),

              // Body content
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: KikoColors.surface,
        border: Border(
          bottom: BorderSide(color: KikoColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profile',
              style: KikoTypography.headlineMd(
                color: KikoColors.textPrimary,
                fontWeight: FontWeight.bold,
              ).copyWith(fontSize: 22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KikoColors.secondarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: KikoColors.border),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: KikoColors.textSecondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: KikoColors.secondaryEmerald, width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student_avatar_snowman.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: KikoColors.tertiaryMint,
                      child: const Icon(Icons.person, color: KikoColors.primaryForest, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KikoColors.primaryForest),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: KikoColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to load profile',
                style: KikoTypography.headlineMd(color: KikoColors.textPrimary, fontWeight: FontWeight.bold)
                    .copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KikoColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KikoColors.primaryForest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: KikoColors.primaryForest,
      backgroundColor: KikoColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            children: [
              // Profile Header Card
              _buildProfileHeaderCard(),
              const SizedBox(height: 18),

              // Personal Information Card
              _buildPersonalInformationCard(),
              const SizedBox(height: 18),

              // Academic Information Card
              _buildAcademicInformationCard(),
              const SizedBox(height: 18),

              // Learning Overview Card
              _buildLearningOverviewCard(),
              const SizedBox(height: 18),

              // Account & Security Card
              _buildAccountSecurityCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final name = _profile?.effectiveNameOrNull ??
        (widget.user?.displayName != null && widget.user!.displayName!.trim().isNotEmpty
            ? widget.user!.displayName!.trim()
            : (widget.authService.currentUser?.displayName != null &&
                    widget.authService.currentUser!.displayName!.trim().isNotEmpty
                ? widget.authService.currentUser!.displayName!.trim()
                : 'Student'));
    final email = _profile?.email ??
        widget.user?.email ??
        widget.authService.currentUser?.email ??
        'student@kiko.com';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;

          final avatarWidget = Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: KikoColors.secondaryEmerald, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: KikoColors.secondaryEmerald.withValues(alpha: 0.15),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/student_avatar_snowman.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: KikoColors.tertiaryMint,
                      child: const Icon(Icons.person, color: KikoColors.primaryForest, size: 40),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: KikoColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: KikoColors.secondaryEmerald, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 13,
                    color: KikoColors.primaryForest,
                  ),
                ),
              ),
            ],
          );

          final detailsWidget = Column(
            crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 19),
              ),
              const SizedBox(height: 3),
              Text(
                email,
                style: const TextStyle(color: KikoColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              // Google account badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoogleLogo(size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Google Account',
                    style: TextStyle(
                      color: KikoColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Prominent Edit Profile Button
              OutlinedButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 15, color: KikoColors.primaryForest),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: KikoColors.primaryForest,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: KikoColors.border, width: 1.2),
                  backgroundColor: KikoColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                avatarWidget,
                const SizedBox(height: 16),
                detailsWidget,
              ],
            );
          }

          return Row(
            children: [
              avatarWidget,
              const SizedBox(width: 20),
              Expanded(child: detailsWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonalInformationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personal Information',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full name',
            value: _profile?.fullName ?? _profile?.displayName ?? widget.user?.displayName,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date of birth',
            value: _profile?.dateOfBirth,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.transgender_outlined,
            label: 'Gender',
            value: _profile?.gender,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'City',
            value: _profile?.city,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInformationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Academic Information',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.account_balance_outlined,
            label: 'College / Institution',
            value: _profile?.institution,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Degree / Course',
            value: _profile?.degree,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.groups_outlined,
            label: 'Department',
            value: _profile?.department,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Academic Year',
            value: _profile?.academicYear,
          ),
          const Divider(color: KikoColors.border, height: 22),
          _buildInfoRow(
            icon: Icons.layers_outlined,
            label: 'Semester',
            value: _profile?.semester,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningOverviewCard() {
    final enrolled = _progress?.totalEnrolledCourses ?? 0;
    final completedLessons = _progress?.completedLessonsCount ?? 0;
    final percentage = (_progress?.overallCompletionPercentage ?? 0).round();
    final streakDays = _streak?.currentStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Learning Overview',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 2x2 Grid of Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildStatCard(
                      icon: Icons.menu_book_outlined,
                      label: 'Courses Enrolled',
                      value: '$enrolled',
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Lessons Completed',
                      value: '$completedLessons',
                    ),
                    const SizedBox(height: 12),
                    _buildProgressStatCard(percentage: percentage),
                    const SizedBox(height: 12),
                    _buildStreakStatCard(streakDays: streakDays),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.menu_book_outlined,
                          label: 'Courses Enrolled',
                          value: '$enrolled',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Lessons Completed',
                          value: '$completedLessons',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgressStatCard(percentage: percentage),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreakStatCard(streakDays: streakDays),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KikoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KikoColors.primaryForest, size: 22),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: KikoColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatCard({required int percentage}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KikoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pie_chart_outline_rounded, color: KikoColors.primaryForest, size: 22),
          const SizedBox(height: 10),
          const Text(
            'Overall Progress',
            style: TextStyle(color: KikoColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: KikoColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(KikoColors.secondaryEmerald),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStatCard({required int streakDays}) {
    final activeToday = _streak?.activeToday ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KikoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 22),
              const Spacer(),
              if (activeToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active Today',
                    style: TextStyle(color: Color(0xFFC2410C), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Current Streak',
            style: TextStyle(color: KikoColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$streakDays ${streakDays == 1 ? 'day' : 'days'}',
            style: const TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: KikoColors.primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                'Account & Security',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sign in provider
          Row(
            children: [
              const Icon(Icons.person_outline, color: KikoColors.textSecondary, size: 18),
              const SizedBox(width: 12),
              const Text(
                'Sign-in provider',
                style: TextStyle(color: KikoColors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              const GoogleLogo(size: 15),
              const SizedBox(width: 6),
              const Text(
                'Google',
                style: TextStyle(color: KikoColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Divider(color: KikoColors.border, height: 22),
          // Email verification
          Row(
            children: [
              const Icon(Icons.mail_outline, color: KikoColors.textSecondary, size: 18),
              const SizedBox(width: 12),
              const Text(
                'Email verification',
                style: TextStyle(color: KikoColors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              const Text(
                'Verified',
                style: TextStyle(color: KikoColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: KikoColors.secondaryEmerald, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              key: const Key('profile_sign_out_button'),
              onPressed: _isSigningOut ? null : _handleSignOut,
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: KikoColors.error),
                    )
                  : const Icon(Icons.logout_rounded, color: KikoColors.error, size: 18),
              label: Text(
                _isSigningOut ? 'Signing out...' : 'Sign Out',
                style: const TextStyle(
                  color: KikoColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: KikoColors.error.withValues(alpha: 0.4), width: 1.2),
                backgroundColor: KikoColors.errorContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const String _notProvidedLabel = 'Not provided';

  bool _hasValidValue(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower == 'not provided' ||
        lower == 'not added' ||
        lower == 'n/a' ||
        lower == 'none' ||
        lower == 'null' ||
        lower == 'undefined' ||
        lower == 'programmer') {
      return false;
    }
    return true;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    final bool hasValue = _hasValidValue(value);
    final String displayText = hasValue ? value!.trim() : _notProvidedLabel;

    return Row(
      children: [
        Icon(icon, color: KikoColors.primaryForest, size: 18),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: KikoColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            displayText,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: hasValue ? KikoColors.textPrimary : KikoColors.textSecondary,
              fontSize: 14,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}
