import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/kiko_app_shell.dart';
import '../../../../core/widgets/kiko_top_header.dart';
import '../../../auth/logic/auth_service.dart';
import '../../../courses/logic/course_api_service.dart';
import '../../../courses/models/user_progress.dart';
import '../../logic/profile_api_service.dart';
import '../../models/user_profile.dart';

/// User Profile Screen displaying user details, dates, and account actions
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
      final profile = await _apiService.fetchProfile();

      UserOverallProgress? progress;
      try {
        final token = await widget.authService.getIdToken();
        progress = await _courseApiService.fetchOverallProgress(token: token);
      } catch (_) {
        progress = UserOverallProgress.empty();
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _progress = progress;
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

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
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

  Future<void> _showEditDisplayNameDialog() async {
    final currentName = _profile?.displayName ??
        widget.user?.displayName ??
        widget.authService.currentUser?.displayName ??
        '';

    final textController = TextEditingController(text: currentName);
    var isSaving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF162228),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF283B45), width: 1.2),
              ),
              title: Text(
                'Edit Display Name',
                style: KikoTypography.headlineMd(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a name visible on your learning profile:',
                    style: KikoTypography.bodySm(color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F181D),
                      hintText: 'Enter display name',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      errorText: dialogError,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF283B45)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = textController.text.trim();
                          if (newName.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Display name cannot be empty.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          try {
                            final updated = await _apiService.updateDisplayName(newName);
                            if (mounted) {
                              setState(() {
                                _profile = updated;
                              });
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Display name updated successfully!'),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              dialogError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF022C22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF022C22)),
                          ),
                        )
                      : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = dt.toLocal();
    final month = months[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final dateStr = _formatDate(dt);
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$dateStr at $hour:$minute';
  }

  String _getUserInitials(String? name, String? email) {
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'K';
  }

  @override
  Widget build(BuildContext context) {
    return KikoAppShell(
      currentTab: KikoTab.profile,
      authService: widget.authService,
      user: widget.user,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    final fbUser = widget.user ?? widget.authService.currentUser;
    final displayName = _profile?.displayName ?? fbUser?.displayName ?? 'Learner';
    final email = _profile?.email ?? fbUser?.email ?? 'No email associated';
    final photoUrl = fbUser?.photoURL;
    final uid = _profile?.firebaseUid ?? fbUser?.uid ?? 'unknown';

    return Column(
      children: [
        KikoTopHeader(
          title: 'Profile',
          authService: widget.authService,
          user: widget.user,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Page Header
                    Text(
                      'Student Profile',
                      style: KikoTypography.headlineMd(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ).copyWith(fontSize: 22, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage your account information and view your learning summary.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile Card with Avatar & Name
                    _buildProfileHeaderCard(
                      displayName: displayName,
                      email: email,
                      photoUrl: photoUrl,
                    ),
                    const SizedBox(height: 18),

                    // Welcome Sync Banner
                    _buildWelcomeSyncBanner(displayName: displayName),
                    const SizedBox(height: 18),

                    // Account Information Card
                    _buildAccountDetailsCard(),
                    const SizedBox(height: 18),

                    // Security & Diagnostics Card
                    _buildDiagnosticsCard(uid: uid),
                    const SizedBox(height: 18),

                    // Learning Summary Card
                    _buildLearningSummaryCard(),
                    const SizedBox(height: 24),

                    // Sign Out Action Button
                    _buildSignOutButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeaderCard({
    required String displayName,
    required String email,
    required String? photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E2F38),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Avatar with Edit Badge
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildAvatarFallback(displayName, email),
                        )
                      : _buildAvatarFallback(displayName, email),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showEditDisplayNameDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F181D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Display Name with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: KikoTypography.headlineMd(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ).copyWith(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showEditDisplayNameDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16232B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF263844)),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name, String email) {
    return Container(
      color: const Color(0xFF132F2A),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/images/tofu_mascot.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildInitialsAvatar(name, email),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, String email) {
    return Container(
      color: const Color(0xFF164E43),
      child: Center(
        child: Text(
          _getUserInitials(name, email),
          style: const TextStyle(
            color: Color(0xFF34D399),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSyncBanner({required String displayName}) {
    final firstName = displayName.split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2922).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cloud_done_outlined,
              color: Color(0xFF34D399),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your profile and learning records are continuously synchronized.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    final createdAt = _profile?.createdAt;
    final lastLoginAt = _profile?.lastLoginAt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 18, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Account Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _formatDate(createdAt),
          ),
          const Divider(color: Color(0xFF1E2D34), height: 24),
          _buildDetailRow(
            icon: Icons.access_time_outlined,
            label: 'Last Active Session',
            value: _formatDateTime(lastLoginAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsCard({required String uid}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'Authentication & Security',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Provider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Identity Provider',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A262D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    GoogleLogo(size: 13),
                    SizedBox(width: 6),
                    Text(
                      'Google Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E2D34), height: 24),

          // Diagnostic UID
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnostic User Identifier (UID)',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F181D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1F2B31)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        uid,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('UID copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSummaryCard() {
    final lessonsCompleted = _progress?.completedLessonsCount ?? 0;
    final totalLessons = (_progress?.totalPublishedLessons ?? 0) > 0
        ? _progress!.totalPublishedLessons
        : 20;
    final testsPassed = _progress?.passedExamsCount ?? 0;
    final totalTests = (_progress?.totalPublishedExams ?? 0) > 0
        ? _progress!.totalPublishedExams
        : 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart, size: 18, color: Color(0xFF00A86B)),
              SizedBox(width: 8),
              Text(
                'Learning Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Lessons Completed
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Color(0xFF00A86B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lessons Completed',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$lessonsCompleted / $totalLessons',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tests Passed
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.military_tech_outlined,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tests Passed',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$testsPassed / $totalTests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSigningOut ? null : _handleSignOut,
        icon: _isSigningOut
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.logout, size: 18, color: Colors.white),
        label: Text(
          _isSigningOut ? 'Signing out...' : 'Sign Out',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF121E24),
          side: const BorderSide(color: Color(0xFF263742), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: KikoColors.error),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Profile',
              style: KikoTypography.headlineMd(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred while loading your profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF022C22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
