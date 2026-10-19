import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../courses/models/course.dart';

/// Card displaying course details, language badge, and lesson count
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  final Course course;
  final VoidCallback? onTap;

  Color get _languageColor {
    final lang = course.language.toLowerCase();
    if (lang.contains('c') && !lang.contains('c#') && !lang.contains('css')) {
      return const Color(0xFF3B82F6); // Blue for C
    } else if (lang.contains('python')) {
      return const Color(0xFF38BDF8); // Sky blue / Python
    } else if (lang.contains('rust')) {
      return const Color(0xFFF97316); // Orange for Rust
    }
    return const Color(0xFF10B981); // Emerald default
  }

  Widget _buildLanguageIcon() {
    final lang = course.language.toLowerCase();
    if (lang.contains('c') && !lang.contains('c#') && !lang.contains('css')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'C',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    } else if (lang.contains('python')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.code,
            color: Color(0xFF2DD4BF),
            size: 24,
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: KikoColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KikoColors.outlineVariant,
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.terminal,
          color: KikoColors.primaryContainer,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131F24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22343C),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with language icon and pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLanguageIcon(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _languageColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _languageColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        course.language == 'C' ? 'C Language' : course.language,
                        style: TextStyle(
                          color: _languageColor,
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
                    color: KikoColors.textHeadline,
                    fontWeight: FontWeight.w700,
                  ).copyWith(fontSize: 18, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Course Description
                Text(
                  course.description,
                  style: KikoTypography.bodySm(
                    color: const Color(0xFF94A3B8),
                  ).copyWith(fontSize: 13, height: 1.45),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom action row: lesson count & view course button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 17,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${course.lessonCount} lessons',
                      style: KikoTypography.bodySm(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ).copyWith(fontSize: 13),
                    ),
                  ],
                ),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View Course',
                          style: TextStyle(
                            color: Color(0xFF022C22),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Color(0xFF022C22),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
