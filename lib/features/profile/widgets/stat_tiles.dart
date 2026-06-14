import 'package:flutter/material.dart';
import '../../../core/models/stats.dart';

class StatTiles extends StatelessWidget {
  final Stats stats;
  const StatTiles({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('\u{1F4DA}', '${stats.words}', 'Words'),
      ('\u2705', '${stats.mastered}', 'Mastered'),
      ('\u{1F4AC}', '${stats.verbs}', 'Drills'),
      ('\u{1F9E9}', '${stats.quizAnswered}', 'Quiz'),
      ('\u{1F4AC}', '${stats.idioms}', 'Idioms'),
      ('\u{1F517}', '${stats.collocations}', 'Collocations'),
      ('\u{1F4D6}', '${stats.stories}', 'Stories'),
      ('\u{1F4A1}', '${stats.tips}', 'Tips'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final (emoji, count, label) = tiles[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
