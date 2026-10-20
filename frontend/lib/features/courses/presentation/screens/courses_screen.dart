import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kiko_app_shell.dart';
import '../../../../core/widgets/kiko_top_header.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/course_api_service.dart';
import '../../models/course.dart';
import '../../models/user_progress.dart';
import 'course_detail_screen.dart';

/// Courses Page displaying catalog of courses with real completion progress
/// Redesigned to centralized Light Theme with clean educational line iconography (no mascot).
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    this.authService,
    this.user,
    this.courseApiService,
  });

  final AuthService? authService;
  final fb.User? user;
  final CourseApiService? courseApiService;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late final CourseApiService _apiService;
  AuthService? _authService;

  List<Course> _courses = [];
  UserOverallProgress _userProgress = UserOverallProgress.empty();
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedFilter = 'All courses';
  final TextEditingController _searchController = TextEditingController();

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
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _apiService.fetchCourses();
      UserOverallProgress progress = UserOverallProgress.empty();

      if (_authService != null) {
        try {
          final token = await _authService?.getIdToken();
          progress = await _apiService.fetchOverallProgress(token: token);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _userProgress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  List<Course> get _filteredCourses {
    return _courses.where((course) {
      // Language filter
      if (_selectedFilter == 'C Language') {
        if (!course.language.toLowerCase().contains('c') ||
            course.language.toLowerCase().contains('python')) {
          return false;
        }
      } else if (_selectedFilter == 'Python') {
        if (!course.language.toLowerCase().contains('python')) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final title = course.title.toLowerCase();
      final desc = course.description.toLowerCase();
      final lang = course.language.toLowerCase();
      return title.contains(query) ||
          desc.contains(query) ||
          lang.contains(query);
    }).toList();
  }

  double _getCourseProgress(int courseId) {
    final match =
        _userProgress.courseProgress.where((cp) => cp.courseId == courseId);
    if (match.isNotEmpty) {
      return match.first.completionPercentage;
    }
    return 0.0;
  }

  int _getCompletedLessons(int courseId) {
    final match =
        _userProgress.courseProgress.where((cp) => cp.courseId == courseId);
    if (match.isNotEmpty) {
      return match.first.completedLessons;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return KikoAppShell(
      currentTab: KikoTab.courses,
      authService: _authService,
      user: widget.user,
      child: Scaffold(
        backgroundColor: KikoColors.background,
        body: _buildBody(),
      ),
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
              const Icon(
                Icons.error_outline,
                size: 48,
                color: KikoColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Courses',
                style: TextStyle(
                  color: KikoColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KikoColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KikoColors.primaryForest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final coursesToDisplay = _filteredCourses;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Standard Top Header Bar
              KikoTopHeader(
                authService: _authService,
                user: widget.user,
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title & Subtitle
                    Text(
                      'Your Courses',
                      style: KikoTypography.headlineMd(
                        color: KikoColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ).copyWith(fontSize: 22, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Explore our beginner-friendly courses and start your coding journey today.',
                      style: TextStyle(
                        color: KikoColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search & Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: KikoColors.secondarySurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KikoColors.border),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: KikoColors.textPrimary,
                                fontSize: 13,
                              ),
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                hintStyle: const TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: KikoColors.textSecondary,
                                  size: 19,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: KikoColors.textSecondary,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildFilterDropdown(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Courses List
                    if (coursesToDisplay.isEmpty)
                      _buildEmptyCoursesView()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: coursesToDisplay.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final course = coursesToDisplay[index];
                          final progress = _getCourseProgress(course.id);
                          return _buildCourseCard(course, progress);
                        },
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KikoColors.border),
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedFilter,
        color: KikoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KikoColors.border),
        ),
        onSelected: (val) => setState(() => _selectedFilter = val),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'All courses',
            child: Text(
              'All courses',
              style: TextStyle(color: KikoColors.textPrimary, fontSize: 13),
            ),
          ),
          const PopupMenuItem(
            value: 'C Language',
            child: Text(
              'C Language',
              style: TextStyle(color: KikoColors.textPrimary, fontSize: 13),
            ),
          ),
          const PopupMenuItem(
            value: 'Python',
            child: Text(
              'Python',
              style: TextStyle(color: KikoColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedFilter,
                style: const TextStyle(
                  color: KikoColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: KikoColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, double progress) {
    final isC = course.language.toLowerCase().contains('c') &&
        !course.language.toLowerCase().contains('python');
    final badgeColor = isC ? const Color(0xFF2563EB) : const Color(0xFF0D9488);
    final badgeBg = isC ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDFA);
    final badgeBorder = isC ? const Color(0xFFBFDBFE) : const Color(0xFF99F6E4);
    final badgeText = isC ? 'C Language' : 'Python';

    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KikoColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0626352D),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  courseId: course.id,
                  initialCourse: course,
                  apiService: _apiService,
                  authService: _authService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          hoverColor: KikoColors.hover,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Language icon badge & Language pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isC ? 'C' : 'Py',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeBorder),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Course Title
                Text(
                  course.title,
                  style: KikoTypography.headlineMd(
                    color: KikoColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ).copyWith(fontSize: 19),
                ),

                const SizedBox(height: 8),

                // Course Description
                Text(
                  course.description,
                  style: const TextStyle(
                    color: KikoColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                // Middle Row: Metrics & Line Art (Turtle mascot removed)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left Column: Lessons, Hours, Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 16,
                                color: KikoColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${course.lessonCount > 0 ? course.lessonCount : 10} lessons',
                                style: const TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.schedule,
                                size: 16,
                                color: KikoColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '~ 20-25 hrs',
                                style: TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Progress row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_getCompletedLessons(course.id)} / ${course.lessonCount} lessons completed',
                                style: const TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  color: KikoColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (progress / 100.0).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                KikoColors.secondaryEmerald,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Clean circular icon badge (Replacing turtle mascot with laptop)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: KikoColors.tertiaryMint,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KikoColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.laptop_chromebook_rounded,
                        size: 26,
                        color: KikoColors.primaryForest,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Button: Continue learning ->
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KikoColors.primaryForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            courseId: course.id,
                            initialCourse: course,
                            apiService: _apiService,
                            authService: _authService,
                          ),
                        ),
                      );
                      if (mounted) {
                        _loadData();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress > 0 ? 'Continue learning' : 'View course',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
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

  Widget _buildEmptyCoursesView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: KikoColors.textSecondary,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Courses Found',
            style: TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search query or language filter.',
            style: TextStyle(
              color: KikoColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedFilter = 'All courses';
              });
            },
            child: const Text(
              'Reset Filters',
              style: TextStyle(
                color: KikoColors.primaryForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
