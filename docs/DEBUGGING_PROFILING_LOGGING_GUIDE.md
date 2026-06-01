# Debugging, Profiling, and Logs Guide

Use this during viva to show that Wicket Wars has proper debugging, profiling,
and logging instead of only `print()` statements.

## What Is Implemented

- Central app logger: `lib/services/app_logger.dart`
- Timeline profiler helper: `lib/services/app_profiler.dart`
- Riverpod provider observer: `lib/services/app_provider_observer.dart`
- Global Flutter/platform/zone error capture: `lib/main.dart`
- Backend Firebase Functions logs: `functions/index.js`

## Show Flutter Debugger

1. Open the project in VS Code or Android Studio.
2. Put a breakpoint in a screen or repository, for example:
   - `lib/screens/home_screen.dart`
   - `lib/data/repositories/firebase_match_repository.dart`
   - `lib/data/repositories/firebase_squad_repository.dart`
3. Run the app in debug mode:

```bash
flutter run
```

4. Trigger the feature in the app.
5. Show the teacher variables, call stack, provider state, and step-over/step-in.

Viva line:

> The app supports real Flutter debugging with breakpoints, call stack
> inspection, and runtime variable inspection.

## Show App Logs

Run the app and watch logs in the terminal:

```bash
flutter run
```

Useful log examples to show:

- `event:app_start`
- `event:firebase_initialized`
- `app_bootstrap completed in ...ms`
- `provider:add ...`
- `provider:update ...`
- Ad loading logs
- Notification/background task logs

For an already running Android device:

```bash
flutter logs
```

Android native logs can also be filtered:

```bash
adb logcat | rg WicketWars
```

Viva line:

> The app uses a central `AppLogger` based on `dart:developer`, so logs appear
> in Flutter tooling, Android logs, and debug console output.

## Show Profiling

Run in profile mode:

```bash
flutter run --profile
```

Open Flutter DevTools from the link shown in the terminal, then show:

- Performance timeline
- CPU profiler
- Memory tab
- Network tab if Firebase/API calls are running

The app records `TimelineTask` profiling labels through `AppProfiler`, including:

- `app_bootstrap`

Viva line:

> I used Flutter DevTools plus a custom `AppProfiler` wrapper around
> `TimelineTask` and `Stopwatch`, so important app flows can be measured in both
> timeline view and logs.

## Show Error Handling

The app captures:

- Flutter framework errors through `FlutterError.onError`
- Platform async errors through `PlatformDispatcher.instance.onError`
- Uncaught zone errors through `runZonedGuarded`
- Riverpod provider failures through `AppProviderObserver.providerDidFail`

Viva line:

> Runtime errors are centrally captured and logged instead of being silently lost.

## Show Backend Logs

For Firebase Functions:

```bash
npx firebase-tools functions:log --only openStarterPack --lines 80
```

Other useful commands:

```bash
npx firebase-tools functions:log --lines 100
```

Viva line:

> Backend events and failures can be inspected from Firebase Functions logs.

## Rubric Mapping

- Profiling: Flutter DevTools, profile mode, `AppProfiler`, timeline tasks
- Logging and Debugging: `AppLogger`, debugger breakpoints, provider observer
- Event Handling: provider observer, auth refresh, notifications, room streams
- Background Tasks: `BackgroundTrainingService`
- Notifications: `LocalNotificationService`

