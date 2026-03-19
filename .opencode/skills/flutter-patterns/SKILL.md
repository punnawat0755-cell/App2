---
name: flutter-patterns
description: Canonical Flutter architecture reference. Defines folder structure, code patterns, naming conventions, and quality rules for every Flutter project in this pipeline. Load this before writing any Flutter code.
---

# Flutter Patterns — Architecture Reference

> **How to use this skill:** Read every section in order before writing a single line of code.
> Every decision you make must be traceable back to a rule here.
> If a rule conflicts with a PRD request, flag it to the Orchestrator — do not silently deviate.

---

## 1. Folder Structure (Non-negotiable)

Use **Feature-first + Clean Architecture** always. No other structure is permitted.

```
mobile/
├── lib/
│   ├── main.dart                          # Entry point only — loads .env, calls runApp()
│   ├── app/
│   │   ├── app.dart                       # ProviderScope + MaterialApp.router
│   │   └── router/
│   │       └── app_router.dart            # ALL GoRouter routes defined here — nowhere else
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart         # Base URL + all endpoint path constants
│   │   ├── errors/
│   │   │   ├── exceptions.dart            # ServerException, NetworkException, CacheException
│   │   │   └── failures.dart              # ServerFailure, NetworkFailure, CacheFailure
│   │   ├── network/
│   │   │   ├── dio_client.dart            # Single Dio instance + interceptors
│   │   │   └── safe_call.dart             # safeCall<T>() helper — wraps every API call
│   │   └── theme/
│   │       ├── app_theme.dart             # ThemeData.light() and ThemeData.dark()
│   │       ├── app_colors.dart            # All color tokens as static const
│   │       └── app_text_styles.dart       # All TextStyle tokens as static const
│   └── features/
│       └── [feature_name]/                # One folder per feature (auth, home, profile…)
│           ├── data/
│           │   ├── datasources/
│           │   │   └── [feature]_remote_datasource.dart
│           │   ├── models/
│           │   │   └── [feature]_model.dart
│           │   └── repositories/
│           │       └── [feature]_repository_impl.dart
│           ├── domain/
│           │   ├── entities/
│           │   │   └── [feature]_entity.dart
│           │   ├── repositories/
│           │   │   └── [feature]_repository.dart
│           │   └── usecases/
│           │       └── [verb]_[noun].dart
│           └── presentation/
│               ├── pages/
│               │   └── [feature]_page.dart
│               ├── widgets/
│               │   └── [component]_widget.dart
│               └── providers/
│                   └── [feature]_provider.dart
├── test/
│   ├── unit/
│   │   └── features/[feature]/
│   └── widget/
│       └── features/[feature]/
├── integration_test/
│   └── [feature]_flow_test.dart
├── .env
├── .env.example
└── pubspec.yaml
```

**Rules:**
- `main.dart` must contain ONLY `dotenv.load()` and `runApp()` — nothing else
- Business logic NEVER lives in `presentation/` — pages and widgets call providers only
- `core/` contains no feature-specific code
- `app_router.dart` is the single source of truth for all routes — `Navigator.push` is forbidden

---

## 2. Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Classes | `PascalCase` | `AuthRepository`, `LoginPage` |
| Variables & functions | `camelCase` | `currentUser`, `fetchProfile()` |
| Files | `snake_case.dart` | `auth_repository.dart` |
| Constants | `camelCase` static const | `AppColors.primary` |
| Test files | `[subject]_test.dart` | `login_page_test.dart` |
| Widget Keys | `const Key('snake_case')` | `const Key('login_button')` |
| Providers (Riverpod) | `camelCase` + `Provider` suffix from codegen | `authStateProvider` |

---

## 3. Dependency Management — Standard pubspec.yaml

```yaml
name: mobile
description: Flutter mobile application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: ^2.5.1       # State management
  riverpod_annotation: ^2.3.5    # Code gen annotations

  go_router: ^14.2.0             # Navigation

  dio: ^5.4.3+1                  # HTTP client
  fpdart: ^1.1.0                 # Either<Failure, T> for error handling

  flutter_dotenv: ^5.1.0         # .env loader
  freezed_annotation: ^2.4.1     # Immutable models
  json_annotation: ^4.9.0        # JSON serialization

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - .env
```

**Do not add packages not listed here without noting them in the Implementation Summary.**

---

## 4. Architecture Patterns — Canonical Code

### 4.1 Entry Point

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const App());
}
```

### 4.2 App Root

```dart
// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            title: 'App',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark, // default — override from PRD
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
```

### 4.3 GoRouter Setup

```dart
// lib/app/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // Add routes here — never use Navigator.push in widgets
    ],
  );
}
```

### 4.4 Dio Client + Interceptor

```dart
// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

@riverpod
Dio dioClient(DioClientRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach auth token if available
        handler.next(options);
      },
      onError: (error, handler) {
        // Log error centrally
        handler.next(error);
      },
    ),
  );

  return dio;
}
```

### 4.5 Error Handling — Exceptions & Failures

```dart
// lib/core/errors/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  const NetworkException();
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}
```

```dart
// lib/core/errors/failures.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server({required String message, int? statusCode}) = ServerFailure;
  const factory Failure.network() = NetworkFailure;
  const factory Failure.cache({required String message}) = CacheFailure;
  const factory Failure.unexpected({required String message}) = UnexpectedFailure;
}
```

### 4.6 safeCall — Universal Error Wrapper

**Every single API call in the project must go through `safeCall`. No exceptions.**

```dart
// lib/core/network/safe_call.dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

typedef EitherFailure<T> = Future<Either<Failure, T>>;

Future<Either<Failure, T>> safeCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      return Left(const Failure.network());
    }
    return Left(Failure.server(
      message: e.response?.data?['message'] ?? e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    ));
  } on ServerException catch (e) {
    return Left(Failure.server(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    return Left(Failure.unexpected(message: e.toString()));
  }
}
```

### 4.7 Domain Layer — Entity & Repository Interface

```dart
// lib/features/auth/domain/entities/user_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user_entity.freezed.dart';

// Pure Dart — zero JSON logic, zero Dio, zero Flutter imports
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String name,
  }) = _UserEntity;
}
```

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

// Abstract interface — data layer implements this
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
```

### 4.8 Domain Layer — UseCase

```dart
// lib/features/auth/domain/usecases/login_user.dart
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

part 'login_user.g.dart';

// One UseCase = one action. No multi-purpose classes.
@riverpod
LoginUser loginUser(LoginUserRef ref) {
  return LoginUser(ref.watch(authRepositoryProvider));
}

class LoginUser {
  final AuthRepository _repository;
  const LoginUser(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email, password);
  }
}
```

### 4.9 Data Layer — Model (extends Entity via freezed)

```dart
// lib/features/auth/data/models/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

// Model = Entity + JSON serialization. Never pass raw Map around.
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelMapper on UserModel {
  UserEntity toEntity() => UserEntity(id: id, email: email, name: name);
}
```

### 4.10 Data Layer — Remote DataSource

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

part 'auth_remote_datasource.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(AuthRemoteDataSourceRef ref) {
  return AuthRemoteDataSource(ref.watch(dioClientProvider));
}

class AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSource(this._dio);

  // Returns raw model — Repository converts to Entity and handles errors
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

### 4.11 Data Layer — Repository Implementation

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/safe_call.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) {
    // safeCall wraps ALL exceptions — never write try/catch in repositories
    return safeCall(() async {
      final model = await _dataSource.login(email, password);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> logout() => safeCall(() async {});

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() =>
      safeCall(() async => throw UnimplementedError());
}
```

### 4.12 Presentation Layer — Provider (Riverpod)

```dart
// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_user.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

// State — always use sealed union via freezed
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserEntity user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

// Notifier — NO business logic here, only UseCase calls
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    final result = await ref.read(loginUserProvider).call(
      email: email,
      password: password,
    );

    // fold = handle both Left (failure) and Right (success)
    state = result.fold(
      (failure) => failure.when(
        server: (msg, _) => AuthState.error(msg),
        network: () => const AuthState.error('No internet connection'),
        cache: (msg) => AuthState.error(msg),
        unexpected: (msg) => AuthState.error(msg),
      ),
      (user) => AuthState.authenticated(user),
    );
  }
}
```

### 4.13 Presentation Layer — Page

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form_widget.dart';

// Pages are ConsumerWidget — they read providers, never contain business logic
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for state changes to navigate or show errors
    ref.listen<AuthState>(authNotifierProvider, (_, state) {
      state.whenOrNull(
        authenticated: (_) => context.go('/home'),
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => LoginFormWidget(
            onSubmit: (email, password) => ref
                .read(authNotifierProvider.notifier)
                .login(email, password),
          ),
        ),
      ),
    );
  }
}
```

### 4.14 Presentation Layer — Widget (reusable)

```dart
// lib/features/auth/presentation/widgets/login_form_widget.dart
import 'package:flutter/material.dart';

// Widget = pure UI. No providers, no business logic, no Dio.
class LoginFormWidget extends StatefulWidget {
  final void Function(String email, String password) onSubmit;

  const LoginFormWidget({super.key, required this.onSubmit});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              key: const Key('email_field'),        // Required for testability
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('password_field'),     // Required for testability
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) =>
                  v == null || v.length < 8 ? 'Min 8 characters' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('login_button'),     // Required for testability
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _emailController.text.trim(),
                      _passwordController.text,
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Theme — Material 3

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

// All colors as static const — NEVER hardcode Color() in widgets
abstract class AppColors {
  static const primary = Color(0xFF6750A4);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFF1C1B1F);
  static const onSurface = Color(0xFFE6E1E5);
  static const error = Color(0xFFF2B8B8);
  static const onError = Color(0xFF601410);
}
```

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
      );
}
```

**Rules:**
- Always `useMaterial3: true`
- Always use `Theme.of(context).colorScheme.X` in widgets — never `AppColors.X` directly in widgets
- Never hardcode `Color(0x...)` anywhere outside `app_colors.dart`
- WCAG AA minimum: text contrast ratio ≥ 4.5:1 on all backgrounds

---

## 6. API Constants

```dart
// lib/core/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Endpoint paths — never hardcode in datasources
  static const login = '/api/auth/login';
  static const logout = '/api/auth/logout';
  static const profile = '/api/users/me';
}
```

---

## 7. Testing Patterns

### 7.1 Widget Test — Required Key Convention

Every interactive widget **must** have a `Key` for testability. No exceptions:

| Widget type | Key value |
|---|---|
| Text input | `Key('[field_name]_field')` e.g. `Key('email_field')` |
| Button | `Key('[action]_button')` e.g. `Key('login_button')` |
| Page root | `Key('[feature]_page')` e.g. `Key('login_page')` |
| Error text | `Key('[field]_error')` e.g. `Key('email_error')` |
| Loading indicator | `Key('loading_indicator')` |

### 7.2 Widget Test Template

```dart
// test/widget/features/auth/login_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';

void main() {
  Widget buildSubject() => const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      );

  group('LoginPage', () {
    testWidgets('renders email field, password field, and login button',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });
  });
}
```

### 7.3 Unit Test Template (UseCase)

```dart
// test/unit/features/auth/login_user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/auth/domain/entities/user_entity.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/login_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUser sut;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    sut = LoginUser(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = UserEntity(id: '1', email: tEmail, name: 'Test');

  test('returns UserEntity on successful login', () async {
    when(() => mockRepository.login(tEmail, tPassword))
        .thenAnswer((_) async => const Right(tUser));

    final result = await sut.call(email: tEmail, password: tPassword);

    expect(result, const Right(tUser));
    verify(() => mockRepository.login(tEmail, tPassword)).called(1);
  });

  test('returns ServerFailure when repository fails', () async {
    when(() => mockRepository.login(tEmail, tPassword)).thenAnswer(
        (_) async => const Left(Failure.server(message: 'Unauthorized')));

    final result = await sut.call(email: tEmail, password: tPassword);

    expect(result.isLeft(), true);
  });
}
```

---

## 8. Code Quality Rules (DoD — Definition of Done)

Before reporting implementation complete, verify every item:

**Format & Analysis**
- [ ] `flutter format . --set-exit-if-changed` passes — no unformatted files
- [ ] `flutter analyze` exits with zero errors and zero warnings
- [ ] No `print()` anywhere — use `debugPrint()` or a logger package

**Type Safety**
- [ ] Zero `dynamic` types — every variable, parameter, and return type is explicitly typed
- [ ] Zero raw `Map<String, dynamic>` passed between layers — all API data goes through Model classes
- [ ] All `async` functions have explicit return types

**Architecture**
- [ ] Zero `Navigator.push` / `Navigator.pop` in any widget — all navigation via GoRouter `context.go()` / `context.push()`
- [ ] Zero business logic in pages or widgets — only provider reads and UI rendering
- [ ] All providers defined in `presentation/providers/` — none in pages or widgets directly

**UI & Accessibility**
- [ ] Every `Image` widget has `semanticLabel`
- [ ] Every interactive widget has a `const Key('...')` for testability
- [ ] No hardcoded colors — all colors via `Theme.of(context).colorScheme`
- [ ] No hardcoded strings — all user-facing text from constants or l10n
- [ ] `const` applied to every widget constructor that qualifies

**Environment & Config**
- [ ] All env vars read from `flutter_dotenv` — `API_BASE_URL` and others never hardcoded
- [ ] `.env.example` lists every key used in the codebase with a placeholder value
- [ ] `pubspec.yaml` `assets:` section includes `.env`

**Testing**
- [ ] All interactive widgets have `Key(...)` identifiers matching the Key Convention table (Section 7.1)
- [ ] `flutter test test/ --reporter=expanded` passes with zero failures
