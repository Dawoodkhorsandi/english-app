import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:english_app/core/models/settings.dart';
import 'package:english_app/features/settings/providers.dart';
import 'package:english_app/features/settings/settings_screen.dart';
import 'package:english_app/core/auth/auth_provider.dart';
import 'package:english_app/core/api/api_client.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient();

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => Response(
    requestOptions: RequestOptions(path: path),
    data: {},
  );

  @override
  Future<Response> post(String path, {dynamic data}) async => Response(
    requestOptions: RequestOptions(path: path),
    data: {},
  );
}

AppSettings testSettings() => AppSettings(
  level: 'intermediate',
  levels: ['beginner', 'intermediate', 'upper-intermediate', 'advanced'],
  levelLabels: {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'upper-intermediate': 'Upper-Intermediate',
    'advanced': 'Advanced',
  },
  name: 'Test User',
  paused: false,
  interval: 60,
  toggles: {
    'tts': true,
    'tips': true,
    'quiz': true,
    'idiom': true,
    'collocation': true,
    'story': true,
    'review': true,
    'daily_review': true,
    'digest': false,
  },
);

Widget wrapInSettingsApp({AppSettings? settings}) => ProviderScope(
  overrides: [
    apiClientProvider.overrideWithValue(_NoOpApiClient()),
    settingsProvider.overrideWith(
      (ref) => Future.value(settings ?? testSettings()),
    ),
  ],
  child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
);

void main() {
  group('SettingsScreen', () {
    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(wrapInSettingsApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Settings'), findsOneWidget);
    });

    testWidgets('shows level chips', (tester) async {
      await tester.pumpWidget(wrapInSettingsApp());
      await tester.pumpAndSettle();
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Upper-Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('shows toggles', (tester) async {
      await tester.pumpWidget(wrapInSettingsApp());
      await tester.pumpAndSettle();
      expect(find.text('Self-paced mode'), findsOneWidget);
      expect(find.text('Pronunciation audio'), findsOneWidget);
      expect(find.text('Daily grammar tips'), findsOneWidget);
      expect(find.text('Quiz reminders'), findsOneWidget);
    });

    testWidgets('shows logout', (tester) async {
      await tester.pumpWidget(wrapInSettingsApp());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('toggle works', (tester) async {
      await tester.pumpWidget(wrapInSettingsApp());
      await tester.pumpAndSettle();

      final ttsToggle = find.byWidgetPredicate(
        (w) =>
            w is SwitchListTile &&
            w.title != null &&
            (w.title as Text?)?.data == 'Pronunciation audio',
      );
      expect(ttsToggle, findsOneWidget);

      final switchWidget = tester.widget<SwitchListTile>(ttsToggle);
      expect(switchWidget.value, true);
    });
  });
}
