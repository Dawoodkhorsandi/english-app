import 'dart:async';
import 'package:flutter/material.dart';

class SearchInput extends StatefulWidget {
  final String placeholder;
  final ValueChanged<String> onSearch;
  final Duration debounce;
  const SearchInput({
    super.key,
    this.placeholder = 'Search...',
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 250),
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
      ),
      onChanged: (v) {
        _timer?.cancel();
        _timer = Timer(widget.debounce, () => widget.onSearch(v));
      },
    );
  }
}
