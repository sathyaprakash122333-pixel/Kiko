import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kiko_app_shell.dart';
import '../../../../core/widgets/kiko_top_header.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/course_api_service.dart';
import '../../models/user_progress.dart';
import 'course_detail_screen.dart';
import 'test_result_screen.dart';

/// Progress Page displaying student statistics, course completion, and test history
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.authService,
    this.user,
    this.courseApiService,
  });

  final AuthService? authService;
  final fb.User? user;
  final CourseApiService? courseApiService;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final CourseApiService _apiService;
  AuthService? _authService;

  UserOverallProgress _progress = UserOverallProgress.empty();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingResult = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.courseApiService ?? CourseApiService();
    if (widget.authService != null) {
      _authService = widget.authService;
    } else {
      try {
        _authService = AuthService();
      } catch (_) {
        _authService = null;
      }
    }
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token;
      if (_authService != null) {
        token = await _authService?.getIdToken();
      }
      final progress = await _apiService.fetchOverallProgress(token: token);

      if (mounted) {
        setState(() {
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = dt.toLocal();
    final month = months[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return KikoAppShell(
      currentTab: KikoTab.progress,
      authService: _authService,
      user: widget.user,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(KikoColors.primaryForest),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: KikoColors.error),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Progress',
                style: TextStyle(color: KikoColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: KikoColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KikoColors.primaryForest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loadProgress,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        KikoTopHeader(
          title: 'Progress',
          authService: _authService,
          user: widget.user,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Your Learning Progress',
                      style: KikoTypography.headlineMd(
                        color: KikoColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ).copyWith(fontSize: 22, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 6),
              const Text(
                'Track your journey, celebrate your progress, and reach your goals!',
                style: TextStyle(
                  color: KikoColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // 4 Stat Summary Cards
              _buildSummaryCards(),

              const SizedBox(height: 32),

              // Course progress section
              Text(
                'Course progress',
                style: KikoTypography.headlineMd(
                  color: KikoColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              if (_progress.courseProgress.isEmpty)
                _buildEmptyCourseProgress()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _progress.courseProgress.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final cp = _progress.courseProgress[index];
                    return _buildCourseProgressCard(cp);
                  },
                ),

              const SizedBox(height: 36),

              // Recent test results section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent test results',
                    style: KikoTypography.headlineMd(
                      color: KikoColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ).copyWith(fontSize: 18),
                  ),
                  if (_progress.recentTestAttempts.isNotEmpty)
                    Text(
                      '${_progress.recentTestAttempts.length} Total',
                      style: const TextStyle(
                        color: KikoColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildRecentTestResultsTable(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
],
);
}

  Widget _buildSummaryCards() {
    final overallPct = _progress.overallCompletionPercentage;
    final completedLessons = _progress.completedLessonsCount;
    final totalLessons = _progress.totalPublishedLessons > 0 ? _progress.totalPublishedLessons : 20;
    final passedExams = _progress.passedExamsCount;
    final totalExams = _progress.totalPublishedExams > 0 ? _progress.totalPublishedExams : 2;
    final avgScore = _progress.averageTestScore;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 650
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: Overall Progress Ring
            _buildStatCard(
              width: cardWidth,
              customLeading: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (overallPct / 100.0).clamp(0.0, 1.0),
                      backgroundColor: KikoColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(KikoColors.secondaryEmerald),
                      strokeWidth: 4.5,
                    ),
                    Center(
                      child: Text(
                        '${overallPct.toInt()}%',
                        style: const TextStyle(
                          color: KikoColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: 'Overall progress',
              subtitle: '$completedLessons / $totalLessons lessons',
            ),

            // Card 2: Lessons Completed
            _buildStatCard(
              width: cardWidth,
              icon: Icons.check_circle_outline,
              iconColor: KikoColors.secondaryEmerald,
              title: 'Lessons completed',
              value: '$completedLessons / $totalLessons',
            ),

            // Card 3: Tests Passed
            _buildStatCard(
              width: cardWidth,
              icon: Icons.military_tech_outlined,
              iconColor: KikoColors.primaryForest,
              title: 'Tests passed',
              value: '$passedExams / $totalExams',
            ),

            // Card 4: Average Test Score
            _buildStatCard(
              width: cardWidth,
              icon: Icons.star_border,
              iconColor: const Color(0xFFD97706),
              title: 'Average test score',
              value: avgScore > 0 ? '${avgScore.toInt()}%' : 'N/A',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    Widget? customLeading,
    IconData? icon,
    Color? iconColor,
    required String title,
    String? value,
    String? subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (customLeading != null)
            customLeading
          else if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? KikoColors.secondaryEmerald).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? KikoColors.secondaryEmerald, size: 24),
            ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: KikoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (value != null)
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KikoColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KikoColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseProgressCard(CourseProgressItem cp) {
    final isC = cp.language.toLowerCase().contains('c') &&
        !cp.language.toLowerCase().contains('python');
    final badgeText = isC ? 'C Language' : 'Python';

    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  courseId: cp.courseId,
                  apiService: _apiService,
                  authService: _authService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Language badge, Title, Pill
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: KikoColors.tertiaryMint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: KikoColors.secondaryEmerald.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isC ? 'C' : 'Py',
                        style: const TextStyle(
                          color: KikoColors.primaryForest,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cp.courseTitle,
                        style: const TextStyle(
                          color: KikoColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KikoColors.hover,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KikoColors.border),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: KikoColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Middle: Progress bar with % and chevron
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (cp.completionPercentage / 100.0).clamp(0.0, 1.0),
                          backgroundColor: KikoColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(KikoColors.secondaryEmerald),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${cp.completionPercentage.toInt()}%',
                      style: const TextStyle(
                        color: KikoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18, color: KikoColors.textSecondary),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row: Lessons count & Test status
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 14, color: KikoColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${cp.completedLessons} / ${cp.totalLessons} lessons completed',
                      style: const TextStyle(
                        color: KikoColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 18),
                    _buildTestStatusIndicator(cp),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestStatusIndicator(CourseProgressItem cp) {
    if (cp.testStatus == 'passed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: KikoColors.secondaryEmerald),
          const SizedBox(width: 4),
          Text(
            'Test passed (${cp.testScore}/${cp.testTotalQuestions})',
            style: const TextStyle(
              color: KikoColors.secondaryEmerald,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (cp.testStatus == 'failed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
          const SizedBox(width: 4),
          Text(
            'Test score: ${cp.testScore}/${cp.testTotalQuestions} (Needs Review)',
            style: const TextStyle(
              color: Color(0xFFB45309),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.quiz_outlined, size: 14, color: KikoColors.textSecondary),
        SizedBox(width: 4),
        Text(
          'Test not attempted',
          style: TextStyle(
            color: KikoColors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTestResultsTable() {
    final attempts = _progress.recentTestAttempts;

    if (attempts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: KikoColors.secondarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KikoColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: KikoColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No Assessments Attempted Yet',
              style: TextStyle(color: KikoColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Complete course lessons and take final assessments to view authoritative results here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KikoColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Table Header
            Container(
              color: KikoColors.hover,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Course',
                      style: TextStyle(color: KikoColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Score',
                      style: TextStyle(color: KikoColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: TextStyle(color: KikoColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Date',
                      style: TextStyle(color: KikoColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Attempts Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attempts.length,
              separatorBuilder: (_, _) => const Divider(color: KikoColors.border, height: 1),
              itemBuilder: (_, index) {
                final attempt = attempts[index];
                final isC = attempt.language.toLowerCase().contains('c') &&
                    !attempt.language.toLowerCase().contains('python');

                return InkWell(
                  onTap: _isLoadingResult
                      ? null
                      : () async {
                          setState(() => _isLoadingResult = true);
                          try {
                            final token = await _authService?.getIdToken();
                            final result = await _apiService.fetchExamAttemptResult(
                              attempt.attemptId,
                              token: token,
                            );
                            if (!mounted) return;
                            setState(() => _isLoadingResult = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TestResultScreen(
                                  result: result,
                                  courseId: attempt.courseId,
                                  courseTitle: attempt.courseTitle,
                                  apiService: _apiService,
                                  authService: _authService,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _isLoadingResult = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to load attempt result: $e')),
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        // Course with Badge
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: KikoColors.tertiaryMint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: KikoColors.secondaryEmerald.withValues(alpha: 0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isC ? 'C' : 'Py',
                                  style: const TextStyle(
                                    color: KikoColors.primaryForest,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  attempt.courseTitle,
                                  style: const TextStyle(
                                    color: KikoColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${attempt.score} / ${attempt.totalQuestions}',
                            style: const TextStyle(
                              color: KikoColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        // Status Badge
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: attempt.passed
                                    ? KikoColors.tertiaryMint
                                    : KikoColors.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: attempt.passed
                                      ? KikoColors.secondaryEmerald.withValues(alpha: 0.4)
                                      : KikoColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                attempt.passed ? 'Passed' : 'Failed',
                                style: TextStyle(
                                  color: attempt.passed ? KikoColors.secondaryEmerald : KikoColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Date + Chevron
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(attempt.attemptedAt),
                                style: const TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16, color: KikoColors.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCourseProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border),
      ),
      child: const Center(
        child: Text(
          'No course progress found.',
          style: TextStyle(color: KikoColors.textSecondary),
        ),
      ),
    );
  }
}
