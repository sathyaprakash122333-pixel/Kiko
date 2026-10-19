import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../../features/auth/logic/auth_service.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Top header bar styled according to the Kiko mobile-first reference layout
class KikoTopHeader extends StatelessWidget {
  const KikoTopHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.authService,
    this.user,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final AuthService? authService;
  final fb.User? user;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    AuthService? auth = authService;
    if (auth == null) {
      try {
        auth = AuthService();
      } catch (_) {
        auth = null;
      }
    }
    final currentUser = user ?? auth?.currentUser;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Either Brand (Logo + Kiko) or Back Button + Title
          Expanded(
            child: showBack
                ? Row(
                    children: [
                      InkWell(
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF142026),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22343E), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2620),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00A86B).withValues(alpha: 0.5),
                            width: 1.2,
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
                      const SizedBox(width: 10),
                      Text(
                        title ?? 'Kiko',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
          ),

          // Right Trailing: Default is Notification Bell + Avatar
          if (trailing != null)
            trailing!
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notification Bell
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No new notifications.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF142026),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22343E), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF94A3B8),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // User Avatar
                InkWell(
                  onTap: () {
                    final localAuth = auth;
                    if (localAuth != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            authService: localAuth,
                            user: currentUser,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00A86B),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty
                          ? Image.network(
                              currentUser.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Image.asset(
      'assets/images/kiko_mascot_logo.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/tofu_mascot.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.person,
          color: Color(0xFF00A86B),
          size: 20,
        ),
      ),
    );
  }
}
