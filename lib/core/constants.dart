const String baseUrl = 'https://bot.mardeen.ir';
const Duration requestTimeout = Duration(seconds: 30);
const int defaultPageSize = 20;
const int maxPageSize = 100;
const String botTelegramUsername = '@mymusclememorybot';

// ---------------------------------------------------------------------------
// Google Sign-In — fill these once the OAuth clients exist in Google Cloud
// Console (APIs & Services → Credentials). Leave empty to keep Google sign-in
// disabled (the button shows a "not configured" notice).
//
//  - googleServerClientId: the **Web application** client id. It doubles as the
//    ID-token audience the backend verifies, so it MUST equal GOOGLE_CLIENT_ID
//    set in the bot's ENV_FILE.
//  - googleIosClientId: the **iOS** client id (needed on iOS only; also add its
//    reversed form as a URL scheme in ios/Runner/Info.plist).
//  - Android needs an OAuth client registered with the app's SHA-1 fingerprint
//    (no value goes here — Google matches it by package name + SHA-1).
// ---------------------------------------------------------------------------
const String googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '498467144653-kuhj65utks079cja31k94ve7grrskk0i.apps.googleusercontent.com',
);
const String googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
