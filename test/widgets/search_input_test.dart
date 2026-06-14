import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/shared/widgets/search_input.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SearchInput', () {
    testWidgets('renders placeholder text', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          SearchInput(placeholder: 'Search words...', onSearch: (_) {}),
        ),
      );

      expect(find.text('Search words...'), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(wrapInApp(SearchInput(onSearch: (_) {})));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('calls onSearch after debounce', (tester) async {
      final results = <String>[];
      await tester.pumpWidget(
        wrapInApp(
          SearchInput(
            onSearch: results.add,
            debounce: const Duration(milliseconds: 100),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      expect(results, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));
      expect(results, contains('hello'));
    });

    testWidgets('debounce resets on rapid input', (tester) async {
      final results = <String>[];
      await tester.pumpWidget(
        wrapInApp(
          SearchInput(
            onSearch: results.add,
            debounce: const Duration(milliseconds: 200),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'he');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump(const Duration(milliseconds: 300));

      expect(results, ['hello']);
      expect(results.length, 1);
    });

    testWidgets('clear button calls onSearch with empty string', (
      tester,
    ) async {
      final results = <String>[];
      await tester.pumpWidget(wrapInApp(SearchInput(onSearch: results.add)));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    });

    testWidgets('does not call onSearch before debounce fires', (tester) async {
      final results = <String>[];
      await tester.pumpWidget(
        wrapInApp(
          SearchInput(
            onSearch: results.add,
            debounce: const Duration(milliseconds: 500),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 100));
      expect(results, isEmpty);
    });

    testWidgets('has OutlineInputBorder', (tester) async {
      await tester.pumpWidget(wrapInApp(SearchInput(onSearch: (_) {})));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.border, isA<OutlineInputBorder>());
    });

    testWidgets('default placeholder is Search...', (tester) async {
      await tester.pumpWidget(wrapInApp(SearchInput(onSearch: (_) {})));

      expect(find.text('Search...'), findsOneWidget);
    });
  });
}
