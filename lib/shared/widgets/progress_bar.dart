import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const ProgressBar({super.key, required this.value, this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}