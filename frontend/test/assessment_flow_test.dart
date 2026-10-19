import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/courses/logic/course_api_service.dart';
import 'package:frontend/features/courses/models/exam.dart';
import 'package:frontend/features/courses/presentation/screens/course_detail_screen.dart';
import 'package:frontend/features/courses/presentation/screens/test_result_screen.dart';
import 'package:frontend/features/courses/presentation/screens/test_screen.dart';

void main() {
  final sampleExamJson = {
    'id': 1,
    'course_id': 1,
    'title': 'C Programming Comprehensive Final Assessment',
    'pass_percentage': 70.0,
    'question_count': 2,
    'questions': [
      {
        'id': 101,
        'question_text': 'Which function is used to print output in C?',
        'options': ['print()', 'printf()', 'echo()', 'System.out.println()'],
        'order_number': 1,
      },
      {
        'id': 102,
        'question_text': 'What is the correct file extension for a C source file?',
        'options': ['.c', '.cpp', '.py', '.java'],
        'order_number': 2,
      },
    ],
  };

  final sampleResultJson = {
    'attempt_id': 50,
    'exam_id': 1,
    'exam_title': 'C Programming Comprehensive Final Assessment',
    'score': 2,
    'total_questions': 2,
    'percentage': 100.0,
    'pass_percentage': 70.0,
    'passed': true,
    'attempted_at': '2026-10-19T12:00:00Z',
    'details': [
      {
        'question_id': 101,
        'question_text': 'Which function is used to print output in C?',
        'options': ['print()', 'printf()', 'echo()', 'System.out.println()'],
        'selected_option_index': 1,
        'correct_option_index': 1,
        'is_correct': true,
        'explanation': 'printf() is declared in <stdio.h> and formats text to stdout.',
      },
      {
        'question_id': 102,
        'question_text': 'What is the correct file extension for a C source file?',
        'options': ['.c', '.cpp', '.py', '.java'],
        'selected_option_index': 0,
        'correct_option_index': 0,
        'is_correct': true,
        'explanation': 'C source code files conventionally end with the .c extension.',
      },
    ],
  };

  group('TestScreen Assessment Experience Tests', () {
    testWidgets('Loads test questions without answer-key leakage and displays options', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify header and question info
      expect(find.text('C Programming Comprehensive Final Assessment'), findsOneWidget);
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('Which function is used to print output in C?'), findsOneWidget);

      // Verify 4 options rendered
      expect(find.text('print()'), findsOneWidget);
      expect(find.text('printf()'), findsOneWidget);
      expect(find.text('echo()'), findsOneWidget);
      expect(find.text('System.out.println()'), findsOneWidget);

      // Initially 0/2 answered
      expect(find.text('0/2 answered'), findsOneWidget);
    });

    testWidgets('Selecting and changing answers updates selection and answered counter', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on option B: printf()
      await tester.tap(find.text('printf()'));
      await tester.pumpAndSettle();

      // Answered counter updates
      expect(find.text('1/2 answered'), findsOneWidget);
      expect(find.text('Answered'), findsOneWidget);

      // Change answer to option A: print()
      await tester.tap(find.text('print()'));
      await tester.pumpAndSettle();

      // Counter remains 1/2 answered
      expect(find.text('1/2 answered'), findsOneWidget);
    });

    testWidgets('Question navigation preserves selected answer state across Next and Prev', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select printf() on Question 1
      await tester.tap(find.text('printf()'));
      await tester.pumpAndSettle();

      // Navigate to Next Question
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Question 2 is now visible
      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(find.text('What is the correct file extension for a C source file?'), findsOneWidget);

      // Navigate Back via Prev button
      await tester.tap(find.text('Prev'));
      await tester.pumpAndSettle();

      // Back on Question 1, selection is preserved
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('1/2 answered'), findsOneWidget);
    });

    testWidgets('Incomplete submission warning dialog triggers when questions are unanswered', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Advance to Question 2 without answering Question 1
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // On Question 2, tap Submit Assessment
      await tester.tap(find.text('Submit Assessment'));
      await tester.pumpAndSettle();

      // Incomplete warning dialog appears
      expect(find.text('Incomplete Assessment'), findsOneWidget);
      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('Submit Anyway'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Review Answers'));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete Assessment'), findsNothing);
    });

    testWidgets('Submitting completed answers navigates to TestResultScreen with full evaluation', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/exams/1/submit') {
          return http.Response(jsonEncode(sampleResultJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Answer Question 1: printf()
      await tester.tap(find.text('printf()'));
      await tester.pumpAndSettle();

      // Go to Question 2
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Answer Question 2: .c
      await tester.tap(find.text('.c'));
      await tester.pumpAndSettle();

      // Tap Submit Assessment
      await tester.tap(find.text('Submit Assessment'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Submit Assessment'), findsWidgets);
      expect(find.text('Confirm & Submit'), findsOneWidget);

      // Confirm submission
      await tester.tap(find.text('Confirm & Submit'));
      await tester.pumpAndSettle();

      // Results screen appears
      expect(find.text('Assessment Results'), findsOneWidget);
      expect(find.text('PASSED (>= 70%)'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Score 2
      expect(find.text('100.0% Score'), findsOneWidget);
      expect(find.text('Answer Review'), findsOneWidget);
      expect(find.text('printf() is declared in <stdio.h> and formats text to stdout.'), findsOneWidget);
    });

    testWidgets('Shows network error and allows Try Again on test fetch failure', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestScreen(
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Assessment'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Which function is used to print output in C?'), findsOneWidget);
    });
  });

  group('TestResultScreen Widget Tests', () {
    testWidgets('Renders score, pass badge, correct metrics, explanations and Retake button', (tester) async {
      final examResult = ExamResult.fromJson(sampleResultJson);

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: TestResultScreen(
            result: examResult,
            courseId: 1,
            courseTitle: 'Introduction to C Programming',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verification of score and metrics
      expect(find.text('Assessment Results'), findsOneWidget);
      expect(find.text('PASSED (>= 70%)'), findsOneWidget);
      expect(find.text('100.0% Score'), findsOneWidget);
      expect(find.text('Correct'), findsWidgets);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Threshold'), findsOneWidget);

      // Question review and explanation
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('printf() is declared in <stdio.h> and formats text to stdout.'), findsOneWidget);

      // Buttons
      expect(find.text('Back to Course'), findsOneWidget);
      expect(find.text('Retake Test'), findsOneWidget);
    });
  });

  group('CourseDetailScreen Assessment Integration Tests', () {
    testWidgets('Displays Course Final Assessment card with syllabus and starts test on click', (tester) async {
      final courseDetailJson = {
        'id': 1,
        'title': 'Introduction to C Programming',
        'description': 'A comprehensive C course.',
        'language': 'C',
        'exam_id': 1,
        'exam_title': 'C Programming Comprehensive Final Assessment',
        'lessons': [
          {'id': 1, 'course_id': 1, 'title': 'Structure of a C Program', 'order_number': 1, 'has_exam': false},
        ],
      };

      final mockClient = MockClient((request) async {
        if (request.url.path == '/courses/1') {
          return http.Response(jsonEncode(courseDetailJson), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/attempts') {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/courses/1/exam') {
          return http.Response(jsonEncode(sampleExamJson), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = CourseApiService(client: mockClient, baseUrl: 'http://127.0.0.1:8000');

      await tester.pumpWidget(
        MaterialApp(
          theme: KikoTheme.darkTheme,
          home: CourseDetailScreen(
            courseId: 1,
            apiService: service,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag scroll view down so assessment card is in viewport
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify assessment card
      expect(find.text('COURSE FINAL ASSESSMENT'), findsOneWidget);
      expect(find.text('C Programming Comprehensive Final Assessment'), findsOneWidget);
      expect(find.text('20 Questions'), findsOneWidget);
      expect(find.text('Passing: 70% (14/20)'), findsOneWidget);
      expect(find.text('Take Final Assessment'), findsOneWidget);

      // Tap Take Final Assessment
      await tester.tap(find.text('Take Final Assessment'));
      await tester.pumpAndSettle();

      // Navigated into TestScreen
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('Which function is used to print output in C?'), findsOneWidget);
    });
  });
}
