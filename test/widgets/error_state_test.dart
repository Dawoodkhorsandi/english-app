import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/shared/widgets/error_state.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorState', () {
    testWidgets('renders default message', (tester) async {
      await tester.pumpWidget(wrapInApp(const ErrorState()));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders custom message', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(message: 'Network timeout'),
      ));

      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(onRetry: SizedBox.new),
      ));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('does not render retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(wrapInApp(const ErrorState()));

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('retry button calls onRetry callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapInApp(
        ErrorState(onRetry: () => tapped = true),
      ));

      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });
  });
}
