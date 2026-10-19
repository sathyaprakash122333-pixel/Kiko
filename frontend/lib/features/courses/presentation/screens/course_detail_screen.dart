import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kiko_top_header.dart';
import '../../../auth/logic/auth_service.dart';
import '../../../lessons/presentation/screens/lesson_screen.dart';
import '../../logic/course_api_service.dart';
import '../../models/course.dart';
import '../../models/course_detail.dart';
import '../../models/exam.dart';
import '../../models/user_progress.dart';
import 'test_screen.dart';

/// Mobile-first Course Details Screen displaying syllabus, progress, and assessment
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.initialCourse,
    this.apiService,
    this.authService,
  });

  final int courseId;
  final Course? initialCourse;
  final CourseApiService? apiService;
  final AuthService? authService;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CourseApiService _apiService;
  AuthService? _authService;

  CourseDetail? _courseDetail;
  ExamAttemptSummary? _latestAttempt;
  CourseProgressDetail? _courseProgress;
  int? _savingLessonId;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0: Lessons, 1: About

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CourseApiService();
    if (widget.authService != null) {
      _authService = widget.authService;
    } else {
      try {
        _authService = AuthService();
      } catch (_) {
        _authService = null;
      }
    }
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _apiService.fetchCourseDetail(widget.courseId);
      ExamAttemptSummary? latestAttempt;
      CourseProgressDetail? courseProgress;

      if (_authService != null) {
        try {
          final token = await _authService!.getIdToken();
          if (token != null && token.isNotEmpty) {
            final attempts = await _apiService.fetchCourseExamAttempts(widget.courseId, token: token);
            if (attempts.isNotEmpty) {
              latestAttempt = attempts.first;
            }
            courseProgress = await _apiService.fetchCourseProgress(widget.courseId, token: token);
          }
        } catch (_) {}
      }

      courseProgress ??= CourseProgressDetail.empty(widget.courseId);

      if (mounted) {
        setState(() {
          _courseDetail = detail;
          _latestAttempt = latestAttempt;
          _courseProgress = courseProgress;
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

  Future<void> _loadCourseProgress() async {
    if (_authService == null) return;
    try {
      final token = await _authService!.getIdToken();
      if (token != null && token.isNotEmpty) {
        final progress = await _apiService.fetchCourseProgress(widget.courseId, token: token);
        if (mounted) {
          setState(() {
            _courseProgress = progress;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleLessonCompletion(LessonSummary lesson) async {
    final currentCompleted = _courseProgress?.completedLessonIds.contains(lesson.id) ?? false;
    final targetCompleted = !currentCompleted;

    setState(() {
      _savingLessonId = lesson.id;
    });

    try {
      final token = await _authService?.getIdToken();
      final result = await _apiService.completeLesson(
        lesson.id,
        token: token,
        completed: targetCompleted,
      );

      if (!mounted) return;

      final updatedIds = Set<int>.from(_courseProgress?.completedLessonIds ?? []);
      if (result.isCompleted) {
        updatedIds.add(lesson.id);
      } else {
        updatedIds.remove(lesson.id);
      }

      final total = _courseDetail?.lessons.length ?? (_courseProgress?.totalLessons ?? 0);
      final count = updatedIds.length;
      final pct = total > 0 ? (count / total) * 100.0 : 0.0;

      setState(() {
        _courseProgress = CourseProgressDetail(
          courseId: widget.courseId,
          courseTitle: _courseDetail?.title ?? '',
          totalLessons: total,
          completedLessons: count,
          completionPercentage: pct,
          isCompleted: total > 0 && count == total,
          completedLessonIds: updatedIds.toList(),
        );
        _savingLessonId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingLessonId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update lesson completion: $e'),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _toggleLessonCompletion(lesson),
          ),
        ),
      );
    }
  }

  void _navigateToAssessment(CourseDetail course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestScreen(
          courseId: course.id,
          courseTitle: course.title,
          examId: course.examId,
          apiService: _apiService,
          authService: _authService,
        ),
      ),
    );
    _fetchCourseDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1317),
      body: SafeArea(
        child: Column(
          children: [
            // Mobile Top Header Bar with Back Button
            KikoTopHeader(
              showBack: true,
              title: 'Course Details',
              onBack: () => Navigator.of(context).pop(),
              authService: _authService,
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _buildCourseContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !_isLoading && _errorMessage == null && _courseDetail != null
          ? _buildBottomActionBar(_courseDetail!)
          : null,
    );
  }

  Widget _buildBottomActionBar(CourseDetail course) {
    final hasAttempt = _latestAttempt != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F181D),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2D36), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              foregroundColor: const Color(0xFF042F24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => _navigateToAssessment(course),
            icon: const Icon(Icons.assignment_turned_in, size: 20, color: Color(0xFF042F24)),
            label: Text(
              hasAttempt ? 'Retake Test' : 'Start Test',
              style: const TextStyle(
                color: Color(0xFF042F24),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 44,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Course',
              style: KikoTypography.headlineMd(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred while fetching course details.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchCourseDetail,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: const Color(0xFF022C22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    final course = _courseDetail!;
    final lessons = course.lessons;

    final isC = course.language.toLowerCase().contains('c') &&
        !course.language.toLowerCase().contains('python');
    final badgeColor = isC ? const Color(0xFF1D4ED8) : const Color(0xFF0284C7);
    final badgeBorder = isC ? const Color(0xFF3B82F6) : const Color(0xFF38BDF8);
    final badgeText = isC ? 'C Language' : 'Python';

    // Real progress derived from authenticated backend progress
    final totalLessons = course.lessons.isNotEmpty ? course.lessons.length : (_courseProgress?.totalLessons ?? 0);
    final completedCount = _courseProgress?.completedLessons ?? 0;
    final progressPct = totalLessons > 0 ? (completedCount / totalLessons) * 100.0 : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121E24),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Language badge & pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: badgeBorder.withValues(alpha: 0.6)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isC ? 'C' : 'Py',
                            style: TextStyle(
                              color: badgeBorder,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: badgeBorder.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeBorder,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      course.description,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info row
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 15, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          '${lessons.length} lessons',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.schedule, size: 15, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        const Text(
                          '~ 20-25 hrs',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          '${progressPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (progressPct / 100.0).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF18262E),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lessons completed text
                    Text(
                      '$completedCount / $totalLessons lessons completed',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Segmented Switch: Lessons | About
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF121E24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E2F38)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? const Color(0xFF00A86B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Lessons',
                            style: TextStyle(
                              color: _selectedTab == 0 ? const Color(0xFF042F24) : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? const Color(0xFF00A86B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'About',
                            style: TextStyle(
                              color: _selectedTab == 1 ? const Color(0xFF042F24) : const Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_selectedTab == 1)
                _buildAboutTab(course)
              else ...[
                // Syllabus Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Syllabus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16232A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${lessons.length} Modules',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lessons list
                if (lessons.isEmpty)
                  _buildEmptyLessonsState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lessons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final isCompleted = _courseProgress?.completedLessonIds.contains(lesson.id) ?? false;
                      return _buildLessonRow(lesson, course, index + 1, isCompleted);
                    },
                  ),
                const SizedBox(height: 24),

                // Final Assessment Card
                _buildFinalAssessmentCard(course),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonRow(
    LessonSummary lesson,
    CourseDetail course,
    int index,
    bool isCompleted,
  ) {
    final isSaving = _savingLessonId == lesson.id;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? const Color(0xFF164E3E) : const Color(0xFF1E2F38),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonScreen(
                  lessonId: lesson.id,
                  courseTitle: course.title,
                  allLessons: course.lessons,
                  apiService: _apiService,
                  authService: _authService,
                  initialCompleted: isCompleted,
                ),
              ),
            );
            _loadCourseProgress();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Number Circle Pill
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF00A86B) : const Color(0xFF16232B),
                    shape: BoxShape.circle,
                    border: isCompleted
                        ? null
                        : Border.all(color: const Color(0xFF283B46), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isCompleted ? const Color(0xFF042F24) : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '~ ${8 + (index * 2 % 7)} min',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                          if (lesson.hasExam) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Assessment Included',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Checkmark / Radio icon with tap-to-complete
                InkWell(
                  onTap: isSaving ? null : () => _toggleLessonCompletion(lesson),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                            ),
                          )
                        : Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: isCompleted ? const Color(0xFF00A86B) : const Color(0xFF475569),
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(CourseDetail course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this Course',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.description,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Key Highlights:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('Structured lessons tailored for complete beginners.'),
          _buildBulletPoint('Syntax explanations with runnable code examples.'),
          _buildBulletPoint('Comprehensive 20-question final assessment.'),
          _buildBulletPoint('Authoritative scoring and instant result evaluation.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF00A86B), fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalAssessmentCard(CourseDetail course) {
    final examTitle = course.examTitle ?? 'Comprehensive Course Assessment';
    final hasAttempt = _latestAttempt != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAttempt
              ? (_latestAttempt!.passed ? const Color(0xFF00A86B) : const Color(0xFFF59E0B))
              : const Color(0xFF1E2F38),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Color(0xFF00A86B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COURSE FINAL ASSESSMENT',
                      style: TextStyle(
                        color: Color(0xFF00A86B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      examTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Test your understanding across all course modules. Complete 20 multiple-choice questions to demonstrate proficiency.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAssessmentChip(Icons.quiz_outlined, '20 Questions'),
              _buildAssessmentChip(Icons.score_outlined, 'Max Score: 20'),
              _buildAssessmentChip(Icons.verified_outlined, 'Passing: 70% (14/20)'),
            ],
          ),
          if (hasAttempt) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _latestAttempt!.passed
                    ? const Color(0xFF063327)
                    : const Color(0xFF3B2011),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _latestAttempt!.passed ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: _latestAttempt!.passed ? const Color(0xFF00A86B) : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Previous Attempt: ${_latestAttempt!.score}/${_latestAttempt!.totalQuestions} (${_latestAttempt!.percentage.toStringAsFixed(1)}%) - ${_latestAttempt!.passed ? "Passed" : "Needs Review"}',
                      style: TextStyle(
                        color: _latestAttempt!.passed ? const Color(0xFF00A86B) : const Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Action button inside card
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: const Color(0xFF042F24),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _navigateToAssessment(course),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Take Final Assessment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF16232B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263844)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLessonsState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38)),
      ),
      child: Column(
        children: const [
          Icon(Icons.menu_book, size: 36, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text(
            'No Lessons Available',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'There are no lessons published for this course yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
