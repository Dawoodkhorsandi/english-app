import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_app/core/models/deck.dart';
import 'package:english_app/features/study/providers.dart';
import 'package:english_app/features/study/study_screen.dart';
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

Widget wrapInStudyApp({List<DeckProgress>? decks}) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(ApiClient()),
    decksProvider.overrideWith((ref) => Future.value(decks ?? testDecks())),
  ],
  child: const MaterialApp(home: Scaffold(body: StudyScreen())),
);

void main() {
  group('StudyScreen', () {
    testWidgets('shows section headers', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows content type cards', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      expect(find.text('Idioms'), findsOneWidget);
      expect(find.text('Collocations'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
    });

    testWidgets('shows grammar card', (tester) async {
      await tester.pumpWidget(wrapInStudyApp());
      await tester.pumpAndSettle();
      expect(find.text('Grammar Lessons'), findsOneWidget);
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
