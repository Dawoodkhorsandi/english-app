import 'package:flutter/material.dart';
import '../../../shared/widgets/progress_ring.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = widget.longest > 0
            ? (widget.streak / widget.longest).clamp(0.0, 1.0)
            : 0.0;
        return ProgressRing(
          progress: progress * _animation.value,
          size: 120,
          strokeWidth: 8,
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
        );
      },
    );
  }
}
