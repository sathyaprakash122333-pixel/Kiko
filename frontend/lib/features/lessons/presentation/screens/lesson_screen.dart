import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/logic/auth_service.dart';
import '../../../courses/logic/course_api_service.dart';
import '../../../courses/models/course_detail.dart';
import '../../models/lesson_detail.dart';

/// Screen displaying structured lesson educational content and code snippets
class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    this.courseTitle,
    this.allLessons,
    this.apiService,
    this.authService,
    this.initialCompleted,
  });

  final int lessonId;
  final String? courseTitle;
  final List<LessonSummary>? allLessons;
  final CourseApiService? apiService;
  final AuthService? authService;
  final bool? initialCompleted;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final CourseApiService _apiService;
  AuthService? _authService;
  late int _currentLessonId;

  LessonDetail? _lessonDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCompleted = false;
  bool _isSavingCompletion = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CourseApiService();
    _authService = widget.authService;
    if (_authService == null) {
      try {
        _authService = AuthService();
      } catch (_) {
        _authService = null;
      }
    }
    if (widget.initialCompleted != null) {
      _isCompleted = widget.initialCompleted!;
    }
    _currentLessonId = widget.lessonId;
    _fetchLesson(_currentLessonId);
  }

  Future<void> _fetchLesson(int lessonId) async {
    setState(() {
      _currentLessonId = lessonId;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lesson = await _apiService.fetchLessonDetail(lessonId);

      bool isCompleted = false;
      if (_authService != null) {
        try {
          final token = await _authService?.getIdToken();
          if (token != null && token.isNotEmpty) {
            final courseProgress = await _apiService.fetchCourseProgress(lesson.courseId, token: token);
            isCompleted = courseProgress.completedLessonIds.contains(lessonId);
          }
        } catch (_) {}
      } else if (lessonId == widget.lessonId && widget.initialCompleted != null) {
        isCompleted = widget.initialCompleted!;
      }

      if (mounted) {
        setState(() {
          _lessonDetail = lesson;
          _isCompleted = isCompleted;
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

  Future<void> _toggleLessonCompletion() async {
    if (_authService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save lesson progress.')),
      );
      return;
    }

    final newStatus = !_isCompleted;
    setState(() => _isSavingCompletion = true);

    try {
      final token = await _authService?.getIdToken();
      final result = await _apiService.completeLesson(
        _currentLessonId,
        token: token,
        completed: newStatus,
      );

      if (!mounted) return;
      setState(() {
        _isCompleted = result.isCompleted;
        _isSavingCompletion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCompleted ? 'Lesson marked as complete!' : 'Lesson marked as incomplete.'),
          backgroundColor: const Color(0xFF00A86B),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingCompletion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update lesson completion: $e'),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _toggleLessonCompletion,
          ),
        ),
      );
    }
  }

  LessonSummary? get _previousLesson {
    final list = widget.allLessons;
    if (list == null || list.isEmpty) return null;
    final currentIndex = list.indexWhere((l) => l.id == _currentLessonId);
    if (currentIndex > 0) {
      return list[currentIndex - 1];
    }
    return null;
  }

  LessonSummary? get _nextLesson {
    final list = widget.allLessons;
    if (list == null || list.isEmpty) return null;
    final currentIndex = list.indexWhere((l) => l.id == _currentLessonId);
    if (currentIndex >= 0 && currentIndex < list.length - 1) {
      return list[currentIndex + 1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
          'Lesson',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
            tooltip: 'Options',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : _buildLessonContent(),
      ),
      bottomNavigationBar: !_isLoading && _errorMessage == null && _lessonDetail != null
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Lesson',
              style: KikoTypography.headlineMd(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred while fetching the lesson.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchLesson(_currentLessonId),
              icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF042F24)),
              label: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF042F24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: const Color(0xFF042F24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent() {
    final lesson = _lessonDetail!;
    final content = lesson.content.trim();

    // Check language from title / course
    final title = widget.courseTitle ?? '';
    final isPython = title.toLowerCase().contains('python');
    final langLabel = isPython ? 'Python' : 'C Language';
    final langColor = isPython ? const Color(0xFF38BDF8) : const Color(0xFF3B82F6);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lesson Number Pill
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00A86B).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Lesson ${lesson.orderNumber}',
                    style: const TextStyle(
                      color: Color(0xFF00A86B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Big Lesson Title
              Text(
                lesson.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // Meta Row: Language Pill + Duration
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: langColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: langColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPython ? Icons.code : Icons.terminal,
                          size: 13,
                          color: langColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          langLabel,
                          style: TextStyle(
                            color: langColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: const [
                      Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text(
                        '~ 12 min',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (lesson.hasExam) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'Assessment Included',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Content Body or Missing Notice
              if (content.isEmpty)
                _buildMissingContentCard()
              else
                _buildStructuredMarkdown(content),

              const SizedBox(height: 12),
              _buildLessonCompletionBanner(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCompletionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCompleted ? const Color(0xFF063327) : const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCompleted ? const Color(0xFF00A86B) : const Color(0xFF1E2D36),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isCompleted ? const Color(0xFF00A86B).withValues(alpha: 0.2) : const Color(0xFF16232B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: _isCompleted ? const Color(0xFF00A86B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCompleted ? 'Lesson Completed!' : 'Finished this lesson?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isCompleted
                      ? 'Progress saved to your account.'
                      : 'Mark complete to track your learning journey.',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSavingCompletion ? null : _toggleLessonCompletion,
            icon: _isSavingCompletion
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isCompleted ? Icons.check : Icons.done_all_rounded,
                    size: 14,
                    color: _isCompleted ? Colors.white : const Color(0xFF042F24),
                  ),
            label: Text(
              _isCompleted ? 'Completed' : 'Mark Complete',
              style: TextStyle(
                color: _isCompleted ? Colors.white : const Color(0xFF042F24),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCompleted ? const Color(0xFF1E3A2F) : const Color(0xFF00A86B),
              foregroundColor: _isCompleted ? Colors.white : const Color(0xFF042F24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingContentCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D36)),
      ),
      child: Column(
        children: const [
          Icon(Icons.info_outline, size: 44, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No Learning Content Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The learning material for this lesson has not been added to the database yet. Please check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredMarkdown(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // Code blocks ```language
      if (line.trim().startsWith('```')) {
        final lang = line.trim().replaceFirst('```', '').trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        widgets.add(_buildCodeBlock(codeLines.join('\n'), lang.isEmpty ? 'C' : lang));
        widgets.add(const SizedBox(height: 16));
        i++;
        continue;
      }

      // Heading 1: # Title
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              line.substring(2).trim(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Heading 2: ## Subtitle
      if (line.startsWith('## ')) {
        final headingText = line.substring(3).trim();
        // Check if this is "Learning Objectives"
        if (headingText.toLowerCase().contains('learning objectives')) {
          // Parse subsequent bullet points into the special Learning Objectives card
          final objectives = <String>[];
          i++;
          while (i < lines.length && (lines[i].trim().startsWith('- ') || lines[i].trim().isEmpty)) {
            if (lines[i].trim().startsWith('- ')) {
              objectives.add(lines[i].trim().substring(2).trim());
            }
            i++;
          }
          widgets.add(_buildLearningObjectivesCard(headingText, objectives));
          widgets.add(const SizedBox(height: 16));
          continue;
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              headingText,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Heading 3: ### Subtitle
      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              line.substring(4).trim(),
              style: const TextStyle(
                color: Color(0xFF00A86B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // Bullet points: - item
      if (line.trim().startsWith('- ')) {
        final bulletText = line.trim().substring(2).trim();
        widgets.add(_buildBulletItem(bulletText));
        widgets.add(const SizedBox(height: 6));
        i++;
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Standard paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildLearningObjectivesCard(String heading, List<String> objectives) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2F38), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF00A86B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                heading,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final obj in objectives) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00A86B),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      obj,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        height: 1.45,
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

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF00A86B)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code, String language) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1317),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code Header Bar with language tag & Copy action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF142026),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code Body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final prev = _previousLesson;
    final next = _nextLesson;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F181D),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2D36), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prev != null)
              OutlinedButton.icon(
                onPressed: () => _fetchLesson(prev.id),
                icon: const Icon(Icons.arrow_back, size: 14, color: Colors.white70),
                label: Text(
                  'Lesson ${prev.orderNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2E3E47)),
                  backgroundColor: const Color(0xFF16232A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              const SizedBox(width: 40),
            if (next != null)
              ElevatedButton.icon(
                onPressed: () => _fetchLesson(next.id),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF042F24)),
                label: Text(
                  'Next: Lesson ${next.orderNumber}',
                  style: const TextStyle(
                    color: Color(0xFF042F24),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  foregroundColor: const Color(0xFF042F24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}
