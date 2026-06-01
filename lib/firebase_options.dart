// Firebase configuration for Android and Web.
// For iOS or desktop, run: dart pub global activate flutterfire_cli && flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Wicket Wars.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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
        throw UnsupportedError('Run flutterfire configure for this platform.');
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-McP_o46PEEhr7EcZnz13ecvxZpx8On8',
    appId: '1:319913157269:web:91aea86cbbee282dddf19c',
    messagingSenderId: '319913157269',
    projectId: 'wicket-wars-d45a0',
    authDomain: 'wicket-wars-d45a0.firebaseapp.com',
    storageBucket: 'wicket-wars-d45a0.firebasestorage.app',
    measurementId: 'G-RP1J8HL4BF',
  );
}
