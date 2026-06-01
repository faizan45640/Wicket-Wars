# Wicket Wars Viva Rubric Demo Guide

Use this file during viva to quickly show each marking point. Keep the app running on the Pixel/device and keep the project open in VS Code/Android Studio.

## 1. Complete App GUI

What to show:
- Open the app and show login/signup.
- Sign in and show Home, Squad, Online Match, Leaderboard, Profile, Starter Pack, and Live Match screens.
- Show player cards, daily reward dialog, squad grid, and match lobby.

Code/files to open:
- `lib/screens/home_screen.dart`
- `lib/screens/squad_screen.dart`
- `lib/screens/online_match_screen.dart`
- `lib/screens/live_match_screen.dart`
- `lib/widgets/player_fifa_card_dialog.dart`

What to say:
> The app has complete game screens, navigation, responsive lists/cards, squad management, online match lobby, live match view, rewards, leaderboard, and profile.

## 2. Firebase Authentication & DB

What to show:
- Create a new account or log in.
- Open Firebase Console and show Authentication users.
- Show Firestore collections: `users`, `users/{uid}/players`, `leaderboard`, `matchRooms`.

Code/files to open:
- `lib/data/repositories/firebase_auth_repository.dart`
- `lib/data/repositories/firebase_user_repository.dart`
- `lib/data/repositories/firebase_squad_repository.dart`
- `lib/data/repositories/firebase_match_repository.dart`
- `functions/index.js`

What to say:
> Authentication is handled by Firebase Auth. User profiles, squads, leaderboard, match rooms, and match history are stored in Firestore. Real-time match updates use Firestore streams.

## 3. Security: Encryption & Decryption

What to show:
- Open login/signup code.
- Show password encryption before calling Firebase Auth.

Code/files to open:
- `lib/auth/password_crypto.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/signup_screen.dart`

What to say:
> I implemented AES encryption/decryption helpers. Firebase Auth still requires the original password, so the app encrypts in memory and decrypts immediately before calling Firebase. This demonstrates symmetric encryption and decryption in the auth flow.

## 4. App Architecture and Code Organization

What to show:
- Show project folders: `models`, `repositories`, `placeholder`, `screens`, `widgets`, `services`.
- Explain repository pattern.

Code/files to open:
- `lib/data/models/`
- `lib/data/repositories/`
- `lib/data/providers.dart`
- `lib/app_router.dart`

What to say:
> The app separates UI, models, repositories, Firebase implementations, placeholder/local implementations, services, and routing. Riverpod providers wire dependencies cleanly.

## 5. External REST API Integration Other Than Firebase

What to show:
- Open Cloud Functions AI call code.
- Explain Google AI REST call and fallback.

Code/files to open:
- `functions/index.js`

What to say:
> The backend calls Google AI using a REST `fetch` request for commentary/player generation. If the AI request fails or times out, the app uses deterministic fallback data so gameplay still works.

## 6. Profiling

What to show:
- Open profiler helper.
- Show startup profiling in `main.dart`.
- Run the app in profile mode and open Flutter DevTools.

Code/files to open:
- `lib/services/app_profiler.dart`
- `lib/main.dart`
- `docs/DEBUGGING_PROFILING_LOGGING_GUIDE.md`

What to say:
> I added a profiling helper using `TimelineTask` and stopwatch timing. It traces app bootstrap and logs elapsed time, and the same run can be inspected in Flutter DevTools Performance and CPU profiler tabs.

## 7. Logging and Debugging

What to show:
- Open central logger.
- Run the app and show debug console logs.
- Put a breakpoint in a repository or screen and inspect variables.
- Show Riverpod provider lifecycle logs in debug mode.

Code/files to open:
- `lib/services/app_logger.dart`
- `lib/services/app_provider_observer.dart`
- `lib/main.dart`
- `functions/index.js`

What to say:
> The app has a central logging helper using `dart:developer` and `debugPrint`, global error capture, and Riverpod provider lifecycle logs. Backend functions also log AI fallback reasons and function events.

## 8. Notifications and Event Handling

What to show:
- Claim daily reward.
- Show notification permission prompt or resulting notification.

Code/files to open:
- `lib/services/local_notification_service.dart`
- `lib/widgets/daily_reward_dialog.dart`

What to say:
> The app requests notification permission and triggers a local notification when a daily reward is claimed. This demonstrates app event handling and notification integration.

## 9. Background Tasks, Services, and Threading

What to show:
- Open background service code.
- Explain periodic Workmanager task.

Code/files to open:
- `lib/services/background_training_service.dart`
- `lib/main.dart`

What to say:
> I integrated Workmanager and registered a periodic background task for training refresh. The task runs outside the normal UI flow and logs when executed.

## 10. Permissions

What to show:
- Open Android manifest.
- Show runtime notification permission service.

Code/files to open:
- `android/app/src/main/AndroidManifest.xml`
- `lib/services/local_notification_service.dart`

What to say:
> Android permissions are declared for internet, notifications, wake lock, and boot completion. Notification permission is requested at runtime through `permission_handler`.

## 11. Advertisement / Monetization Integration

What to show:
- Open Home/Squad/Profile/Leaderboard/Online Match and point to ad slots.
- Explain test AdMob banner id.

Code/files to open:
- `lib/services/ads_service.dart`
- `lib/widgets/monetization_banner.dart`
- `lib/screens/home_screen.dart`
- `android/app/src/main/AndroidManifest.xml`

What to say:
> I integrated Google Mobile Ads with the official test banner unit. Test ad slots are placed in natural empty spaces across the app.

## 12. Flutter Installation

What to show:
- Run these commands in terminal:

```bash
flutter --version
flutter pub get
flutter analyze
flutter test
```

What to say:
> The project is a Flutter application with Android support, dependencies managed in `pubspec.yaml`, and it passes analyzer/tests.

## Quick Demo Flow

1. Run app on Pixel/device.
2. Sign up or log in.
3. Open starter pack/squad.
4. Claim daily reward and show notification.
5. Open Online Match and create a room.
6. Show Leaderboard and Profile.
7. Show ad banners in Home/Squad/Profile/Leaderboard/Online Match.
8. Open Firebase Console and show Auth + Firestore collections.
9. Open code files from this guide for encryption, logging, profiling, notifications, background tasks, ads, and rules.

## Useful Verification Commands

```bash
flutter pub get
flutter analyze
flutter test
npx firebase-tools deploy --only firestore:rules
```

## Notes for Questions

- If asked about real-time multiplayer: room state is stored in Firestore `matchRooms`; both clients listen to the same room stream.
- If asked about security: clients cannot directly create/update/delete match rooms; match logic is backend-authoritative through Cloud Functions.
- If asked about AI fallback: Google AI is called from Cloud Functions, but deterministic fallback keeps the app usable if the model/API is unavailable.
- If asked about ads: test AdMob IDs are used because production ad IDs require a real AdMob account and app review.
