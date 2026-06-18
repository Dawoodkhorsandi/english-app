import 'dart:math';
import 'package:flutter/material.dart';

/// A circular progress ring with an optional centered [child].
///
/// Generalized from the streak ring so it can back the daily-goal ring,
/// per-deck progress rings, and review-completion ring.
class ProgressRing extends StatelessWidget {
  /// Progress in the 0..1 range (clamped).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 6,
    this.color,
    this.trackColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color ?? colorScheme.primary,
          trackColor: trackColor ?? colorScheme.surfaceContainerHighest,
          strokeWidth: strokeWidth,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

/// Paints the track circle and the progress arc. Public so [ProgressRing]
/// and animated wrappers (e.g. StreakRing) can share it.
class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
