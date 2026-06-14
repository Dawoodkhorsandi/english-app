import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/shared/widgets/bottom_sheet_word.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WordBottomSheet', () {
    testWidgets('renders term', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const WordBottomSheet(term: 'ubiquitous')),
      );

      expect(find.text('ubiquitous'), findsOneWidget);
    });

    testWidgets('renders pronunciation when provided', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const WordBottomSheet(term: 'hello', pronunciation: '/hɛˈloʊ/'),
        ),
      );

      expect(find.text('/hɛˈloʊ/'), findsOneWidget);
    });

    testWidgets('renders persian when provided', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const WordBottomSheet(term: 'hello', persian: 'سلام')),
      );

      expect(find.text('سلام'), findsOneWidget);
    });

    testWidgets('renders meaning when provided', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const WordBottomSheet(term: 'hello', meaning: 'A greeting')),
      );

      expect(find.text('A greeting'), findsOneWidget);
    });

    testWidgets('renders example when provided', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const WordBottomSheet(term: 'hello', example: 'Hello, how are you?'),
        ),
      );

      expect(find.text('Hello, how are you?'), findsOneWidget);
    });

    testWidgets('renders dictionary button when onOpenDictionary provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapInApp(
          const WordBottomSheet(term: 'test', onOpenDictionary: SizedBox.new),
        ),
      );

      expect(find.text('Open in Dictionary'), findsOneWidget);
    });

    testWidgets(
      'does not render dictionary button when onOpenDictionary is null',
      (tester) async {
        await tester.pumpWidget(wrapInApp(const WordBottomSheet(term: 'test')));

        expect(find.text('Open in Dictionary'), findsNothing);
      },
    );

    testWidgets('does not render optional fields when null', (tester) async {
      await tester.pumpWidget(wrapInApp(const WordBottomSheet(term: 'hello')));

      expect(find.text('/hɛˈloʊ/'), findsNothing);
      expect(find.text('سلام'), findsNothing);
      expect(find.text('A greeting'), findsNothing);
    });
  });
}
