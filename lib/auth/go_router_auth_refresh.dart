import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Drives [GoRouter] redirects when the Firebase session changes.
final goRouterAuthRefresh = GoRouterAuthRefresh();

final class GoRouterAuthRefresh extends ChangeNotifier {
  StreamSubscription<User?>? _sub;

  /// Call once after [Firebase.initializeApp].
  void listenToAuth() {
    _sub ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
