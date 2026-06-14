import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final int lines;
  const LoadingSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(lines, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )),
      ),
    );
  }
}