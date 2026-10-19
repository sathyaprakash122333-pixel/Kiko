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

/// Mobile-first Learning Dashboard Screen displaying enrolled courses and quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.authService,
    this.user,
    this.courseApiService,
  });

  final AuthService? authService;
  final User? user;
  final CourseApiService? courseApiService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthService _authService;
  late final CourseApiService _apiService;

  List<Course> _courses = [];
  UserOverallProgress _userProgress = UserOverallProgress.empty();
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _apiService = widget.courseApiService ?? CourseApiService();
    _fetchCourses();
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
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user ?? _authService.currentUser;

    return KikoAppShell(
      currentTab: KikoTab.home,
      authService: _authService,
      user: currentUser,
      child: _buildMainContent(currentUser),
    );
  }

  Widget _buildMainContent(User? user) {
    final displayName = user?.displayName ?? 'Learner';
    final filteredCourses = _courses.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.language.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mobile Top Header Bar
              KikoTopHeader(
                authService: _authService,
                user: user,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                  color: Colors.white,
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
                                  color: Color(0xFF94A3B8),
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
                          icon: const Icon(Icons.logout, size: 14, color: Color(0xFF94A3B8)),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E2D36)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            color: Colors.white,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: const [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF00A86B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: Color(0xFF00A86B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Field (collapsible / compact)
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
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF07382E),
            Color(0xFF05241C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF0D634C),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Welcome to Kiko',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
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
                        color: Colors.white,
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
                        color: Color(0xFFA7F3D0),
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
                          color: const Color(0xFF00A86B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF042F24),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Waving Mascot Image on Right
              Flexible(
                flex: 4,
                child: SizedBox(
                  height: 125,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/kiko_mascot_waving.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/kiko_hero.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/tofu_mascot.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.school,
                            size: 64,
                            color: Color(0xFF00A86B),
                          ),
                        ),
                      ),
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

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E2F38),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 19,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            InkWell(
              onTap: () => setState(() => _searchQuery = ''),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
        ],
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
            color: Colors.white,
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
                iconColor: const Color(0xFF00A86B),
                bgColor: const Color(0xFF063327),
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
                iconColor: const Color(0xFF38BDF8),
                bgColor: const Color(0xFF082B38),
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
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                    border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
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
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2F38)),
      ),
      child: Column(
        children: const [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading courses...',
            style: TextStyle(
              color: Color(0xFF94A3B8),
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
        color: KikoColors.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KikoColors.error.withValues(alpha: 0.6),
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchCourses,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A86B),
              foregroundColor: const Color(0xFF022C22),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2F38)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 36,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No courses match "$_searchQuery"'
                  : 'No courses available right now.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
