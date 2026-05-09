// Generated from android/app/google-services.json for Android.
// For iOS, web, or desktop, run: dart pub global activate flutterfire_cli && flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Wicket Wars.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Configure a web app in Firebase Console, then run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Add an Apple app in Firebase Console, then run flutterfire configure.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Run flutterfire configure for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKi9jziC79vWKbUUHH0uHcU1qiFC4B1ec',
    appId: '1:319913157269:android:dbb928596c3cf79addf19c',
    messagingSenderId: '319913157269',
    projectId: 'wicket-wars-d45a0',
    storageBucket: 'wicket-wars-d45a0.firebasestorage.app',
  );
}
