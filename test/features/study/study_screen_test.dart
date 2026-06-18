import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_app/core/models/deck.dart';
import 'package:english_app/core/models/stats.dart';
import 'package:english_app/core/models/grammar_lesson.dart';
import 'package:english_app/features/study/providers.dart';
import 'package:english_app/features/study/study_screen.dart';
import 'package:english_app/features/profile/providers.dart';
import 'package:english_app/core/auth/auth_provider.dart';
import 'package:english_app/core/api/api_client.dart';

List<DeckProgress> testDecks() => [
  DeckProgress(
    id: '504-essential',
    name: '504 Essential Words',
    description: 'Core vocabulary',
    total: 504,
    mastered: 100,
    due: 50,
    progressPct: 20,
  ),
  DeckProgress(
    id: 'gre-333',
    name: "Barron's GRE 333",
    description: 'GRE words',
    total: 333,
    mastered: 50,
    due: 30,
    progressPct: 15,
  ),
];

List<GrammarLesson> testLessons() => [
  GrammarLesson(
    id: 'present-simple',
    order: 1,
    level: 'beginner',
    title: 'Present Simple',
    pattern: 'Subject + V1 / V1+s',
  ),
];

Widget wrapInStudyApp({List<DeckProgress>? decks}) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(ApiClient()),
    decksProvider.overrideWith((ref) => Future.value(decks ?? testDecks())),
    grammarLessonsProvider.overrideWith((ref) => Future.value(testLessons())),
    statsProvider.overrideWith(
      (ref) => Future.value(
        Stats.fromJson({
          'idioms': 8,
          'collocations': 6,
          'stories': 4,
          'tips': 5,
        }),
      ),
    ),
  ],
  child: const MaterialApp(home: Scaffold(body: StudyScreen())),
);

void main() {
  group('StudyScreen', () {
    testWidgets('shows segmented tabs', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows content type cards on Content tab', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Content'));
      await tester.pumpAndSettle();
      expect(find.text('Idioms'), findsOneWidget);
      expect(find.text('Collocations'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
    });

    testWidgets('shows grammar lessons on Grammar tab', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();
      expect(find.text('Present Simple'), findsOneWidget);
    });

    testWidgets('shows deck list', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      expect(find.text('504 Essential Words'), findsOneWidget);
      expect(find.text("Barron's GRE 333"), findsOneWidget);
    });

    testWidgets('shows empty state when no decks', (tester) async {
      await tester.pumpWidget(wrapInStudyApp(decks: []));
      await tester.pumpAndSettle();
      expect(find.text('No decks yet'), findsOneWidget);
    });
  });
}
