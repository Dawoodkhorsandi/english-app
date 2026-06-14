import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/shared/widgets/empty_state.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const EmptyState(icon: Icons.inbox, title: 'Nothing here')),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const EmptyState(
            icon: Icons.inbox,
            title: 'No items',
            subtitle: 'Add something to get started',
          ),
        ),
      );

      expect(find.text('Add something to get started'), findsOneWidget);
    });

    testWidgets('does not render subtitle when empty string', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const EmptyState(icon: Icons.inbox, title: 'Empty')),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
