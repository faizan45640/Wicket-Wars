# Wicket Wars — Viva Rubric Demo Guide

Use this during the viva to demo each marking point fast. Keep two things ready:

1. The app **running on the Pixel/device** — ideally started with `flutter run` so you have the **debug console** + **DevTools** link in the terminal.
2. The **project open in the editor** so you can jump to the exact file for each item.

> Tip: when `flutter run` starts it prints a line like
> `A Dart VM Service ... is available at: http://127.0.0.1:9101/...`
> and `The Flutter DevTools debugger and profiler is available at: http://127.0.0.1:9100?uri=...`.
> Keep that DevTools URL handy — you'll use it for **Profiling** and **Logging**.

Marks per item (total 35): GUI 5 · Auth/DB 4 · Encryption 2 · Architecture 4 · REST API 3 · Profiling 3 · Logging/Debugging 2 · Notifications 3 · Background 3 · Permissions 2 · Ads 3 · Flutter install 1.

---

## 1. Complete App GUI — 5

**Show:** login/signup → Home → Squad → Online Match lobby → Live Match (LIVE / Commentary / Scorecard tabs) → Leaderboard → Profile → Starter Pack. Open a player card and the daily-reward dialog.

**Open:**
- `lib/screens/home_screen.dart`
- `lib/screens/squad_screen.dart`
- `lib/screens/online_match_screen.dart`
- `lib/screens/live_match_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/widgets/player_fifa_card_dialog.dart`

**Say:** "Full game UI — auth, home hub, squad management, online lobby, a real-match-style live screen with scoreboard/commentary/scorecard tabs, leaderboard, profile, and animated loading overlays."

---

## 2. Firebase Authentication & DB — 4

**Show:** create/log in an account → Firebase Console → **Authentication** users; **Firestore** collections `users`, `users/{uid}/players`, `leaderboard`, `matchRooms`.

**Open:**
- `lib/data/repositories/firebase_auth_repository.dart`
- `lib/data/repositories/firebase_user_repository.dart`
- `lib/data/repositories/firebase_squad_repository.dart`
- `lib/data/repositories/firebase_match_repository.dart`
- `functions/index.js` · `firestore.rules`

**Say:** "Firebase Auth for sign-in; Firestore for profiles, squads, leaderboard, match rooms and history. Match writes are backend-authoritative through Cloud Functions, and clients listen to room streams for real-time updates."

---

## 3. Security: Encryption & Decryption — 2

**Show:** `password_crypto.dart`, then the call sites where login/signup encrypt then decrypt right before the Firebase Auth call.

**Open:**
- `lib/auth/password_crypto.dart`
- `lib/screens/login_screen.dart` (`_submit`) · `lib/screens/signup_screen.dart` (`_submit`)

**Say:** "AES-256 symmetric encryption with a per-call random IV. Firebase Auth only accepts plaintext over TLS, so I encrypt in memory and decrypt immediately before the call — this demonstrates encrypt+decrypt in the real auth flow. In production the key would live in Keystore/Keychain or a KMS, not in source."

---

## 4. App Architecture and Code Organization — 4

**Show:** folder layout and the repository pattern (interface + `firebase_*` impl + `placeholder_*` impl), Riverpod wiring, routing.

**Open:**
- `lib/data/models/` · `lib/data/repositories/` · `lib/data/placeholder/`
- `lib/data/providers.dart` · `lib/app_router.dart` · `lib/app_environment.dart`

**Say:** "Clean layering: models, repository interfaces, swappable Firebase vs local implementations, Riverpod providers for DI, and `go_router` for navigation. `AppEnvironment` lets the app fall back to in-memory data if Firebase is unavailable."

---

## 5. External REST API Integration (non-Firebase) — 3

**Show:** the `fetch` REST calls in Cloud Functions to Hugging Face and Google Generative Language, with provider fallback.

**Open:**
- `functions/index.js` — search for `HUGGING_FACE_CHAT_URL` and `generativelanguage.googleapis.com`.

**Say:** "The backend makes raw REST `fetch` calls to the Hugging Face router API for commentary/player generation, falls back to Google AI, then to deterministic data so gameplay never breaks. Keys are stored as Cloud Function secrets, not in code."

> If asked to prove it live: keys are set with `firebase functions:secrets:set HUGGING_FACE_TOKEN`. Without keys it silently uses the deterministic fallback (still correct behaviour).

---

## 6. Profiling — 3  ⭐ (examiners probe this)

We profile two ways: **(a) our own timed traces in code**, and **(b) Flutter DevTools**.

**Open first:**
- `lib/services/app_profiler.dart` — `AppProfiler.trace()` wraps work in a `TimelineTask` **and** a `Stopwatch`, logging elapsed ms and emitting a Timeline event.
- `lib/main.dart` — bootstrap is wrapped: `AppProfiler.trace('app_bootstrap', () async { … ads/notifications/background init … })`.

**Demo A — see the timing in logs (easiest):**
1. App is running via `flutter run`.
2. In the debug console you'll see `[INFO] app_bootstrap completed in <N>ms` from the profiler. That's our instrumentation timing a real code path.

**Demo B — Flutter DevTools Performance/Timeline (the "real" profiler):**
1. Open the **DevTools URL** printed by `flutter run` (or run `flutter pub global run devtools` and paste the VM Service URI).
2. Go to the **Performance** tab → enable **Track Widget Builds** → interact with the app (open Squad, scroll). You'll see the frame chart; point out frames staying under the 16ms (60fps) budget.
3. In the **Timeline / Timeline Events**, search for **`app_bootstrap`** — our `TimelineTask` label appears as a named slice, proving custom instrumentation lines up with the platform timeline.
4. Open the **CPU Profiler** tab, record while doing an action, and show the flame chart of hot methods.
5. (Optional, most accurate) Restart in profile mode: `flutter run --profile`, which disables debug asserts so timings are representative.

**Say:** "I instrument key paths with a `TimelineTask` + `Stopwatch` helper so every traced operation both logs its duration and shows up as a named slice in the DevTools Timeline. Then I use DevTools Performance, Timeline Events and the CPU Profiler to inspect frame times and hot code. `app_bootstrap` is the slice to look for."

---

## 7. Logging and Debugging — 2  ⭐

**Open first:**
- `lib/services/app_logger.dart` — central logger: `debug/info/warning/error` + structured `event(name, data)`; writes via `dart:developer log(name: 'WicketWars')` and `debugPrint`.
- `lib/services/app_provider_observer.dart` — Riverpod `ProviderObserver` that logs provider add/update/dispose/fail.
- `lib/main.dart` — global crash capture: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and a `runZonedGuarded` wrapper, plus `AppLogger.event('app_start')` / `'firebase_initialized'`.

**Demo — view logs:**
1. With `flutter run` active, watch the **debug console**: you'll see `[INFO] event:app_start`, `[INFO] app_bootstrap completed in …ms`, `[INFO] event:firebase_initialized`, provider lifecycle lines, and ads/notification init logs.
2. Filter: in DevTools open the **Logging** tab and filter by the `WicketWars` source, or in a terminal run `flutter logs`.
3. **Breakpoint demo:** set a breakpoint in `firebase_user_repository.dart` `upsertProfile` (or any `_submit`), trigger it from the UI, and inspect variables / call stack in the debugger.
4. **Structured events:** point out `event:bg_task_run` and `event:bg_energy_notified` from the background task (item 9) — proof the logger captures custom domain events with key/value data.

**Say:** "One logger with levels and structured events, routed through `dart:developer` so it's filterable by the `WicketWars` source in DevTools. Global handlers catch framework, platform and zone errors. A Riverpod observer logs provider lifecycle. For debugging I use breakpoints + the variable/call-stack inspector."

---

## 8. Notifications and Event Handling — 3

**Show:** claim the daily reward → notification fires; mention scheduled reminders for daily-reward unlock and training-energy-full.

**Open:**
- `lib/services/local_notification_service.dart` — `show…`, `scheduleDailyRewardUnlock`, `scheduleTrainingEnergyFull` (timezone-aware `zonedSchedule`), and `showTrainingEnergyFullNow` (used by the background task).
- `lib/widgets/daily_reward_dialog.dart` — claim emits a notification event.

**Say:** "Local notifications via `flutter_local_notifications` + `timezone`. Immediate notifications on reward claim, and scheduled zoned reminders for the next daily reward and when training energy refills."

---

## 9. Background Tasks, Services, and Threading — 3  (newly hardened)

**Show & explain the real work the task does now:**
- `lib/services/background_training_service.dart` — registers a periodic `Workmanager` task (15-min). The `@pragma('vm:entry-point')` callback runs in a **separate isolate** and:
  1. **Records proof of run** (timestamp + run counter) via `TrainingReminderStore`.
  2. Reads the persisted **energy-full time**; if energy has finished recharging and a reminder is still pending, it **delivers the "training energy full" notification itself** — a backstop in case the exact-time alarm was dropped because the app was killed.
  3. Logs `event:bg_task_run` / `event:bg_energy_notified`.
- `lib/services/training_reminder_store.dart` — `SharedPreferences` bridge between the UI isolate and the background isolate.
- `lib/screens/player_detail_screen.dart` — when you train a player, `_scheduleEnergyReminder` persists the energy-full time for the background task.
- `lib/main.dart` — task registered during bootstrap.

**Demo:** train a player, then background the app. In the debug console you'll see `event:bg_task_run` lines when the task fires; when energy completes you get the notification even if the app isn't foregrounded.

**Say:** "Workmanager runs a periodic task on a background isolate. Because that isolate has no Riverpod/Firebase context, it talks to the app through SharedPreferences: it logs each run for observability and delivers the energy-full reminder as a backstop. This shows background services + threading (separate isolate) + inter-isolate state."

---

## 10. Permissions — 2

**Open:**
- `android/app/src/main/AndroidManifest.xml` — `INTERNET`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` + the `flutter_local_notifications` boot/scheduled receivers.
- `lib/services/local_notification_service.dart` — `requestPermission()` via `permission_handler` (runtime POST_NOTIFICATIONS prompt on Android 13+).

**Say:** "Declared the needed manifest permissions and request notification permission at runtime; boot/wake-lock support lets scheduled reminders survive reboots."

---

## 11. Advertisement / Monetization Integration — 3

> Note: ads are intentionally **only on the Home screen** now (cleaner UX); other screens use the plain bottom nav.

**Show:** Home screen banner in the bottom slot.

**Open:**
- `lib/services/ads_service.dart` — `MobileAds.instance.initialize()` + official test banner unit.
- `lib/widgets/monetization_banner.dart` · `lib/services/rewarded_ad_helper.dart`
- `lib/screens/home_screen.dart` — banner placement.
- `android/app/src/main/AndroidManifest.xml` — AdMob `APPLICATION_ID` (test).

**Say:** "Google Mobile Ads with the official test IDs — a banner on Home and a rewarded-ad helper. Test IDs are used because production IDs need a reviewed AdMob account."

---

## 12. Flutter Installation — 1

**Run:**
```bash
flutter --version
flutter pub get
flutter analyze   # → No issues found!
flutter test
```

**Say:** "Standard Flutter project with Android support; dependencies in `pubspec.yaml`; analyzer is clean."

---

## Quick Demo Flow

1. Start with `flutter run` (keep console + DevTools link).
2. Sign up / log in → show Auth + Firestore in Firebase Console.
3. Open starter pack / squad; train a player (sets up the background reminder).
4. Claim daily reward → notification fires.
5. Create an online room → show Live Match tabs.
6. Show Leaderboard + Profile; Home banner ad.
7. **Profiling:** DevTools → Performance + Timeline (`app_bootstrap`).
8. **Logging:** debug console events (`app_start`, `bg_task_run`) + a breakpoint.

## Useful Commands
```bash
flutter analyze
flutter test
flutter run --profile          # representative profiling
npx firebase-tools deploy --only firestore:rules
```

## Likely Questions
- **Real-time multiplayer?** Room state in Firestore `matchRooms`; both clients stream the same doc; per-delivery choices use a two-sided handshake with a deadline.
- **Security?** Clients can't mutate match rooms directly — Cloud Functions are authoritative; Firestore rules restrict writes to owners.
- **AI fallback?** Hugging Face REST first → Google AI → deterministic data.
- **Background task scope?** Periodic (Android min 15 min), runs on its own isolate, communicates via SharedPreferences, and delivers the energy-full reminder as a backstop.
- **Encryption realism?** Demo of symmetric encrypt/decrypt; real password still needed by Firebase, so we decryp
t before the call.