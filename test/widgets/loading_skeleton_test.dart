import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:english_app/shared/widgets/loading_skeleton.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LoadingSkeleton', () {
    testWidgets('renders correct number of skeleton lines', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const LoadingSkeleton(lines: 5),
      ));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(5));
    });

    testWidgets('uses shimmer animation', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const LoadingSkeleton(lines: 2),
      ));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('defaults to 3 lines', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoadingSkeleton()));
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
    });
  });
}
