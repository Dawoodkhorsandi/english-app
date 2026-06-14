import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_app/core/auth/auth_provider.dart';
import 'package:english_app/core/api/api_client.dart';

Widget wrapInApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(ApiClient()),
      ...overrides,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
