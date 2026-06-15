import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/features/review/widgets/swipe_card.dart';

Widget wrapInApp(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SwipeSession', () {
    testWidgets('renders empty state when no cards', (tester) async {
      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: const [], onAnswer: (_, _) async {})),
      );
      await tester.pump();
      expect(find.text('No cards to review.'), findsOneWidget);
    });

    testWidgets('renders card front text', (tester) async {
      final cards = [
        SwipeCard(front: 'Ubiquitous', back: 'Everywhere', term: 'ubiquitous'),
      ];
      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: cards, onAnswer: (_, _) async {})),
      );
      await tester.pump();
      expect(find.text('Ubiquitous'), findsOneWidget);
      expect(find.text('Tap to flip'), findsOneWidget);
    });

    testWidgets('shows remaining count', (tester) async {
      final cards = [
        SwipeCard(front: 'A', back: 'A-back', term: 'a'),
        SwipeCard(front: 'B', back: 'B-back', term: 'b'),
      ];
      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: cards, onAnswer: (_, _) async {})),
      );
      await tester.pump();
      expect(find.text('2 remaining'), findsOneWidget);
    });

    testWidgets('tap flips card to show back', (tester) async {
      final cards = [
        SwipeCard(front: 'Ubiquitous', back: 'Everywhere', term: 'ubiquitous'),
      ];
      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: cards, onAnswer: (_, _) async {})),
      );
      await tester.pump();
      expect(find.text('Ubiquitous'), findsOneWidget);

      await tester.tap(find.byType(AnimatedContainer));
      await tester.pump();
      expect(find.text('Everywhere'), findsOneWidget);
      expect(find.text('Tap to see front'), findsOneWidget);
    });

    testWidgets('Knew it button commits known', (tester) async {
      SwipeCard? answeredCard;
      bool? answeredKnown;

      final cards = [SwipeCard(front: 'Hello', back: 'World', term: 'hello')];

      await tester.pumpWidget(
        wrapInApp(
          SwipeSession(
            cards: cards,
            onAnswer: (card, known) async {
              answeredCard = card;
              answeredKnown = known;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(answeredKnown, isTrue);
      expect(answeredCard?.front, 'Hello');
    });

    testWidgets('Forgot button commits forgot', (tester) async {
      bool? answeredKnown;

      final cards = [SwipeCard(front: 'Test', back: 'Answer', term: 'test')];

      await tester.pumpWidget(
        wrapInApp(
          SwipeSession(
            cards: cards,
            onAnswer: (_, known) async {
              answeredKnown = known;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Forgot'));
      await tester.pumpAndSettle();

      expect(answeredKnown, isFalse);
    });

    testWidgets('completion screen shows when all cards answered', (
      tester,
    ) async {
      final cards = [SwipeCard(front: 'A', back: 'A-back', term: 'a')];

      await tester.pumpWidget(
        wrapInApp(
          SwipeSession(
            cards: cards,
            onAnswer: (_, _) async {},
            doneText: 'All done!',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shows known/forgot counts on completion', (tester) async {
      final cards = [
        SwipeCard(front: 'A', back: 'A-back', term: 'a'),
        SwipeCard(front: 'B', back: 'B-back', term: 'b'),
      ];

      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: cards, onAnswer: (_, _) async {})),
      );
      await tester.pump();

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot'));
      await tester.pumpAndSettle();

      expect(find.text('1 known / 1 forgot'), findsOneWidget);
    });

    testWidgets('renders custom emptyText', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          SwipeSession(
            cards: const [],
            onAnswer: (_, _) async {},
            emptyText: 'Nothing to study',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Nothing to study'), findsOneWidget);
    });

    testWidgets('renders custom doneText', (tester) async {
      final cards = [SwipeCard(front: 'X', back: 'Y', term: 'x')];

      await tester.pumpWidget(
        wrapInApp(
          SwipeSession(
            cards: cards,
            onAnswer: (_, _) async {},
            doneText: 'Finished!',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(find.text('Finished!'), findsOneWidget);
    });

    testWidgets('shows remaining count after answering', (tester) async {
      final cards = [
        SwipeCard(front: 'A', back: 'A-back', term: 'a'),
        SwipeCard(front: 'B', back: 'B-back', term: 'b'),
      ];

      await tester.pumpWidget(
        wrapInApp(SwipeSession(cards: cards, onAnswer: (_, _) async {})),
      );
      await tester.pump();

      expect(find.text('2 remaining'), findsOneWidget);

      await tester.tap(find.text('Knew it'));
      await tester.pumpAndSettle();

      expect(find.text('1 remaining'), findsOneWidget);
    });
  });
}
