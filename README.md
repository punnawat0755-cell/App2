# How Are You

Flutter application with Supabase, Firebase, and Cloud Functions.

## Local setup

1. Install Flutter and run `flutter pub get`
2. Copy [dart_defines.example.json](/c:/Users/Punnawat.k/Downloads/App2/dart_defines.example.json) to `dart_defines.local.json`
3. Fill in the real values for your environment
4. Run the app with compile-time defines:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

You can also pass values individually:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://your-project.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Required app config

The app expects these compile-time values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Optional values:

- `N8N_MODERATION_WEBHOOK`
- `N8N_MODERATION_TOKEN`
- `N8N_MODERATION_FAIL_OPEN`
- `N8N_ALLOW_BAD_CERT`
- `N8N_ALLOW_BAD_CERT_HOSTS`

## Android release signing

Release builds now require `android/key.properties`.

1. Copy [android/key.properties.example](/c:/Users/Punnawat.k/Downloads/App2/android/key.properties.example) to `android/key.properties`
2. Update it with the real keystore path and passwords
3. Keep the keystore file outside version control

Example release build:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.local.json
```

If `android/key.properties` is missing, release tasks fail fast by design.

## Quality checks

Run before merging or releasing:

```bash
flutter analyze
flutter test
```
