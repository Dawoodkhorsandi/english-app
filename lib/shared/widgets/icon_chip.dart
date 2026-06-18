import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';

/// A rounded-square colored icon badge: a [color] icon on a soft [background].
///
/// Used for quick-action tiles, content categories, and metric chips.
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double iconSize;

  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.borderMd,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
