import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders the small subset of Telegram-flavoured HTML the bot emits — `<b>`,
/// `<i>`, `<u>`, `<code>`, `<tg-spoiler>` and `<br>` plus HTML entities — as a
/// rich [Text]. Spoilers start covered and reveal on tap, matching Telegram.
///
/// This is intentionally a hand-rolled parser (not a full HTML package): the tag
/// set is tiny and we need theme-matched, tappable spoilers.
class TelegramHtml extends StatefulWidget {
  final String html;
  final TextStyle? style;
  final TextAlign textAlign;

  const TelegramHtml(
    this.html, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TelegramHtml> createState() => _TelegramHtmlState();
}

class _Run {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool code;
  final bool spoiler;
  final int spoilerId;

  _Run(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.code = false,
    this.spoiler = false,
    this.spoilerId = -1,
  });
}

class _TelegramHtmlState extends State<TelegramHtml> {
  final Set<int> _revealed = {};
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers are rebuilt every build; dispose the previous batch first.
    _disposeRecognizers();

    final base = (widget.style ?? DefaultTextStyle.of(context).style);
    final spoilerCover = (base.color ?? Theme.of(context).colorScheme.onSurface)
        .withValues(alpha: 0.22);

    final runs = _parse(widget.html);
    final spans = <InlineSpan>[];
    for (final run in runs) {
      var style = base;
      if (run.bold) style = style.copyWith(fontWeight: FontWeight.w700);
      if (run.italic) style = style.copyWith(fontStyle: FontStyle.italic);
      if (run.underline) {
        style = style.copyWith(decoration: TextDecoration.underline);
      }
      if (run.code) {
        style = style.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          backgroundColor: spoilerCover.withValues(alpha: 0.12),
        );
      }

      final hidden = run.spoiler && !_revealed.contains(run.spoilerId);
      if (hidden) {
        final rec = TapGestureRecognizer()
          ..onTap = () => setState(() => _revealed.add(run.spoilerId));
        _recognizers.add(rec);
        spans.add(
          TextSpan(
            text: run.text,
            style: style.copyWith(
              color: Colors.transparent,
              backgroundColor: spoilerCover,
            ),
            recognizer: rec,
          ),
        );
      } else {
        spans.add(TextSpan(text: run.text, style: style));
      }
    }

    return Text.rich(
      TextSpan(children: spans, style: base),
      textAlign: widget.textAlign,
    );
  }

  List<_Run> _parse(String input) {
    final runs = <_Run>[];
    var bold = false,
        italic = false,
        underline = false,
        code = false,
        spoiler = false;
    var spoilerCounter = 0;
    var currentSpoilerId = -1;
    final buf = StringBuffer();

    void flush() {
      if (buf.isEmpty) return;
      runs.add(
        _Run(
          _decodeEntities(buf.toString()),
          bold: bold,
          italic: italic,
          underline: underline,
          code: code,
          spoiler: spoiler,
          spoilerId: currentSpoilerId,
        ),
      );
      buf.clear();
    }

    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (ch == '<') {
        final end = input.indexOf('>', i);
        if (end == -1) {
          buf.write(ch);
          i++;
          continue;
        }
        final tag = input.substring(i + 1, end).trim().toLowerCase();
        // Normalise attributes: `span class="tg-spoiler"` → treat as spoiler.
        final isSpoilerSpan =
            tag.startsWith('span') && tag.contains('tg-spoiler');
        // Strip attributes for the rest (e.g. `a href=...`).
        final spaceIdx = tag.indexOf(' ');
        final name = spaceIdx == -1 ? tag : tag.substring(0, spaceIdx);

        flush();
        switch (name) {
          case 'b':
          case 'strong':
            bold = true;
          case '/b':
          case '/strong':
            bold = false;
          case 'i':
          case 'em':
            italic = true;
          case '/i':
          case '/em':
            italic = false;
          case 'u':
            underline = true;
          case '/u':
            underline = false;
          case 'code':
          case 'pre':
            code = true;
          case '/code':
          case '/pre':
            code = false;
          case 'tg-spoiler':
            spoiler = true;
            currentSpoilerId = spoilerCounter++;
          case '/tg-spoiler':
          case '/span':
            spoiler = false;
            currentSpoilerId = -1;
          case 'br':
          case 'br/':
            buf.write('\n');
          default:
            if (isSpoilerSpan) {
              spoiler = true;
              currentSpoilerId = spoilerCounter++;
            }
        }
        i = end + 1;
        continue;
      }
      buf.write(ch);
      i++;
    }
    flush();
    return runs;
  }

  String _decodeEntities(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }
}
