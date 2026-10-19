import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum StatusPillVariant {
  primaryAccent,
  subtle,
}

/// Status Pill Capsule for streak, telemetry badges, and security status
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.variant = StatusPillVariant.subtle,
    this.customTextColor,
    this.customIconColor,
    this.customBorderColor,
    this.useCaps = true,
  });

  final String label;
  final IconData icon;
  final StatusPillVariant variant;
  final Color? customTextColor;
  final Color? customIconColor;
  final Color? customBorderColor;
  final bool useCaps;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == StatusPillVariant.primaryAccent;

    final borderColor = customBorderColor ??
        (isPrimary
            ? KikoColors.primaryContainer.withValues(alpha: 0.3)
            : KikoColors.surfaceContainerHigh.withValues(alpha: 0.6));

    final iconColor = customIconColor ??
        (isPrimary ? KikoColors.primaryContainer : KikoColors.onSurfaceVariant);

    final textColor = customTextColor ??
        (isPrimary ? KikoColors.primaryContainer : KikoColors.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KikoColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: KikoColors.primaryContainer.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            useCaps ? label.toUpperCase() : label,
            style: useCaps
                ? KikoTypography.labelCaps(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ).copyWith(fontSize: 11)
                : KikoTypography.labelCode(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
