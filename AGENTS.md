# AGENTS.md

## Project Overview

This is a Flutter Mobile/Web Application with Supabase backend. The project supports Android, iOS, Web, macOS, Windows, and Linux platforms. Dart SDK: ^3.10.7.

## Build/Lint/Test Commands

### Flutter Commands (run from project root)

- `flutter pub get` - Fetch dependencies | `flutter pub upgrade` - Upgrade to latest
- `flutter analyze` - Run Dart static analyzer | `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run single test file
- `flutter test --plain-name "pattern"` - Run tests matching pattern
- `flutter run` - Run on device/emulator | `flutter run -d chrome` - Run on Chrome

### Build Commands

- Android: `flutter build apk --debug` or `--release`
- iOS: `flutter build ios --debug` or `--release`
- Other: `flutter build web | macos | windows | linux`

## Git Workflow Conventions

### Branch Naming
- Feature: `feature/<ticket-id>-description` (e.g., `feature/123-user-auth`)
- Bugfix: `bugfix/<ticket-id>-description` | Hotfix: `hotfix/<ticket-id>-fix`
- Release: `release/v1.0.0`

### Commit Message Format
```
<type>(<scope>): <subject>
```
**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples:** `feat(auth): add biometric login` | `fix(profile): resolve avatar upload on iOS`

## Code Style Guidelines

### File Naming & Imports
- Files: snake_case (`login_page.dart`). One class per file.
- Imports: relative for local (`../supabase_client.dart`), package for deps (`package:flutter/material.dart`)
- Group order: dart core → flutter → packages → local (blank lines between groups)

### Formatting & Types
- Use `dart format .` | 2-space indent | 80-100 char line length
- Use `const` constructors and trailing commas
- `final` for single-assignment, `late final` for lazy init, `var` only when type obvious
- Primitives lowercase (`int`), classes PascalCase

### Naming Conventions
- Classes: PascalCase | Vars/functions: camelCase | Private: `_prefix`
- Constants: camelCase or SCREAMING_SNAKE_CASE | Booleans: `is`/`has`/`can` prefix

### Widgets
```dart
class NamePage extends StatefulWidget {
  const NamePage({super.key});
  @override
  State<NamePage> createState() => _NamePageState();
}
class _NamePageState extends State<NamePage> {
  @override
  Widget build(BuildContext context) => const Placeholder();
}
```

### Async & Error Handling
- **Always** check `mounted` before `context` in async callbacks: `if (!mounted) return;`
- Wrap async ops in try-catch | Use specific exceptions (e.g., `AuthException`)
- Show errors via SnackBar | Use `_isLoading` state to prevent double-submission

### Error Handling Pattern
```dart
Future<void> _submit() async {
  if (_isLoading) return;
  setState(() => _isLoading = true);
  try {
    await authService.signIn(_email, _password);
    if (mounted) Get.offAll(() => const HomePage());
  } on AuthException catch (e) {
    if (mounted) Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
  } catch (e) {
    if (mounted) Get.snackbar('Error', 'An unexpected error occurred', snackPosition: SnackPosition.BOTTOM);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### State Management (Get Package)
- `Get.put()` - singleton services | `Get.lazyPut()` - lazy initialization
- `Get.find()<Service>()` - retrieve services | `Obx()` - reactive UI with `.obs`
- Controllers extend `GetxController` with `onInit()`/`onClose()`

### Colors & Theming
- Hex colors: `Color(0xFF...)` | Opacity: `withValues(alpha: 0.xx)`
- Material 3: `ThemeData(useMaterial3: true)` | Extract color constants

### Linting
- Uses `flutter_lints` (default set) | Run `flutter analyze`
- Suppress: `// ignore: lint_name` | Config: `analysis_options.yaml`

## Asset Management

### Declaring Assets (pubspec.yaml)
```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/profile_avatars/
    - assets/videos/
    - assets/fonts/
```

### Using Assets
```dart
Image.asset('assets/images/logo.png')
// Or via constants:
class AppAssets {
  static const logo = 'assets/images/logo.png';
  static const defaultAvatar = 'assets/images/profile_avatars/default_avatar.png';
}
```

## Test Conventions
- Files: `test/<feature>_test.dart` | Use `WidgetTester` for widget tests
- `testWidgets()` for UI tests, `test()` for unit tests
- Use `expect()` from `flutter_test` | Clean up in `tearDown()`

## Key Dependencies
- `flutter` | `supabase_flutter: ^2.12.0` | `firebase_core`, `firebase_auth`, `firebase_messaging`
- `get:` - state management | `path_provider` | `image_picker` | `video_player`
- `postgres: ^3.5.9` | `cupertino_icons: ^1.0.8`

## Architecture Notes

### Folder Structure
```
lib/
├── main.dart              # Entry point
├── app/                   # App config & routes
├── core/                  # Constants, theme, utils
├── data/                  # Models, repositories impl, datasources
├── domain/                # Entities, repository interfaces, usecases
├── presentation/          # Pages, widgets, controllers, bindings
└── services/              # Auth, storage, etc.
```

### Service Configuration
- Supabase singleton: `final supabase = Supabase.instance.client;`
- Auth state: `supabase.auth.onAuthStateChange` stream
- Firebase Messaging configured for push notifications
- GetX bindings initialize controllers on page routes
