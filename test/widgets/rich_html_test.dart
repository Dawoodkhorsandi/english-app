import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/shared/widgets/rich_html.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('renders plain text and decodes entities', (tester) async {
    await tester.pumpWidget(wrapInApp(const RichHtml('Tom &amp; Jerry &lt;3')));
    expect(find.text('Tom & Jerry <3'), findsOneWidget);
  });

  testWidgets('strips tags into a single rich text run', (tester) async {
    await tester.pumpWidget(wrapInApp(const RichHtml('a <b>bold</b> word')));
    // The RichText concatenates all runs; the visible string excludes tags.
    final richText = tester.widget<RichText>(find.byType(RichText).first);
    expect((richText.text as TextSpan).toPlainText(), 'a bold word');
  });

  testWidgets('spoiler is hidden until tapped', (tester) async {
    await tester.pumpWidget(
      wrapInApp(const RichHtml('secret: <tg-spoiler>hidden</tg-spoiler>')),
    );

    // Find the "hidden" run across every RichText in the tree.
    TextSpan spoilerSpan() {
      TextSpan? found;
      for (final el in find.byType(RichText).evaluate()) {
        final span = (el.widget as RichText).text;
        span.visitChildren((s) {
          if (s is TextSpan && s.text == 'hidden') found = s;
          return true;
        });
      }
      expect(found, isNotNull, reason: 'spoiler run "hidden" should exist');
      return found!;
    }

    // Hidden: rendered transparent.
    expect(spoilerSpan().style?.color, Colors.transparent);

    // Tap the recognizer directly (the span is the only tappable region).
    (spoilerSpan().recognizer as TapGestureRecognizer).onTap!();
    await tester.pump();

    // Revealed: no longer transparent.
    expect(spoilerSpan().style?.color, isNot(Colors.transparent));
  });
}
