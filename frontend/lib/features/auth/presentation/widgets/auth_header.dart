import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Top Navigation Header for Auth screens
class AuthHeader extends StatelessWidget implements PreferredSizeWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showBackButton = true,
    this.avatarUrl,
    this.userInitials,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showBackButton;
  final String? avatarUrl;
  final String? userInitials;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canPop = showBackButton && (Navigator.canPop(context) || onBack != null);

    return Container(
      height: preferredSize.height + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: KikoColors.background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: KikoColors.surfaceContainerHigh.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (canPop) ...[
                InkWell(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: KikoColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: KikoColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Image.asset(
                'assets/images/kiko_logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: KikoColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'K',
                      style: KikoTypography.headlineMd(
                        color: KikoColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ).copyWith(fontSize: 16),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: KikoTypography.headlineMd(
                  color: KikoColors.onSurface,
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 17),
              ),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KikoColors.surfaceContainerHigh,
              border: Border.all(
                color: avatarUrl != null
                    ? KikoColors.primaryContainer
                    : KikoColors.outlineVariant.withValues(alpha: 0.4),
                width: avatarUrl != null ? 1.5 : 1,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            userInitials ?? 'U',
                            style: KikoTypography.headlineMd(
                              color: KikoColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ).copyWith(fontSize: 13),
                          ),
                        );
                      },
                    )
                  : (userInitials != null
                      ? Center(
                          child: Text(
                            userInitials!,
                            style: KikoTypography.headlineMd(
                              color: KikoColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ).copyWith(fontSize: 13),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 18,
                          color: KikoColors.primaryContainer,
                        )),
            ),
          ),
        ],
      ),
    );
  }
}
