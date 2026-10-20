import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/logic/auth_service.dart';
import '../../logic/course_api_service.dart';
import '../../models/exam.dart';
import 'test_result_screen.dart';

/// Interactive test-taking screen for course-end assessments
class TestScreen extends StatefulWidget {
  const TestScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.examId,
    this.apiService,
    this.authService,
  });

  final int courseId;
  final String courseTitle;
  final int? examId;
  final CourseApiService? apiService;
  final AuthService? authService;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late final CourseApiService _apiService;
  AuthService? _authService;

  ExamPublic? _exam;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // question_id -> option_index
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CourseApiService();
    if (widget.authService != null) {
      _authService = widget.authService;
    } else {
      try {
        _authService = AuthService();
      } catch (_) {
        _authService = null;
      }
    }
    _fetchExam();
  }

  Future<void> _fetchExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exam = await _apiService.fetchCourseExam(widget.courseId);
      if (mounted) {
        setState(() {
          _exam = exam;
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

  void _selectOption(int questionId, int optionIndex) {
    if (_isSubmitting) return;
    setState(() {
      _selectedAnswers[questionId] = optionIndex;
    });
  }

  Future<void> _handleConfirmSubmit() async {
    if (_exam == null || _isSubmitting) return;

    final totalQuestions = _exam!.questions.length;
    final answeredCount = _selectedAnswers.length;
    final isIncomplete = answeredCount < totalQuestions;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (ctx) => AlertDialog(
        backgroundColor: KikoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KikoColors.border),
        ),
        title: Row(
          children: [
            Icon(
              isIncomplete ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: isIncomplete ? const Color(0xFFD97706) : KikoColors.secondaryEmerald,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isIncomplete ? 'Incomplete Assessment' : 'Submit Assessment',
              style: KikoTypography.headlineMd(
                color: KikoColors.textPrimary,
                fontWeight: FontWeight.bold,
              ).copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isIncomplete
              ? 'You have answered $answeredCount of $totalQuestions questions.\n\nUnanswered questions will be scored as 0. Are you sure you want to submit now?'
              : 'You have answered all $totalQuestions questions.\n\nReady to submit for final evaluation?',
          style: const TextStyle(
            color: KikoColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Review Answers',
              style: TextStyle(color: KikoColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncomplete ? const Color(0xFFD97706) : KikoColors.primaryForest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isIncomplete ? 'Submit Anyway' : 'Confirm & Submit',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      await _executeSubmission();
    }
  }

  Future<void> _executeSubmission() async {
    setState(() => _isSubmitting = true);

    try {
      final token = await _authService?.getIdToken();
      final result = await _apiService.submitExam(
        _exam!.id,
        _selectedAnswers,
        token: token,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            result: result,
            courseId: widget.courseId,
            courseTitle: widget.courseTitle,
            apiService: _apiService,
            authService: _authService,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errText = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: KikoColors.error,
            content: Text('Failed to submit test: $errText'),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _executeSubmission,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KikoColors.background,
      appBar: AppBar(
        backgroundColor: KikoColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: KikoColors.border, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: KikoColors.textPrimary),
          tooltip: 'Exit Assessment',
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_selectedAnswers.isEmpty) {
                    Navigator.of(context).pop();
                    return;
                  }
                  final leave = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: KikoColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: KikoColors.border),
                      ),
                      title: const Text(
                        'Leave Assessment?',
                        style: TextStyle(color: KikoColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Your progress on this test attempt will not be saved if you leave now.',
                        style: TextStyle(color: KikoColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Stay', style: TextStyle(color: KikoColors.primaryForest)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Leave', style: TextStyle(color: KikoColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (leave == true && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
        ),
        title: const Text(
          'Course Test',
          style: TextStyle(
            color: KikoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_exam != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KikoColors.tertiaryMint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KikoColors.secondaryEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${_selectedAnswers.length}/${_exam!.questions.length} answered',
                    style: const TextStyle(
                      color: KikoColors.primaryForest,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _exam != null && !_isLoading ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: KikoColors.primaryForest),
            SizedBox(height: 16),
            Text(
              'Loading course assessment...',
              style: TextStyle(color: KikoColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _exam == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: KikoColors.error),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Assessment',
                style: TextStyle(color: KikoColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Assessment not found.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: KikoColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KikoColors.primaryForest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fetchExam,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _exam!.questions;
    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'No questions available in this assessment.',
          style: TextStyle(color: KikoColors.textSecondary),
        ),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final selectedOption = _selectedAnswers[currentQuestion.id];
    final progressPct = ((_currentIndex + 1) / questions.length * 100).toInt();

    final isC = widget.courseTitle.toLowerCase().contains('c') &&
        !widget.courseTitle.toLowerCase().contains('python');

    return Column(
      children: [
        // Question & Options View
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Indicator Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: KikoColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KikoColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KikoColors.tertiaryMint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KikoColors.secondaryEmerald.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isC ? 'C' : 'Py',
                          style: const TextStyle(
                            color: KikoColors.primaryForest,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.courseTitle,
                              style: const TextStyle(
                                color: KikoColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_exam?.title != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                _exam!.title,
                                style: const TextStyle(
                                  color: KikoColors.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Question Progress Row (Question X of Y ... Z%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${questions.length}',
                      style: const TextStyle(
                        color: KikoColors.primaryForest,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedOption != null)
                      const Row(
                        children: [
                          Icon(Icons.check, size: 14, color: KikoColors.secondaryEmerald),
                          SizedBox(width: 4),
                          Text(
                            'Answered',
                            style: TextStyle(
                              color: KikoColors.secondaryEmerald,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '$progressPct%',
                        style: const TextStyle(
                          color: KikoColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Emerald Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / questions.length,
                    backgroundColor: KikoColors.secondarySurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(KikoColors.secondaryEmerald),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),

                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KikoColors.secondarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KikoColors.border, width: 1.2),
                  ),
                  child: Text(
                    currentQuestion.questionText,
                    style: KikoTypography.bodyLg(
                      color: KikoColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),

                // 4 Options
                ...List.generate(currentQuestion.options.length, (optIdx) {
                  final optionText = currentQuestion.options[optIdx];
                  final isSelected = selectedOption == optIdx;
                  final optionLetter = String.fromCharCode(65 + optIdx); // A, B, C, D

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () => _selectOption(currentQuestion.id, optIdx),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? KikoColors.tertiaryMint
                              : KikoColors.secondarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? KikoColors.secondaryEmerald
                                : KikoColors.border,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Option Letter / Checkmark Badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? KikoColors.primaryForest
                                    : KikoColors.hover,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? KikoColors.primaryForest
                                      : KikoColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isSelected
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : Text(
                                      optionLetter,
                                      style: const TextStyle(
                                        color: KikoColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            // Option Text
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  color: KikoColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    final questions = _exam!.questions;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: KikoColors.surface,
        border: Border(top: BorderSide(color: KikoColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: KikoColors.textPrimary,
                  side: const BorderSide(color: KikoColors.border),
                  backgroundColor: KikoColors.secondarySurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (isFirst || _isSubmitting)
                    ? null
                    : () {
                        setState(() => _currentIndex--);
                      },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Prev'),
              ),
            ),
            const SizedBox(width: 12),

            // Next or Submit button
            Expanded(
              flex: 2,
              child: isLast
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KikoColors.secondaryEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _handleConfirmSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Evaluating...' : 'Submit Assessment',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KikoColors.primaryForest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() => _currentIndex++);
                            },
                      label: const Text(
                        'Next Question',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
