# CLAUDE.md — English App

Flutter cross-platform mobile app (iOS + Android) for English learning.
Connects to the Go backend at `https://bot.mardeen.ir` (shared with the Telegram bot).

## Build / test / run

- `flutter pub get` — install dependencies
- `flutter analyze` — static analysis (must pass with zero issues)
- `flutter test` — run all tests (73 tests across 15 files)
- `flutter run` — run on connected device/emulator
- `dart format .` — format all Dart files
- `dart format --set-exit-if-changed .` — check formatting (CI enforces)

## Project structure

```
lib/
  core/
    api/          — Dio client, auth interceptor, endpoint constants
    auth/         — Riverpod auth state (JWT + Telegram)
    cache/        — Offline cache with shared_preferences
    models/       — 12 data classes (Stats, Deck, Quiz, etc.)
    theme/        — Light/dark themes, semantic color tokens
  features/
    auth/         — Login/register screen, auth gate
    profile/      — Dashboard: streak ring, heatmap, achievements, stat tiles
    library/      — Words, bookmarks, idioms, stories, tips, dictionary
    study/        — Decks, grammar lessons, practice, deck study
    review/       — SRS swipe card engine, review session
    ranks/        — Leaderboard, profile drill-down, kudos
    quiz/         — In-app quiz with HMAC token
    settings/     — Level, toggles, interval, logout
  shared/
    navigation/   — 5-tab bottom nav shell
    widgets/      — Reusable: skeleton, empty, error, progress bar, bookmark star, search, word sheet
test/
  helpers/        — wrapInApp test utility
  widgets/        — 7 widget test files
  models/         — 2 model test files
  features/       — 3 feature screen tests
  core/           — 1 auth provider test
```

## Conventions

- State management: Riverpod (`FutureProvider` for async data, `StateProvider` for UI state)
- Navigation: `Navigator.push` for drill-downs (no go_router at runtime)
- API calls: all go through `ApiClient` (Dio) with JWT/Telegram auth interceptor
- Error handling: `ErrorState` widget for API errors, `EmptyState` for empty data
- Loading states: `LoadingSkeleton` with shimmer animation
- All screens use `ConsumerWidget` or `ConsumerStatefulWidget`
- Models are plain Dart classes with `fromJson` factory constructors (no codegen)
- Tests override providers directly rather than mocking ApiClient
- Haptic feedback on key interactions (quiz answers, settings toggles)

## Key files

- `lib/core/api/api_client.dart` — HTTP client, base URL config, auth interceptor
- `lib/core/api/api_endpoints.dart` — 31 endpoint constants
- `lib/core/auth/auth_provider.dart` — Auth state, login/register/logout
- `lib/features/review/widgets/swipe_card.dart` — Core swipe card engine
- `lib/main.dart` — Entry point, auth gate routing

## Backend

The Go backend lives at `/home/dawood/codes/adventure/english-bot/`.
Mobile app auth endpoints were added in `internal/app/auth.go`:
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/refresh`
- GET `/api/auth/me`

Run backend tests: `cd ../english-bot && go test ./...`
