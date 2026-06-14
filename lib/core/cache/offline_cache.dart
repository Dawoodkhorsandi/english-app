import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  static const _prefix = 'cache_';
  static const _duration = Duration(hours: 1);

  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {'data': data, 'timestamp': DateTime.now().millisecondsSinceEpoch};
    await prefs.setString('$_prefix$key', jsonEncode(entry));
  }

  static Future<T?> get<T>(String key, {Duration? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final age = DateTime.now().millisecondsSinceEpoch - (entry['timestamp'] as int);
      if (age > (maxAge ?? _duration).inMilliseconds) return null;
      return entry['data'] as T;
    } catch (e) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
