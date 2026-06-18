import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';

/// Thin wrapper over google_sign_in (v7) that yields a Google ID token for the
/// backend to verify. Sign-in is disabled until [googleServerClientId] is set.
class GoogleSignInService {
  GoogleSignInService._();

  /// Whether the OAuth client id has been configured (see constants.dart).
  static bool get isConfigured => googleServerClientId.isNotEmpty;

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: googleServerClientId.isEmpty
          ? null
          : googleServerClientId,
      clientId: googleIosClientId.isEmpty ? null : googleIosClientId,
    );
    _initialized = true;
  }

  /// Triggers the interactive Google sign-in and returns the ID token, or null
  /// if the user cancels. Throws [GoogleSignInException] for other failures.
  static Future<String?> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
