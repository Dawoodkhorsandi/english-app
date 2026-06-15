import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

class StreakRing extends StatefulWidget {
  final int streak;
  final int longest;
  const StreakRing({super.key, required this.streak, required this.longest});

  @override
  State<StreakRing> createState() => _StreakRingState();
}

class _StreakRingState extends State<StreakRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = widget.longest > 0
            ? (widget.streak / widget.longest).clamp(0.0, 1.0)
            : 0.0;
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress * _animation.value,
              color: colorScheme.primary,
              trackColor: colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.streak >= 3)
                    Text('\u{1F525}', style: textTheme.bodyLarge),
                  Text(
                    '${widget.streak}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('days', style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - AppSpacing.sm;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.sm
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
