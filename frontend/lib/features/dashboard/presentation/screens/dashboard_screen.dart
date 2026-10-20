import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kiko_app_shell.dart';
import '../../../../core/widgets/kiko_top_header.dart';
import '../../../auth/logic/auth_service.dart';
import '../../../courses/logic/course_api_service.dart';
import '../../../courses/models/course.dart';
import '../../../courses/models/user_progress.dart';
import '../../../courses/presentation/screens/course_detail_screen.dart';
import '../../../courses/presentation/screens/courses_screen.dart';
import '../../../courses/presentation/screens/progress_screen.dart';
import '../widgets/course_card.dart';

/// Redesigned Kiko Learning Dashboard adhering to the centralized Light Theme:
/// - Dominant white background with soft-gray card surfaces
/// - Clean educational typography and line iconography (turtle mascot removed)
/// - Course listing with search filtering and direct lesson navigation
/// - Synchronized progress and streak indicators
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
    this.user,
    this.apiService,
    this.courseApiService,
  });

  final AuthService authService;
  final User? user;
  final CourseApiService? apiService;
  final CourseApiService? courseApiService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final CourseApiService _apiService;
  late final AuthService _authService;

  List<Course> _courses = [];
  UserOverallProgress _userProgress = UserOverallProgress.empty();
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _apiService =
        widget.courseApiService ?? widget.apiService ?? CourseApiService();
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _apiService.fetchCourses();
      UserOverallProgress progress = UserOverallProgress.empty();
      try {
        final token = await _authService.getIdToken();
        progress = await _apiService.fetchOverallProgress(token: token);
      } catch (_) {}

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

  List<Course> get filteredCourses {
    if (_searchQuery.isEmpty) return _courses;
    final q = _searchQuery.toLowerCase();
    return _courses.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.language.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user ?? _authService.currentUser;
    final displayName = user?.displayName ?? 'Learner';

    return KikoAppShell(
      currentTab: KikoTab.home,
      authService: _authService,
      user: user,
      child: Scaffold(
        backgroundColor: KikoColors.background,
        body: RefreshIndicator(
          onRefresh: _fetchCourses,
          color: KikoColors.primaryForest,
          backgroundColor: KikoColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Standard Top Header Bar
                    KikoTopHeader(
                      title: 'Kiko',
                      authService: _authService,
                      user: user,
                    ),

                    // Main Dashboard Body
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Personalized Greeting + Sign Out
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $displayName!',
                                  style: const TextStyle(
                                    color: KikoColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Ready to learn something amazing today?',
                                  style: TextStyle(
                                    color: KikoColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _authService.signOut();
                            },
                            icon: const Icon(
                              Icons.logout,
                              size: 14,
                              color: KikoColors.textSecondary,
                            ),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: KikoColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: KikoColors.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Hero Banner Card ("Learn Today, Build Tomorrow")
                      _buildHeroBanner(),
                      const SizedBox(height: 24),

                      // "Your Courses" Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Your Courses',
                            style: TextStyle(
                              color: KikoColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CoursesScreen(
                                    authService: _authService,
                                    user: user,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    'View All',
                                    style: TextStyle(
                                      color: KikoColors.primaryForest,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: KikoColors.primaryForest,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Field
                      _buildSearchField(),
                      const SizedBox(height: 16),

                      // Course Cards State
                      if (_isLoading)
                        _buildLoadingState()
                      else if (_errorMessage != null)
                        _buildErrorState()
                      else if (filteredCourses.isEmpty)
                        _buildEmptyState()
                      else
                        _buildCoursesList(filteredCourses),

                      const SizedBox(height: 28),

                      // Quick Actions Section
                      _buildQuickActions(user),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KikoColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0826352D),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KikoColors.tertiaryMint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: KikoColors.border,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Welcome to Kiko',
                    style: TextStyle(
                      color: KikoColors.primaryForest,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Main Headline
                const Text(
                  'Learn Today,\nBuild Tomorrow',
                  style: TextStyle(
                    color: KikoColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  _userProgress.completedLessonsCount > 0
                      ? '${_userProgress.completedLessonsCount} lessons completed · Keep going!'
                      : 'Small steps make big progress!',
                  style: const TextStyle(
                    color: KikoColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Start Action Button (Round arrow)
                InkWell(
                  onTap: () async {
                    if (_courses.isNotEmpty) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            courseId: _courses.first.id,
                            initialCourse: _courses.first,
                            apiService: _apiService,
                            authService: _authService,
                          ),
                        ),
                      );
                    } else {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CoursesScreen(
                            authService: _authService,
                            user: widget.user,
                          ),
                        ),
                      );
                    }
                    if (mounted) {
                      _fetchCourses();
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: KikoColors.primaryForest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Clean educational geometric decoration (Turtle removed)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: KikoColors.tertiaryMint,
              shape: BoxShape.circle,
              border: Border.all(
                color: KikoColors.border,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_rounded,
              size: 42,
              color: KikoColors.primaryForest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KikoColors.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(
          color: KikoColors.textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Search courses or languages...',
          hintStyle: const TextStyle(
            color: KikoColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: KikoColors.textSecondary,
            size: 18,
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
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCoursesList(List<Course> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          course: course,
          onTap: () async {
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
              _fetchCourses();
            }
          },
        );
      },
    );
  }

  Widget _buildQuickActions(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: KikoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // My Courses Tile
            Expanded(
              child: _buildActionTile(
                title: 'My Courses',
                icon: Icons.menu_book_rounded,
                iconColor: KikoColors.primaryForest,
                bgColor: KikoColors.tertiaryMint,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CoursesScreen(
                        authService: _authService,
                        user: user,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            // View Progress Tile
            Expanded(
              child: _buildActionTile(
                title: 'View Progress',
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgressScreen(
                        authService: _authService,
                        user: user,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KikoColors.border, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: KikoColors.hover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: KikoColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        children: const [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                KikoColors.primaryForest,
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading courses...',
            style: TextStyle(
              color: KikoColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: KikoColors.errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KikoColors.error.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 36,
            color: KikoColors.error,
          ),
          const SizedBox(height: 10),
          Text(
            'Unable to Load Courses',
            style: KikoTypography.headlineMd(
              color: KikoColors.onErrorContainer,
              fontWeight: FontWeight.bold,
            ).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'An error occurred while connecting to the API.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: KikoColors.onErrorContainer,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchCourses,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KikoColors.primaryForest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KikoColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 36,
              color: KikoColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No courses match "$_searchQuery"'
                  : 'No courses available right now.',
              style: const TextStyle(
                color: KikoColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
