# DentSpace — Flutter Mobile Application

A cross-platform mobile app connecting patients with verified dentists,
with a marketplace for dental tools and a full treatment lifecycle
reviewed by administration.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Tech Stack](#tech-stack)
- [Setup](#setup)
- [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Testing](#testing)
- [Build & Release](#build--release)
- [Local Storage Strategy](#local-storage-strategy)
- [Notifications](#notifications)
- [Internationalization](#internationalization)
- [Theming](#theming)
- [State Management](#state-management)
- [Networking](#networking)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

---

## Overview

DentSpace serves three user roles:

| Role | Capabilities |
|------|-------------|
| **Patient** | Describe symptoms, receive preliminary diagnosis, approve doctor requests, complete treatment for free |
| **Doctor** | Browse available patient cases, request bookings (max 3 active), mark treatments complete, list/sell dental tools |
| **Admin** | Managed via a separate web panel (Next.js, planned) |

---

## Architecture

The app follows **Clean Architecture** combined with a **Feature-First** folder layout.
┌─────────────────────────────────────────────┐
│ Presentation Layer │
│ Pages · Widgets · BLoC (State Management) │
└────────────────────┬────────────────────────┘
│ UseCases
┌────────────────────▼────────────────────────┐
│ Domain Layer │
│ Entities · Repository Interfaces · UseCases│
│ (pure Dart — no Flutter, no Dio) │
└────────────────────┬────────────────────────┘
│ Implements
┌────────────────────▼────────────────────────┐
│ Data Layer │
│ DataSources (Dio) · Repositories · Cache │
└─────────────────────────────────────────────┘

### Key principles

- **Domain has zero dependencies** — no Flutter, no Dio, no Hive.
- **Repositories are the only bridge** between Domain and Data.
- **Every BLoC consumes UseCases only** — never repositories directly.
- **Cache-aside pattern** — network-first, cache-fallback on failure.

---

## Folder Structure
lib/
├── core/
│ ├── cache/ # Hive wrapper + typed cache service
│ │ ├── cache_keys.dart
│ │ ├── cache_service.dart
│ │ ├── hive_cache_box.dart
│ │ └── hive_initializer.dart
│ ├── config/ # Environment / AppConfig
│ │ ├── app_config.dart
│ │ └── environment.dart
│ ├── di/ # Dependency Injection (GetIt)
│ │ └── injection.dart
│ ├── error/ # Failures, Exceptions, Mapper
│ │ ├── exception_mapper.dart
│ │ ├── exceptions.dart
│ │ └── failures.dart
│ ├── localization/ # AR/EN + RTL
│ │ └── localization_cubit.dart
│ ├── network/ # Dio + Interceptors
│ │ ├── dio_client.dart
│ │ ├── interceptors/
│ │ │ ├── auth_interceptor.dart
│ │ │ └── error_interceptor.dart
│ │ └── network_info.dart
│ ├── notifications/ # FCM + Local notifications
│ │ ├── fcm_sync_service.dart
│ │ ├── notification_router.dart
│ │ ├── notification_service.dart
│ │ └── notification_translator.dart
│ ├── router/ # GoRouter
│ │ ├── app_router.dart
│ │ └── routes.dart
│ ├── services/ # Shared services
│ │ ├── image_picker_service.dart
│ │ └── local_storage_service.dart
│ ├── theme/ # Colors, styles, cubit
│ │ ├── app_colors.dart
│ │ ├── app_text_styles.dart
│ │ ├── app_theme.dart
│ │ └── theme_cubit.dart
│ ├── usecase/ # Base UseCase + NoParams
│ │ └── usecase.dart
│ ├── utils/ # Helpers
│ │ ├── helpers/debouncer.dart
│ │ └── validators.dart
│ └── widgets/ # Shared UI components
│ ├── home/ # HomeShell, HomeDrawer, QuickActionCard
│ ├── pages/placeholder_page.dart
│ └── password_strength_indicator.dart
│
└── features/ # Feature modules
├── about/
├── appointments/
├── auth/
├── home/
│ ├── doctor_home/
│ └── patient_home/
├── notifications/
├── onboarding/
├── orders/
├── patient_cases/
├── profile/
├── setup/ # Legacy (removed)
├── splash/
├── support/
└── tools/

Each feature folder follows:

feature_name/
├── data/
│ ├── datasources/ # Remote (Dio) + Local (Hive) sources
│ ├── repositories/ # RepositoryImpl (implements domain interface)
│ └── models/ # JSON models (when needed)
├── domain/
│ ├── entities/ # Pure Dart classes
│ ├── repositories/ # Abstract interfaces
│ └── usecases/ # One class per operation
└── presentation/
├── bloc/ # Bloc + Event + State
├── pages/ # Full screens
└── widgets/ # Feature-scoped widgets

---

## Tech Stack

| Concern | Package | Version |
|---------|---------|---------|
| State Management | `flutter_bloc` | ^9.1.1 |
| DI | `get_it` | ^9.3.0 |
| Functional Programming | `dartz` | ^0.10.1 |
| Networking | `dio` | ^5.7.0 |
| Connectivity | `connectivity_plus` | ^7.3.1 |
| Secure Storage | `flutter_secure_storage` | ^11.2.0 |
| Preferences | `shared_preferences` | ^2.3.3 |
| Local Cache | `hive` + `hive_flutter` | ^2.2.3 |
| Routing | `go_router` | ^18.0.1 |
| Animations | `flutter_animate` | ^4.5.0 |
| Image Caching | `cached_network_image` | ^4.0.2 |
| Firebase | `firebase_core`, `firebase_messaging` | ^4.15.0, ^16.7.0 |
| Local Notifications | `flutter_local_notifications` | ^22.3.1 |
| Forms & Validation | Built-in + custom `Validators` | — |
| Fonts | Cairo (Google Fonts) | ^8.2.1 |

**Dart SDK**: `>=3.5.0 <4.0.0`  
**Flutter**: `>=3.24.0`

---

## Setup

### Prerequisites

- Flutter SDK 3.24 or newer
- Dart SDK 3.5 or newer
- Android Studio (for Android) or Xcode (for iOS)
- A running DentSpace backend (`http://YOUR_IP:8000`)

### Steps

```bash
# 1. Clone or navigate to the project
cd FrontEnd

# 2. Install dependencies
flutter pub get

# 3. Configure environment
#    Edit lib/core/config/environment.dart and set apiBaseUrl
#    to your backend URL (see Configuration section below)

# 4. (Optional) Firebase setup
#    Place google-services.json in android/app/

# 5. Run the app
flutter run
Configuration
Backend URL
Open lib/core/config/environment.dart and edit:
static String get apiBaseUrl {
  switch (current) {
    case Env.development:
      return 'http://YOUR_LOCAL_IP:8000/api/v1';   // ← change this
    case Env.staging:
      return 'https://staging.dentspace.app/api/v1';
    case Env.production:
      return 'https://api.dentspace.app/api/v1';
  }
}
For Android emulator: use http://10.0.2.2:8000/api/v1
For physical device: use http://YOUR_COMPUTER_IP:8000/api/v1 (e.g., 192.168.1.105)
For production: use an HTTPS URL.

Firebase (Push Notifications)
Create a Firebase project (or use an existing one).

Add an Android app with package name com.dentspace.app.

Download google-services.json and place it in android/app/.

Ensure the same project_id is used on the backend (firebase-credentials.json).

Without Firebase, notifications still arrive in the in-app list — only push (system tray) is skipped.

Running the App
# Debug mode (hot reload)
flutter run

# Release mode (for performance testing)
flutter run --release

# Profile mode (for DevTools profiling)
flutter run --profile

# Specify a device
flutter devices
flutter run -d <device-id>
Useful CLI commands
Command	Purpose
r	Hot reload
R	Hot restart
p	Toggle performance overlay
q	Quit
Testing
# Run all tests
flutter test

# Expanded output
flutter test --reporter expanded

# One file
flutter test test/features/tools/bloc/tools_bloc_test.dart

# One feature
flutter test test/features/tools/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
Test coverage
Layer	Coverage
Entities (fromJson / toJson)	✅ Full
BLoCs (events / states)	✅ Full
Repositories (cache + invalidation)	✅ Full
Validators	✅ Full
Cache / Storage	✅ Full
Network Interceptors	✅ Full
Integration (order lifecycle)	✅ Full
Total: ~312 tests, ~90% coverage of business logic.
Build & Release
Debug APK (for quick testing)
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
Release APK (for device install)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
For personal testing, the release APK uses the debug signing key — installs fine on your device, but cannot be uploaded to Google Play.
Production release (Google Play)
1 Generate a keystore:
keytool -genkey -v -keystore dentspace-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias dentspace
2 Create android/key.properties with the signing details.
3 Update android/app/build.gradle.kts to use the release signing config.
4 Build:
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
Split APKs (smaller size)
flutter build apk --release --split-per-abi
Local Storage Strategy
Three storage mechanisms, each for a specific purpose:

Purpose	Technology	Location
Auth tokens	flutter_secure_storage	OS-level encrypted (Keychain / Keystore)
Preferences	shared_preferences	Theme, language, onboarding flag
API cache	hive (JSON, TTL)	Lists, details, user profile
Cache TTL policy
Resource	TTL
Lists (tools, orders, notifications)	5 minutes
Details (case, tool, order)	30 minutes
User profile	6 hours
On logout → CacheService.clearAll() wipes everything to protect privacy.

Cache invalidation
Every mutation (create / update / delete) triggers invalidateX() for the affected prefix — guaranteeing no stale data on the next read.

Notifications
The app handles three notification channels:

1. Foreground (app open)
FCM message received → shown as a local notification in the system tray.

The in-app notification list refreshes automatically via LoadNotificationsEvent.

2. Background (app in background)
OS displays the notification natively (backend sends a notification payload).

3. In-app list
Every notification is persisted on the backend AND locally (cached).

Tapping a notification routes to the correct screen via NotificationRouter:

Type	Routes to
case_verified	Achievements
case_completed / case_rejected	Appointments
appointment_*	Appointments
tool_order_* / tool_sold	Order details (via payload order_id)
system	Stay in place
FCM Token lifecycle
FcmSyncService requests permission on startup.

Token is pushed to the backend (PATCH /auth/me/fcm-token) after every login and on rotation.

Dead tokens are cleared automatically (unregistered response).

Internationalization
Locales: Arabic (ar) + English (en)

Default: Arabic (RTL)

Switching: runtime via LocalizationCubit

Persistence: saved in SharedPreferences under app_locale

RTL handling
Every directional icon uses isArabic ? Icons.arrow_forward : Icons.arrow_back.

EdgeInsetsDirectional used instead of EdgeInsets.only(left/right).

Text alignment follows Directionality.of(context).

Notification text
The backend sends Arabic fallback strings for the OS tray.

The in-app list uses NotificationTranslator — a pure function that rebuilds the text from type + payload in the current locale.

Theming
Modes: Light / Dark / System (via ThemeCubit)

Persistence: SharedPreferences under theme_mode

Material 3: enabled

Font: Cairo

Color palette (from AppColors)
Primary   #0D6EFD  (medical blue)
Secondary #14B8A6  (soft teal)
Success   #10B981
Warning   #F59E0B
Error     #EF4444
Info      #3B82F6
Dark mode gotchas
Never use raw Colors.white / Colors.black — always isDark ? AppColors.darkX : AppColors.lightX.

Overlays (Colors.white.withValues(alpha: 0.05)) are safe on either theme.

State Management
BLoC pattern with flutter_bloc.

Convention
One BLoC per feature (ToolsBloc, OrdersBloc, etc.)

Events are sealed class extending a base — exhaustive switch support

States are immutable with copyWith(...) and clearX flags

Side effects (SnackBars, navigation) handled by BlocListener — never in build

Registration in DI
Singletons: AuthBloc, NotificationsBloc — persist across navigation

Factories: ToolsBloc, OrdersBloc, CasesBloc, AppointmentsBloc — fresh per page

Networking
Dio with two interceptors:

Interceptor	Responsibility
AuthInterceptor	Attaches Bearer <token> to every request (skips auth endpoints). Clears tokens on hard 401.
ErrorInterceptor	Maps DioException → typed ServerException / NetworkException / UnauthorizedException.
Response shape
Success: 200/201/204 → returns parsed body.

Failure: interceptor throws → repository catches → maps to Failure via mapErrorToFailure.

The presentation layer only sees Either<Failure, T> — never raw exceptions.

Error Handling
Two-level error system:

Level	Type	Purpose
Data	ServerException, NetworkException, UnauthorizedException, CacheException	Thrown by data sources
Domain	ServerFailure, NetworkFailure, UnauthorizedFailure, CacheFailure, UnknownFailure	Returned by use cases
The mapping happens in core/error/exception_mapper.dart — single source of truth.

422 Validation errors
extractValidationErrors(error) parses FastAPI's field-level error structure into Map<String, List<String>> for form display.

Troubleshooting
"NO ROUTESETUP" / "No route defined for X"
The route is not registered in app_router.dart. Check routes.dart for the constant and add a matching GoRoute.

"Duplicate fullpaths for name X"
Two GoRoutes share the same path or name. Search app_router.dart for the duplicate.

on<Event> called multiple times
A BLoC handler was registered twice. Open the BLoC's constructor and remove the duplicate.

API calls fail with 401
Token expired → check password_changed_at on the backend.

Token not attached → verify AuthInterceptor whitelist does NOT include the path.

Push notifications don't arrive
Check google-services.json (Android) exists.

Check the backend firebase-credentials.json uses the same Firebase project.

Check the FCM token was pushed to /auth/me/fcm-token (logcat).

Check the Android channel ID matches (dentspace_channel on both sides).

Images don't load
Check the Cloudinary URL is HTTPS.

Check the image magic bytes are valid (JPEG/PNG/WEBP).

Hive box fails to open
Ensure HiveInitializer.init() runs BEFORE configureDependencies().

On schema change, bump CacheKeys.mainBox version (v1 → v2).


