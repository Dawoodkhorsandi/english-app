# English Muscle Memory

A cross-platform mobile app (iOS + Android) for building English vocabulary and grammar mastery through spaced repetition, curated word decks, and interactive quizzes. Built with Flutter and powered by a Go backend.

## Screenshots

<!-- Add screenshots here -->
<!-- ![Dashboard](screenshots/dashboard.png) -->
<!-- ![Library](screenshots/library.png) -->
<!-- ![Review](screenshots/review.png) -->

## Tech Stack

- **Framework**: Flutter 3.x (Dart SDK ^3.12.2)
- **State Management**: Riverpod
- **Networking**: Dio
- **Navigation**: GoRouter
- **Storage**: flutter_secure_storage, shared_preferences
- **Charts**: fl_chart
- **UI Utilities**: shimmer
- **Backend**: Go (hosted at `https://bot.mardeen.ir`)
- **Authentication**: JWT (email/password) + Telegram Mini App init data

## Project Structure

```
lib/
  core/
    api/
      api_client.dart          # Dio HTTP client with JWT interceptors
      api_endpoints.dart       # All 31 API endpoint constants
    auth/
      auth_provider.dart       # Auth state, login/register/logout logic
    theme/
      app_theme.dart           # Light/dark theme definitions
      app_colors.dart          # Color palette
    models/
      stats.dart               # User stats & activity data model
      achievement.dart         # Achievement data model
  features/
    auth/
      login_screen.dart        # Email/password + Telegram auth
    profile/
      profile_screen.dart      # Dashboard with streak, heatmap, achievements
    library/
      library_screen.dart      # Words, idioms, collocations, stories, tips
    study/
      study_screen.dart        # Curated decks, grammar lessons
    review/
      review_screen.dart       # SRS swipe card review engine
    ranks/
      ranks_screen.dart        # Leaderboard with head-to-head comparison
  shared/
    navigation/
      app_router.dart          # Bottom nav shell (5 tabs)
```

## Prerequisites

- Flutter SDK 3.12.2 or later
- Dart SDK 3.12.2 or later
- An iOS simulator or physical device (Xcode)
- An Android emulator or physical device (Android Studio)
- Access to the backend at `https://bot.mardeen.ir` (or a local instance)

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd english-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the backend URL if not using the default (`https://bot.mardeen.ir`). Update the base URL in `lib/core/api/api_client.dart`.

4. Run the app:
   ```bash
   flutter run
   ```

## Building for Release

**Android:**
```bash
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

The APK/AAB will be at `build/app/outputs/`. The iOS build requires Xcode and signing configuration.

## Testing

```bash
flutter test
```

Run all widget and unit tests in the `test/` directory.

## Architecture

The app follows a feature-based structure:

- **core/**: Shared infrastructure (API client, auth, theme, data models). No UI lives here.
- **features/**: Each feature is a self-contained module with its own screens and providers.
- **shared/**: Cross-feature UI components like the navigation shell.

State is managed entirely through Riverpod providers. The `ApiClient` (Dio) handles JWT injection, token refresh, and Telegram auth headers via interceptors. Secure storage persists tokens across sessions.

Authentication flow: the app checks for a stored JWT on launch, validates it via `/api/auth/me`, and routes to either the login screen or the main shell accordingly.

## API Endpoints

The app communicates with the Go backend via these endpoints:

| Endpoint | Method | Description |
|---|---|---|
| `/api/auth/register` | POST | Create new account (email/password) |
| `/api/auth/login` | POST | Email/password login |
| `/api/auth/refresh` | POST | Refresh JWT token |
| `/api/auth/me` | GET | Get current user profile |
| `/api/config` | GET | App configuration |
| `/api/stats` | GET | User stats (streak, words, achievements) |
| `/api/analytics` | GET | Activity heatmap data |
| `/api/vocab` | GET | Vocabulary library |
| `/api/vocab/card` | GET | Single vocabulary card |
| `/api/bookmark` | POST | Toggle bookmark on a word |
| `/api/leaderboard` | GET | Global leaderboard |
| `/api/leaderboard/name` | GET | Leaderboard by user name |
| `/api/profile` | GET | User profile details |
| `/api/kudos` | POST | Send kudos to a user |
| `/api/review/next` | GET | Next SRS review card |
| `/api/review/answer` | POST | Submit review answer |
| `/api/review/summary` | GET | Review session summary |
| `/api/decks` | GET | List available word decks |
| `/api/decks/study` | GET | Study deck content |
| `/api/decks/detail` | GET | Deck details |
| `/api/decks/swipe` | POST | Submit swipe action on deck card |
| `/api/settings` | GET/PUT | User settings and content toggles |
| `/api/content` | GET | Library content (idioms, collocations, stories, tips) |
| `/api/quizzes` | GET | List available quizzes |
| `/api/quiz/next` | GET | Next quiz question |
| `/api/quiz/answer` | POST | Submit quiz answer |
| `/api/practice` | GET | Practice exercises |
| `/api/grammar` | GET | Grammar lesson list |
| `/api/grammar/lesson` | GET | Single grammar lesson |
| `/api/dictionary` | GET | Dictionary lookup |

## Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Make your changes following the existing code style and conventions.
4. Add or update tests if applicable.
5. Run `flutter analyze` and `flutter test` to verify.
6. Commit your changes and open a pull request.

## License

This project is proprietary. All rights reserved.
