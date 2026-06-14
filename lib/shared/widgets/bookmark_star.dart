import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';

class BookmarkStar extends ConsumerStatefulWidget {
  final String term;
  final bool initialBookmarked;
  const BookmarkStar({
    super.key,
    required this.term,
    required this.initialBookmarked,
  });

  @override
  ConsumerState<BookmarkStar> createState() => _BookmarkStarState();
}

class _BookmarkStarState extends ConsumerState<BookmarkStar> {
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.initialBookmarked;
  }

  Future<void> _toggle() async {
    final previous = _bookmarked;
    setState(() => _bookmarked = !_bookmarked);
    try {
      final client = ref.read(apiClientProvider);
      await client.post(
        ApiEndpoints.bookmark,
        data: {'term': widget.term, 'on': _bookmarked},
      );
    } catch (e) {
      setState(() => _bookmarked = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _bookmarked ? Icons.star : Icons.star_border,
        color: _bookmarked ? Colors.amber : null,
      ),
      onPressed: _toggle,
      splashRadius: 20,
    );
  }
}
