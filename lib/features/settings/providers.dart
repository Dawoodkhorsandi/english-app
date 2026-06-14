import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/settings.dart';
import '../../../core/auth/auth_provider.dart';

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.settings);
  return AppSettings.fromJson(response.data);
});
