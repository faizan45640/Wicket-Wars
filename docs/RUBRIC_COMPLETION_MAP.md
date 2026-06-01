# Wicket Wars Rubric Completion Map

## Complete App GUI
- Main screens: `lib/screens/home_screen.dart`, `lib/screens/squad_screen.dart`, `lib/screens/online_match_screen.dart`, `lib/screens/live_match_screen.dart`, `lib/screens/profile_screen.dart`.
- Card UI and reward UI: `lib/widgets/player_fifa_card_dialog.dart`, `lib/widgets/daily_reward_dialog.dart`.

## Firebase Authentication & DB
- Firebase Auth repositories: `lib/data/repositories/firebase_auth_repository.dart`.
- Firestore repositories: `lib/data/repositories/firebase_user_repository.dart`, `lib/data/repositories/firebase_squad_repository.dart`, `lib/data/repositories/firebase_match_repository.dart`.
- Backend Cloud Functions: `functions/index.js`.

## Security: Encryption & Decryption
- AES password encrypt/decrypt demonstration: `lib/auth/password_crypto.dart`.
- Login/signup encrypt then decrypt before Firebase Auth API call: `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart`.

## App Architecture and Code Organization
- Models: `lib/data/models/`.
- Repository interfaces: `lib/data/repositories/`.
- Firebase and placeholder implementations are separated.
- Providers and dependency wiring: `lib/data/providers.dart`.
- Routing: `lib/app_router.dart`.

## External REST API Integration Other Than Firebase
- Google AI REST call via `fetch` in Cloud Functions: `functions/index.js`.
- Used for match commentary/player generation attempts with local fallback.

## Profiling
- Timeline profiling helper: `lib/services/app_profiler.dart`.
- Bootstrap trace: `lib/main.dart`.

## Logging and Debugging
- Central logger: `lib/services/app_logger.dart`.
- Used by startup services, ads, background task, and AI fallback logging.

## Notifications and Event Handling
- Local notification service: `lib/services/local_notification_service.dart`.
- Daily reward claim emits a notification event: `lib/widgets/daily_reward_dialog.dart`.

## Background Tasks, Services, and Threading
- Periodic Workmanager task registration: `lib/services/background_training_service.dart`.
- Initialized during app startup: `lib/main.dart`.

## Permissions
- Notification, wake lock, boot, and internet permissions: `android/app/src/main/AndroidManifest.xml`.
- Runtime notification permission request: `lib/services/local_notification_service.dart`.

## Advertisement / Monetization Integration
- Google Mobile Ads initialization: `lib/services/ads_service.dart`.
- Test banner widget: `lib/widgets/monetization_banner.dart`.
- Home screen ad placement: `lib/screens/home_screen.dart`.
- Android AdMob test app id: `android/app/src/main/AndroidManifest.xml`.

## Flutter Installation
- Project is a Flutter app with `pubspec.yaml`, Android/iOS/macOS/Windows folders, and passing `flutter analyze` / `flutter test`.
