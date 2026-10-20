import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/course_api_service.dart';
import '../../models/exam.dart';
import 'test_screen.dart';

/// Screen displaying assessment results, pass/fail status, clean status badge, and question review
class TestResultScreen extends StatefulWidget {
  const TestResultScreen({
    super.key,
    required this.result,
    required this.courseId,
    required this.courseTitle,
    this.apiService,
    this.authService,
  });

  final ExamResult result;
  final int courseId;
  final String courseTitle;
  final CourseApiService? apiService;
  final AuthService? authService;

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  bool _showAnswers = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final passed = result.passed;
    final incorrectCount = result.totalQuestions - result.score;
    final primaryAccent = passed ? KikoColors.secondaryEmerald : KikoColors.error;

    return Scaffold(
      backgroundColor: KikoColors.background,
      appBar: AppBar(
        backgroundColor: KikoColors.surface,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: KikoColors.border, height: 1),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: KikoColors.secondarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KikoColors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: KikoColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Assessment Results',
          style: TextStyle(
            color: KikoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Clean Circular Status Icon Badge (replaces turtle mascot)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: passed ? KikoColors.tertiaryMint : const Color(0xFFFEF3C7),
                      border: Border.all(
                        color: passed
                            ? KikoColors.secondaryEmerald.withValues(alpha: 0.3)
                            : const Color(0xFFFDE68A),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                      size: 46,
                      color: passed ? KikoColors.secondaryEmerald : const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Headline & Encouragement
                  Text(
                    passed ? 'Great Job!' : 'Keep Practicing!',
                    style: const TextStyle(
                      color: KikoColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passed
                        ? 'You completed the test successfully.'
                        : 'Review your mistakes and retake when you are ready.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: KikoColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Circular Score Gauge Ring
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KikoColors.secondarySurface,
                      border: Border.all(
                        color: primaryAccent,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${result.score}/${result.totalQuestions}',
                          style: TextStyle(
                            color: primaryAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${result.percentage.toStringAsFixed(1)}% Score',
                          style: const TextStyle(
                            color: KikoColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Score',
                          style: TextStyle(
                            color: KikoColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Metric Cards in a row: Correct, Incorrect, Total / Threshold
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.check_circle_rounded,
                          iconColor: KikoColors.secondaryEmerald,
                          title: 'Correct',
                          value: '${result.score}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.cancel_rounded,
                          iconColor: KikoColors.error,
                          title: 'Incorrect',
                          value: '$incorrectCount',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.rule_rounded,
                          iconColor: KikoColors.primaryForest,
                          title: 'Threshold',
                          value: '${result.totalQuestions} (70%)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Result Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KikoColors.secondarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KikoColors.border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Result',
                              style: TextStyle(
                                color: KikoColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                passed ? 'PASSED (>= 70%)' : 'NEEDS REVIEW (< 70%)',
                                style: TextStyle(
                                  color: primaryAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You scored ${result.percentage.toStringAsFixed(0)}% (${result.score}/${result.totalQuestions}). Passing threshold is 70% (${(result.totalQuestions * 0.7).ceil()}/${result.totalQuestions}).',
                          style: const TextStyle(
                            color: KikoColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons: Review Answers & Retake Test
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KikoColors.primaryForest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() => _showAnswers = !_showAnswers);
                      },
                      icon: Icon(
                        _showAnswers ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _showAnswers ? 'Hide Review' : 'Review Answers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KikoColors.textPrimary,
                            side: const BorderSide(color: KikoColors.border),
                            backgroundColor: KikoColors.secondarySurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Back to Course',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KikoColors.primaryForest,
                            side: const BorderSide(color: KikoColors.secondaryEmerald),
                            backgroundColor: KikoColors.tertiaryMint,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => TestScreen(
                                  courseId: widget.courseId,
                                  courseTitle: widget.courseTitle,
                                  examId: result.examId,
                                  apiService: widget.apiService,
                                  authService: widget.authService,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.replay_rounded, size: 16),
                          label: const Text(
                            'Retake Test',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Question-by-question review section
                  if (_showAnswers || result.details.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Answer Review',
                        style: KikoTypography.headlineMd(
                          color: KikoColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ).copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: result.details.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = result.details[index];
                        return _buildQuestionReviewCard(index + 1, item);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KikoColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: KikoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(int questionNum, QuestionResultDetail item) {
    final isCorrect = item.isCorrect;
    final statusColor = isCorrect ? KikoColors.secondaryEmerald : KikoColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question $questionNum',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                isCorrect ? 'Correct' : 'Incorrect',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.questionText,
            style: const TextStyle(
              color: KikoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (item.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KikoColors.hover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KikoColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: KikoColors.primaryForest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.explanation,
                      style: const TextStyle(
                        color: KikoColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
