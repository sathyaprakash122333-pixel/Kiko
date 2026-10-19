import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../features/auth/logic/auth_service.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/courses/presentation/screens/progress_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

enum KikoTab {
  home,
  learn,
  progress,
  profile,
  dashboard, // Alias for home
  courses, // Alias for learn
}

/// Shared responsive application shell providing mobile-first bottom navigation and desktop sidebar
class KikoAppShell extends StatelessWidget {
  const KikoAppShell({
    super.key,
    required this.currentTab,
    required this.child,
    this.authService,
    this.user,
  });

  final KikoTab currentTab;
  final Widget child;
  final AuthService? authService;
  final fb.User? user;

  bool get _isHome => currentTab == KikoTab.home || currentTab == KikoTab.dashboard;
  bool get _isLearn => currentTab == KikoTab.learn || currentTab == KikoTab.courses;
  bool get _isProgress => currentTab == KikoTab.progress;
  bool get _isProfile => currentTab == KikoTab.profile;

  void _navigateToTab(BuildContext context, KikoTab target) {
    final auth = authService ?? AuthService();
    final currentUser = user ?? auth.currentUser;

    if (target == KikoTab.home || target == KikoTab.dashboard) {
      if (_isHome) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(authService: auth, user: currentUser),
        ),
        (route) => route.isFirst,
      );
    } else if (target == KikoTab.learn || target == KikoTab.courses) {
      if (_isLearn) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CoursesScreen(authService: auth, user: currentUser),
        ),
      );
    } else if (target == KikoTab.progress) {
      if (_isProgress) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProgressScreen(authService: auth, user: currentUser),
        ),
      );
    } else if (target == KikoTab.profile) {
      if (_isProfile) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(authService: auth, user: currentUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 850;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: const Color(0xFF0B1317),
            body: SafeArea(
              child: Row(
                children: [
                  _buildDesktopSidebar(context),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        // Mobile Layout: Screen body placed cleanly above the bottom navigation bar
        return Scaffold(
          backgroundColor: const Color(0xFF0B1317),
          body: SafeArea(bottom: false, child: child),
          bottomNavigationBar: _buildMobileBottomNav(context),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F181D),
        border: Border(
          right: BorderSide(color: Color(0xFF1E2D36), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiko Brand Logo & Name
          InkWell(
            onTap: () => _navigateToTab(context, KikoTab.home),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/kiko_mascot_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/tofu_mascot.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.terminal,
                          color: Color(0xFF00A86B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kiko',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Navigation Links
          _buildSidebarNavItem(
            context: context,
            icon: Icons.home_rounded,
            label: 'Dashboard',
            isSelected: _isHome,
            onTap: () => _navigateToTab(context, KikoTab.home),
          ),
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            context: context,
            icon: Icons.menu_book_rounded,
            label: 'Courses',
            isSelected: _isLearn,
            onTap: () => _navigateToTab(context, KikoTab.learn),
          ),
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            context: context,
            icon: Icons.trending_up_rounded,
            label: 'Progress',
            isSelected: _isProgress,
            onTap: () => _navigateToTab(context, KikoTab.progress),
          ),
          const SizedBox(height: 8),
          _buildSidebarNavItem(
            context: context,
            icon: Icons.person_rounded,
            label: 'Profile',
            isSelected: _isProfile,
            onTap: () => _navigateToTab(context, KikoTab.profile),
          ),

          const Spacer(),

          // Mascot Encouragement Card at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131F25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2E37), width: 1),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Image.asset(
                    'assets/images/kiko_mascot_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/tofu_mascot.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.cruelty_free,
                        color: Color(0xFF00A86B),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Small steps\nbuild big\nprogrammers. 💚',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF16232B),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00A86B) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1317),
        border: Border(
          top: BorderSide(color: Color(0xFF1A2830), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMobileNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _isHome,
                onTap: () => _navigateToTab(context, KikoTab.home),
              ),
              _buildMobileNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Learn',
                isSelected: _isLearn,
                onTap: () => _navigateToTab(context, KikoTab.learn),
              ),
              _buildMobileNavItem(
                icon: Icons.trending_up_rounded,
                label: 'Progress',
                isSelected: _isProgress,
                onTap: () => _navigateToTab(context, KikoTab.progress),
              ),
              _buildMobileNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _isProfile,
                onTap: () => _navigateToTab(context, KikoTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF00A86B);
    final inactiveColor = const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
