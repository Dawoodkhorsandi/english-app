import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_app/core/models/quiz.dart';
import 'package:english_app/features/quiz/providers.dart';
import 'package:english_app/features/quiz/quiz_screen.dart';
import 'package:english_app/core/auth/auth_provider.dart';
import 'package:english_app/core/api/api_client.dart';
import 'package:english_app/shared/widgets/loading_skeleton.dart';

Widget wrapInQuizApp(QuizQuestion quiz) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(ApiClient()),
    quizProvider.overrideWith((ref) => Future.value(quiz)),
  ],
  child: const MaterialApp(home: Scaffold(body: QuizScreen())),
);

Widget wrapInQuizLoading() => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(ApiClient()),
    quizProvider.overrideWith((ref) => Completer<QuizQuestion>().future),
  ],
  child: const MaterialApp(home: Scaffold(body: QuizScreen())),
);

void main() {
  group('QuizScreen', () {
    testWidgets('shows loading skeleton while fetching', (tester) async {
      await tester.pumpWidget(wrapInQuizLoading());
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
    });

    testWidgets('shows empty state when no quiz available', (tester) async {
      await tester.pumpWidget(wrapInQuizApp(QuizQuestion(available: false)));
      await tester.pumpAndSettle();
      expect(find.text('No quiz available right now.'), findsOneWidget);
    });

    testWidgets('shows question and options when quiz loaded', (tester) async {
      await tester.pumpWidget(
        wrapInQuizApp(
          QuizQuestion(
            available: true,
            prompt: "What does 'test' mean?",
            options: ['A trial', 'A test', 'A word', 'A thing'],
            word: 'test',
            correct: 1,
            exp: 9999999999,
            token: 'abc',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("What does 'test' mean?"), findsOneWidget);
      expect(find.text('A trial'), findsOneWidget);
      expect(find.text('A test'), findsOneWidget);
      expect(find.text('A word'), findsOneWidget);
      expect(find.text('A thing'), findsOneWidget);
    });

    testWidgets('tapping an option selects it', (tester) async {
      await tester.pumpWidget(
        wrapInQuizApp(
          QuizQuestion(
            available: true,
            prompt: 'Question?',
            options: ['Option A', 'Option B'],
            word: 'test',
            correct: 0,
            exp: 9999999999,
            token: 'abc',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final buttonBefore = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttonBefore.onPressed, isNull);

      await tester.tap(find.text('Option B'));
      await tester.pump();

      final buttonAfter = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('submit button disabled when nothing selected', (tester) async {
      await tester.pumpWidget(
        wrapInQuizApp(
          QuizQuestion(
            available: true,
            prompt: 'Question?',
            options: ['A', 'B'],
            word: 'test',
            correct: 0,
            exp: 9999999999,
            token: 'abc',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
