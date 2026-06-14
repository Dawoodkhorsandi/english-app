import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/shared/widgets/progress_bar.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ProgressBar', () {
    testWidgets('renders at correct width percentage', (tester) async {
      await tester.pumpWidget(wrapInApp(const ProgressBar(value: 0.5)));

      final fractionally = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionally.widthFactor, 0.5);
    });

    testWidgets('clamps value between 0 and 1 (over 1)', (tester) async {
      await tester.pumpWidget(wrapInApp(const ProgressBar(value: 1.5)));

      final fractionally = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionally.widthFactor, 1.0);
    });

    testWidgets('clamps value between 0 and 1 (negative)', (tester) async {
      await tester.pumpWidget(wrapInApp(const ProgressBar(value: -0.3)));

      final fractionally = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionally.widthFactor, 0.0);
    });

    testWidgets('renders at 100%', (tester) async {
      await tester.pumpWidget(wrapInApp(const ProgressBar(value: 1.0)));

      final fractionally = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionally.widthFactor, 1.0);
    });

    testWidgets('renders at 0%', (tester) async {
      await tester.pumpWidget(wrapInApp(const ProgressBar(value: 0.0)));

      final fractionally = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionally.widthFactor, 0.0);
    });
  });
}
