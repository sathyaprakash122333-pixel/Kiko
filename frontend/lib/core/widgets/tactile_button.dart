import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum TactileButtonVariant { primary, secondary, google }

/// Tactile 3D Action Button matching the Stitch design
/// Features a bevel bottom shadow that depresses when pressed.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.height = 50.0,
    this.width = double.infinity,
    this.customBackgroundColor,
    this.customTextColor,
    this.customShadowColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final double height;
  final double width;
  final Color? customBackgroundColor;
  final Color? customTextColor;
  final Color? customShadowColor;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final Color shadowColor;
    final Border? border;

    if (widget.variant == TactileButtonVariant.google) {
      backgroundColor = _isEnabled
          ? (widget.customBackgroundColor ?? Colors.white)
          : Colors.white.withValues(alpha: 0.7);
      textColor = widget.customTextColor ?? const Color(0xFF1F1F1F);
      shadowColor = widget.customShadowColor ?? const Color(0xFFB0B5B0);
      border = Border.all(color: const Color(0xFFE0E3E0), width: 1);
    } else if (widget.variant == TactileButtonVariant.primary) {
      backgroundColor = _isEnabled
          ? (widget.customBackgroundColor ?? KikoColors.primaryContainer)
          : KikoColors.primaryContainer.withValues(alpha: 0.5);
      textColor = widget.customTextColor ?? KikoColors.onPrimary;
      shadowColor = widget.customShadowColor ?? KikoColors.tactileShadowPrimary;
      border = null;
    } else {
      backgroundColor = _isEnabled
          ? (widget.customBackgroundColor ?? KikoColors.surfaceContainerLow)
          : KikoColors.surfaceContainerLow.withValues(alpha: 0.5);
      textColor = widget.customTextColor ?? KikoColors.onSurface;
      shadowColor = widget.customShadowColor ?? Colors.black.withValues(alpha: 0.5);
      border = Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1);
    }

    const double bevelDepth = 4.0;
    final currentOffset = _isPressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height + bevelDepth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Bottom shadow layer (bevel)
            Positioned(
              top: bevelDepth,
              left: 0,
              right: 0,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            // Front button face
            Positioned(
              top: currentOffset,
              left: 0,
              right: 0,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: border,
                  boxShadow: widget.variant == TactileButtonVariant.primary && !_isPressed
                      ? [
                          BoxShadow(
                            color: KikoColors.primaryContainer.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Connecting to Google...',
                            style: KikoTypography.headlineMd(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ).copyWith(fontSize: 14),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            widget.leadingIcon!,
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: KikoTypography.headlineMd(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ).copyWith(fontSize: 15),
                          ),
                          if (widget.trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            widget.trailingIcon!,
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
