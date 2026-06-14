import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/core/models/deck.dart';

void main() {
  group('DeckProgress', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'deck-1',
        'name': 'GRE Vocabulary',
        'description': 'Advanced words',
        'total': 500,
        'mastered': 120,
        'due': 35,
        'progressPct': 24,
      };

      final deck = DeckProgress.fromJson(json);

      expect(deck.id, 'deck-1');
      expect(deck.name, 'GRE Vocabulary');
      expect(deck.description, 'Advanced words');
      expect(deck.total, 500);
      expect(deck.mastered, 120);
      expect(deck.due, 35);
      expect(deck.progressPct, 24);
    });

    test('handles missing fields with defaults', () {
      final deck = DeckProgress.fromJson({});

      expect(deck.id, '');
      expect(deck.name, '');
      expect(deck.description, '');
      expect(deck.total, 0);
      expect(deck.mastered, 0);
      expect(deck.due, 0);
      expect(deck.progressPct, 0);
    });
  });

  group('DeckStudyCard', () {
    test('parses from JSON correctly', () {
      final json = {
        'term': 'ephemeral',
        'definition': 'Short-lived',
        'example': 'The ephemeral beauty of cherry blossoms',
        'persian': 'زودگذر',
        'pronunciation': '/ɪˈfɛmərəl/',
        'mnemonic': 'e-phem-er-al → e-phone-mer-all (calls are short)',
        'box': 3,
      };

      final card = DeckStudyCard.fromJson(json);

      expect(card.term, 'ephemeral');
      expect(card.definition, 'Short-lived');
      expect(card.example, 'The ephemeral beauty of cherry blossoms');
      expect(card.persian, 'زودگذر');
      expect(card.pronunciation, '/ɪˈfɛmərəl/');
      expect(card.box, 3);
    });

    test('handles missing fields with defaults', () {
      final card = DeckStudyCard.fromJson({});

      expect(card.term, '');
      expect(card.definition, '');
      expect(card.persian, '');
      expect(card.box, 1);
    });
  });

  group('DeckDetail', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'd1',
        'name': 'Test Deck',
        'description': 'Testing',
        'total': 100,
        'mastered': 40,
        'due': 10,
        'new': 20,
        'progressPct': 40,
        'nextReview': '2026-06-15',
        'boxes': [
          {'box': 1, 'label': 'New', 'count': 20},
          {'box': 2, 'label': 'Learning', 'count': 30},
        ],
      };

      final detail = DeckDetail.fromJson(json);

      expect(detail.id, 'd1');
      expect(detail.newCount, 20);
      expect(detail.boxes.length, 2);
      expect(detail.boxes[0].label, 'New');
      expect(detail.boxes[1].count, 30);
    });
  });

  group('BoxDistribution', () {
    test('parses from JSON correctly', () {
      final box = BoxDistribution.fromJson({
        'box': 3,
        'label': 'Review',
        'count': 15,
      });

      expect(box.box, 3);
      expect(box.label, 'Review');
      expect(box.count, 15);
    });

    test('handles missing fields with defaults', () {
      final box = BoxDistribution.fromJson({});

      expect(box.box, 0);
      expect(box.label, '');
      expect(box.count, 0);
    });
  });
}
