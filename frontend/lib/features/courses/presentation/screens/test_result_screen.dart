import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/course_api_service.dart';
import '../../models/exam.dart';
import 'test_screen.dart';

/// Screen displaying assessment results, pass/fail status, celebrating turtle mascot, and question review
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
    final primaryAccent = passed ? const Color(0xFF00A86B) : const Color(0xFFF43F5E);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1317),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F181D),
        elevation: 0,
        centerTitle: true,
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
          ),
        ),
        title: const Text(
          'Assessment Results',
          style: TextStyle(
            color: Colors.white,
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
                  // Celebrating Mascot Hero Image
                  SizedBox(
                    height: 110,
                    child: Image.asset(
                      'assets/images/kiko_mascot_celebrating.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/kiko_mascot_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.celebration_rounded,
                          size: 60,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Headline & Encouragement
                  Text(
                    passed ? 'Great Job!' : 'Keep Practicing!',
                    style: const TextStyle(
                      color: Colors.white,
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
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Circular Score Gauge Ring (Panel 6)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF121E24),
                      border: Border.all(
                        color: primaryAccent,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.25),
                          blurRadius: 20,
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
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Score',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
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
                          iconColor: const Color(0xFF00A86B),
                          title: 'Correct',
                          value: '${result.score}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.cancel_rounded,
                          iconColor: const Color(0xFFEF4444),
                          title: 'Incorrect',
                          value: '$incorrectCount',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.rule_rounded,
                          iconColor: const Color(0xFF38BDF8),
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
                      color: const Color(0xFF121E24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
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
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryAccent.withValues(alpha: 0.4)),
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
                            color: Color(0xFF94A3B8),
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
                        backgroundColor: const Color(0xFF00A86B),
                        foregroundColor: const Color(0xFF042F24),
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
                        color: const Color(0xFF042F24),
                      ),
                      label: Text(
                        _showAnswers ? 'Hide Review' : 'Review Answers',
                        style: const TextStyle(
                          color: Color(0xFF042F24),
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
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF1E2F38)),
                            backgroundColor: const Color(0xFF121E24),
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
                            foregroundColor: const Color(0xFF00A86B),
                            side: const BorderSide(color: Color(0xFF00A86B)),
                            backgroundColor: const Color(0xFF063327),
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
                          color: Colors.white,
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
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2F38)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
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
    final statusColor = isCorrect ? const Color(0xFF00A86B) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
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
                  color: statusColor.withValues(alpha: 0.15),
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
              color: Colors.white,
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
                color: const Color(0xFF0F181D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2D36)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.explanation,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
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
