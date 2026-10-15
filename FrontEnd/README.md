# DentSpace — Flutter Mobile Application

A cross-platform mobile application connecting patients with verified dentists, featuring patient case management, appointment requests, a dental tools marketplace, and a complete treatment lifecycle.

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
|---|---|
| **Patient** | Describe symptoms, receive preliminary diagnoses, review doctor appointment requests, and receive treatment free of charge under the application's training model. |
| **Doctor** | Browse available patient cases, request appointments (maximum 3 active bookings), mark treatments as completed, and list or sell dental tools. |
| **Admin** | Manage application operations through the administration interface. The administration panel is maintained separately from the Flutter application. |

---

## Architecture

The application follows **Clean Architecture** combined with a **Feature-First** folder structure.

```text
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│       Pages · Widgets · BLoC (State)         │
└──────────────────────┬──────────────────────┘
                       │ Uses UseCases
┌──────────────────────▼──────────────────────┐
│                 Domain Layer                 │
│       Entities · Repository Interfaces       │
│                  · UseCases                  │
│       Pure Dart — no Flutter or Dio          │
└──────────────────────┬──────────────────────┘
                       │ Implemented by
┌──────────────────────▼──────────────────────┐
│                  Data Layer                  │
│       DataSources · Repositories · Cache     │
│                Dio · Hive                    │
└─────────────────────────────────────────────┘
```

### Key Principles

- **Domain independence:** The domain layer has no direct dependencies on Flutter, Dio, or Hive.
- **Repository abstraction:** Repositories provide the bridge between the domain and data layers.
- **UseCase-driven state management:** BLoCs interact with UseCases instead of accessing repositories directly.
- **Cache-aside strategy:** Network requests are preferred, with cached data used as a fallback when appropriate.
- **Feature isolation:** Each feature contains its own data, domain, and presentation components.
- **Dependency injection:** GetIt manages dependency registration and resolution.

---

## Folder Structure

The following structure illustrates the main organization of the application:

```text
lib/
├── core/
│   ├── cache/
│   │   ├── cache_keys.dart
│   │   ├── cache_service.dart
│   │   ├── hive_cache_box.dart
│   │   └── hive_initializer.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   └── environment.dart
│   │
│   ├── di/
│   │   └── injection.dart
│   │
│   ├── error/
│   │   ├── exception_mapper.dart
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   │
│   ├── localization/
│   │   └── localization_cubit.dart
│   │
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   └── network_info.dart
│   │
│   ├── notifications/
│   │   ├── fcm_sync_service.dart
│   │   ├── notification_router.dart
│   │   ├── notification_service.dart
│   │   └── notification_translator.dart
│   │
│   ├── router/
│   │   ├── app_router.dart
│   │   └── routes.dart
│   │
│   ├── services/
│   │   ├── image_picker_service.dart
│   │   └── local_storage_service.dart
│   │
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_theme.dart
│   │   └── theme_cubit.dart
│   │
│   ├── usecase/
│   │   └── usecase.dart
│   │
│   ├── utils/
│   │   ├── helpers/
│   │   │   └── debouncer.dart
│   │   └── validators.dart
│   │
│   └── widgets/
│       ├── home/
│       │   ├── home_shell.dart
│       │   ├── home_drawer.dart
│       │   └── quick_action_card.dart
│       ├── pages/
│       │   └── placeholder_page.dart
│       └── password_strength_indicator.dart
│
└── features/
    ├── about/
    ├── appointments/
    ├── auth/
    ├── home/
    │   ├── doctor_home/
    │   └── patient_home/
    ├── notifications/
    ├── onboarding/
    ├── orders/
    ├── patient_cases/
    ├── profile/
    ├── setup/
    ├── splash/
    ├── support/
    └── tools/
```

Each feature generally follows this structure:

```text
feature_name/
├── data/
│   ├── datasources/
│   │   ├── remote/
│   │   └── local/
│   ├── repositories/
│   └── models/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── bloc/
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── pages/
    └── widgets/
```

**Note:** The directory trees illustrate the intended organization and may omit individual files or feature-specific variations.

---

## Tech Stack

| Concern | Technology | Version |
|---|---|---|
| Framework | Flutter | `>=3.24.0` |
| Language | Dart | `>=3.5.0 <4.0.0` |
| State Management | `flutter_bloc` | `^9.1.1` |
| Dependency Injection | `get_it` | `^9.3.0` |
| Functional Programming | `dartz` | `^0.10.1` |
| Networking | `dio` | `^5.7.0` |
| Connectivity | `connectivity_plus` | `^7.3.1` |
| Secure Storage | `flutter_secure_storage` | `^11.2.0` |
| Preferences | `shared_preferences` | `^2.3.3` |
| Local Cache | `hive`, `hive_flutter` | `^2.2.3` |
| Routing | `go_router` | `^18.0.1` |
| Animations | `flutter_animate` | `^4.5.0` |
| Image Caching | `cached_network_image` | `^4.0.2` |
| Firebase Core | `firebase_core` | `^4.15.0` |
| Firebase Messaging | `firebase_messaging` | `^16.7.0` |
| Local Notifications | `flutter_local_notifications` | `^22.3.1` |
| Forms and Validation | Built-in Flutter widgets and custom validators | — |
| Fonts | Cairo via Google Fonts | `^8.2.1` |

> Package versions are reproduced from the supplied project documentation. The project's `pubspec.yaml` and `pubspec.lock` are the authoritative sources for the actual dependency versions.

---

## Setup

### Prerequisites

Install the following tools before running the application:

- Flutter SDK 3.24 or newer.
- Dart SDK 3.5 or newer.
- Android Studio and the Android SDK for Android development.
- Xcode for iOS development on macOS.
- A running DentSpace backend API.
- A Firebase project if push notifications are required.

### Installation

Clone the repository if you have not already done so:

```bash
git clone https://github.com/mohamad-yousef88/DentSpace-V2.git
```

Navigate to the Flutter application directory:

```bash
cd DentSpace-V2/FrontEnd
```

Install dependencies:

```bash
flutter pub get
```

Configure the backend URL as described in the [Configuration](#configuration) section.

If Firebase push notifications are required, configure the Android Firebase application as described below.

Run the application:

```bash
flutter run
```

---

## Configuration

### Backend URL

Open:

```text
lib/core/config/environment.dart
```

Configure the API base URL to point to your running backend.

The following is an illustrative example; adapt it to the actual configuration defined in your project:

```dart
static String get apiBaseUrl {
  switch (current) {
    case Env.development:
      return 'http://YOUR_LOCAL_IP:8000/api/v1';

    case Env.staging:
      return 'https://staging.dentspace.app/api/v1';

    case Env.production:
      return 'https://api.dentspace.app/api/v1';
  }
}
```

Replace the example addresses with the actual URLs for your environments.

#### Choosing the Correct URL

| Environment | Example URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api/v1` |
| Physical Android device | `http://YOUR_COMPUTER_IP:8000/api/v1` |
| Staging server | Your staging API URL |
| Production server | Your production HTTPS API URL |

**Important:**

- `10.0.2.2` is the Android emulator's special address for accessing the host computer's loopback interface.
- For a physical device, the computer and phone generally need to be connected to the same accessible network.
- Ensure your firewall allows the required local connections.
- Use HTTPS for production deployments.
- Never commit private production credentials or secret configuration values to the repository.

### Firebase — Push Notifications

Firebase Cloud Messaging (FCM) is used for push notifications.

To configure Firebase for Android:

1. Create a Firebase project or use an existing one.
2. Register an Android application in Firebase using the actual Android application ID configured in your project.
3. Download the corresponding `google-services.json` file.
4. Place it at:

   ```text
   android/app/google-services.json
   ```

5. Configure the backend to use credentials from the same Firebase project.
6. Verify that the Android Firebase configuration and backend Firebase credentials refer to the same project.

**Security note:** Do not commit private service-account credentials such as `firebase-credentials.json`. Keep them outside version control and configure the backend to load them securely.

If Firebase is not configured, push notifications may not work. Whether the in-app notification list remains available depends on the backend and local application configuration.

---

## Running the App

### Debug Mode

Run the application with debugging enabled:

```bash
flutter run
```

### Release Mode

Run a release build on a connected device:

```bash
flutter run --release
```

### Profile Mode

Run the application in profile mode for performance analysis:

```bash
flutter run --profile
```

### Select a Device

List available devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

### Useful Flutter CLI Commands

| Command | Purpose |
|---|---|
| `r` | Perform hot reload while the app is running. |
| `R` | Perform hot restart while the app is running. |
| `p` | Toggle the performance overlay when supported. |
| `q` | Quit the running application. |

---

## Testing

### Run All Tests

```bash
flutter test
```

### Expanded Test Output

```bash
flutter test --reporter expanded
```

### Run a Specific Test File

```bash
flutter test test/features/tools/bloc/tools_bloc_test.dart
```

### Run Tests for a Feature

```bash
flutter test test/features/tools/
```

### Generate Coverage Data

```bash
flutter test --coverage
```

If `genhtml` is installed, generate an HTML coverage report:

```bash
genhtml coverage/lcov.info -o coverage/html
```

On macOS, open the report with:

```bash
open coverage/html/index.html
```

On Windows, open `coverage/html/index.html` using a web browser or run:

```powershell
Start-Process coverage/html/index.html
```

### Test Coverage

The original project notes report the following coverage areas:

| Layer | Reported Coverage |
|---|---|
| Entities (`fromJson` / `toJson`) | Full |
| BLoCs (events and states) | Full |
| Repositories (cache and invalidation) | Full |
| Validators | Full |
| Cache and storage | Full |
| Network interceptors | Full |
| Integration (order lifecycle) | Full |

**Reported test metrics:** Approximately 312 tests and 90% coverage of business logic.

These figures are the project's documented estimates and should be verified by running the current test suite and generating a fresh coverage report.

---

## Build & Release

### Debug APK

Build a debug APK for quick testing:

```bash
flutter build apk --debug
```

Expected output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK

Build a release APK for installation on a device:

```bash
flutter build apk --release
```

Expected output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Signing configuration depends on the project's Android Gradle setup. Verify the actual signing configuration before distributing a release build.

### Split APKs by ABI

Generate smaller APKs for supported CPU architectures:

```bash
flutter build apk --release --split-per-abi
```

### Production Release — Google Play

For a production Android release:

1. Generate a secure signing keystore.
2. Store signing information in a protected configuration file.
3. Configure the Android release signing settings.
4. Keep the keystore and signing credentials out of version control.
5. Build the Android App Bundle.

Example keystore-generation command:

```bash
keytool -genkey -v \
  -keystore dentspace-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias dentspace
```

Create and configure the required signing properties file according to the Android Gradle configuration in the project.

Build the release bundle:

```bash
flutter build appbundle --release
```

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

**Important:** A production release must use the appropriate signing configuration. Do not distribute a build as a production-ready release until signing, API endpoints, Firebase configuration, and release settings have been verified.

---

## Local Storage Strategy

The application uses separate storage mechanisms for different purposes.

| Purpose | Technology | Storage |
|---|---|---|
| Authentication tokens | `flutter_secure_storage` | Platform secure storage, such as Android Keystore-backed storage or the iOS Keychain. |
| User preferences | `shared_preferences` | Theme, language, and onboarding preferences. |
| API cache | Hive | Cached API data, such as lists, details, and user profiles. |

### Cache TTL Policy

The documented cache expiration policy is:

| Resource | Time to Live (TTL) |
|---|---|
| Lists (tools, orders, notifications) | 5 minutes |
| Details (cases, tools, orders) | 30 minutes |
| User profile | 6 hours |

Actual expiration behavior depends on the implementation of the cache service and the relevant cache keys.

### Logout and Privacy

On logout, the documented strategy is to clear cached data:

```dart
CacheService.clearAll();
```

This helps prevent previously cached user information from appearing after another user signs in.

### Cache Invalidation

After a successful create, update, or delete operation, the relevant cache entries should be invalidated.

The project uses `invalidateX()`-style operations to invalidate affected resource prefixes, helping prevent stale data from being returned on subsequent reads.

---

## Notifications

The application supports Firebase Cloud Messaging and local notification handling.

### 1. Foreground Notifications

When an FCM message arrives while the application is open:

- The foreground message handler receives the message.
- A local notification can be displayed in the system tray.
- The in-app notification list can be refreshed through `LoadNotificationsEvent`.

### 2. Background Notifications

When the application is in the background, the operating system can display notifications when the message payload and platform configuration support it.

### 3. In-App Notification List

Notifications are retrieved from the backend and may be cached locally.

When a notification is tapped, the application uses `NotificationRouter` to navigate to the relevant screen.

### Notification Routing

The documented notification routing rules are:

| Notification Type | Destination |
|---|---|
| `case_verified` | Achievements |
| `case_completed` | Appointments |
| `case_rejected` | Appointments |
| `appointment_*` | Appointments |
| `tool_order_*` | Order details |
| `tool_sold` | Order details |
| `system` | Remain on the current screen |

The exact destination and required payload fields depend on the implementation of `NotificationRouter`.

For tool-order notifications, the documented payload includes an `order_id` where needed to identify the relevant order.

### FCM Token Lifecycle

The documented FCM synchronization process is:

1. `FcmSyncService` requests notification permission where required.
2. The device obtains an FCM registration token.
3. The token is synchronized with the backend after login.
4. Token updates are synchronized when the token rotates.
5. The backend can clear invalid tokens when Firebase reports that they are no longer registered.

The documented token endpoint is:

```http
PATCH /auth/me/fcm-token
```

The actual endpoint, request payload, and permission behavior should match the backend implementation.

---

## Internationalization

The application supports Arabic and English.

| Setting | Behavior |
|---|---|
| Supported locales | Arabic (`ar`) and English (`en`) |
| Default locale | Arabic |
| Layout direction | RTL for Arabic; LTR for English |
| Language switching | Runtime switching through `LocalizationCubit` |
| Persistence | `SharedPreferences`, using `app_locale` |

### RTL Handling

The application follows these layout conventions:

- Direction-aware icons should use the appropriate orientation for the active locale.
- `EdgeInsetsDirectional` should be preferred over hard-coded left and right padding.
- Text alignment should follow the active text direction.
- Navigation and directional controls should remain intuitive in both Arabic and English.

### Notification Text

The documented notification strategy distinguishes between system notifications and in-app notifications:

- The backend can provide Arabic fallback strings for system-tray notifications.
- `NotificationTranslator` can reconstruct in-app notification text from the notification type and payload according to the current locale.

---

## Theming

The application supports three theme modes:

- Light
- Dark
- System

Theme selection is managed through `ThemeCubit` and persisted in `SharedPreferences` under the `theme_mode` key.

### Material Design

The application uses Material 3 and the Cairo font.

### Color Palette

The documented palette is:

| Color Role | Hex Value |
|---|---|
| Primary | `#0D6EFD` |
| Secondary | `#14B8A6` |
| Success | `#10B981` |
| Warning | `#F59E0B` |
| Error | `#EF4444` |
| Info | `#3B82F6` |

### Dark Mode Guidelines

- Prefer semantic colors from `AppColors` rather than hard-coded black and white values.
- Use the appropriate light or dark color variant for surfaces, text, and borders.
- Ensure dialogs, overlays, cards, and input fields remain readable in both themes.
- Test the theme on all major screens, including forms, navigation, and notification views.

---

## State Management

The application uses the **BLoC pattern** with `flutter_bloc`.

### Conventions

- Each feature has its own BLoC where appropriate, such as `ToolsBloc`, `OrdersBloc`, and `AppointmentsBloc`.
- Events represent user actions or application events.
- States are immutable and describe the current presentation state.
- State classes may provide `copyWith(...)` methods and explicit flags for clearing optional values.
- Side effects, such as navigation and SnackBars, should be handled through `BlocListener` rather than directly inside `build()`.

### Dependency Registration

The documented dependency-injection strategy distinguishes between shared instances and feature-scoped instances.

| Registration | Examples | Purpose |
|---|---|---|
| Singletons | `AuthBloc`, `NotificationsBloc` | Shared instances that persist across navigation where required. |
| Factories | `ToolsBloc`, `OrdersBloc`, `CasesBloc`, `AppointmentsBloc` | Fresh instances for feature or page lifecycles. |

The exact registrations should be verified in `core/di/injection.dart`.

---

## Networking

The application uses Dio for HTTP requests to the backend API.

### Interceptors

| Interceptor | Responsibility |
|---|---|
| `AuthInterceptor` | Attaches the Bearer token to applicable requests and handles authentication-related responses. |
| `ErrorInterceptor` | Converts Dio errors into application-specific exceptions. |

### Response Handling

The documented request flow is:

1. A data source sends an HTTP request through Dio.
2. Interceptors process authentication and network errors.
3. Data sources parse successful responses.
4. Repositories handle data-source results and map exceptions to failures.
5. UseCases return results to the presentation layer.

The application uses `Either<Failure, T>` to represent success or failure in the domain-facing flow.

Typical successful HTTP status codes include:

- `200 OK`
- `201 Created`
- `204 No Content`

A `204 No Content` response has no response body to parse.

### Authentication

Protected requests use the Bearer token scheme:

```http
Authorization: Bearer <token>
```

Authentication behavior, including token expiration and handling of `401 Unauthorized` responses, is managed by the authentication interceptor and related authentication services.

---

## Error Handling

The application separates exceptions in the data layer from failures exposed to the domain and presentation layers.

### Data-Layer Exceptions

| Exception | Purpose |
|---|---|
| `ServerException` | Represents a backend or server-side error. |
| `NetworkException` | Represents a network connectivity or transport error. |
| `UnauthorizedException` | Represents an authentication or authorization failure. |
| `CacheException` | Represents a local cache error. |

### Domain-Layer Failures

| Failure | Purpose |
|---|---|
| `ServerFailure` | Represents a server-related failure. |
| `NetworkFailure` | Represents a network failure. |
| `UnauthorizedFailure` | Represents an authentication-related failure. |
| `CacheFailure` | Represents a local storage or cache failure. |
| `UnknownFailure` | Represents an unexpected or unmapped failure. |

Exception-to-failure conversion is centralized in:

```text
lib/core/error/exception_mapper.dart
```

### Validation Errors — HTTP 422

FastAPI can return field-level validation errors with status code `422 Unprocessable Entity`.

The documented helper:

```dart
extractValidationErrors(error)
```

parses validation errors into a structure of this form:

```dart
Map<String, List<String>>
```

The resulting field-specific messages can then be displayed in the relevant form.

---

## Troubleshooting

### `NO ROUTESETUP` or `No route defined for X`

The requested route may not be registered.

Check:

- `lib/core/router/routes.dart`
- `lib/core/router/app_router.dart`

Verify that the route constant exists and that a matching route is registered.

### `Duplicate fullpaths for name X`

Two routes may share the same path or name.

Inspect `app_router.dart` and check for duplicate route paths and names.

### An Event Handler Runs Multiple Times

Check the relevant BLoC constructor for duplicate event-handler registrations.

Also verify that the BLoC is not being created or registered more often than intended.

### API Requests Return `401 Unauthorized`

Check the following:

- The user is authenticated.
- The access token is present and has not expired.
- The request includes the expected authorization header.
- The backend accepts the token.
- The authentication interceptor is configured correctly.
- The endpoint is not incorrectly included in an authentication-interceptor exclusion list.

### Push Notifications Do Not Arrive

Verify the following:

- `google-services.json` exists in `android/app/` for Android builds.
- The Android application ID matches the Firebase registration.
- The backend Firebase credentials refer to the same Firebase project.
- Notification permissions have been granted where required.
- The device's FCM token has been synchronized with the backend.
- The notification payload and platform configuration support the expected delivery behavior.
- The local notification channel is configured correctly.

The documented Android channel ID is:

```text
dentspace_channel
```

Verify the actual channel ID in both the Flutter application and backend.

### Images Do Not Load

Check the following:

- The image URL is valid and accessible.
- HTTPS is used where required.
- The backend or image provider returns the expected image format.
- Network access and image-provider permissions are configured correctly.
- Cached image data is not stale or invalid.

If image validation relies on file signatures, ensure the bytes match the expected image format.

### Hive Box Fails to Open

Verify that Hive initialization runs before dependencies or services attempt to access the cache.

The expected initialization sequence should be consistent with:

```dart
HiveInitializer.init();
configureDependencies();
```

The exact method signatures and initialization order must match the actual project implementation.

If a cache schema changes, review the box and cache-key versioning strategy before reusing older persisted data.

---

