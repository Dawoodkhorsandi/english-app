# Contributing to English App

## Development Setup

1. Install Flutter SDK 3.12.2+
2. Clone the repository
3. Run `make get` to install dependencies
4. Run `make test` to verify everything works

## Code Style

- Run `make format` before committing
- Run `make analyze` to check for issues
- All checks must pass in CI before merging

## Testing

- Widget tests go in `test/widgets/`
- Model tests go in `test/models/`
- Feature screen tests go in `test/features/<feature>/`
- Provider tests go in `test/core/`
- Use `wrapInApp()` from `test/helpers/test_helpers.dart` for widget tests
- Override providers directly rather than mocking ApiClient

## Architecture

- **core/**: Shared infrastructure only — no UI
- **features/**: Self-contained feature modules
- **shared/**: Cross-feature reusable components
- Use Riverpod for all state management
- Use `ConsumerWidget` / `ConsumerStatefulWidget` for screens

## Pull Requests

1. Create a feature branch from `master`
2. Make your changes
3. Run `make analyze && make test`
4. Ensure `dart format --set-exit-if-changed .` passes
5. Open a PR with a clear description
