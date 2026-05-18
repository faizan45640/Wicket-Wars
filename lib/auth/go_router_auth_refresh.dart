import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

/// Drives [GoRouter] redirects when the auth session changes.
final goRouterAuthRefresh = GoRouterAuthRefresh();

final class GoRouterAuthRefresh extends ChangeNotifier {
  StreamSubscription<AppUser?>? _sub;
  AuthRepository? _authRepository;

  void listenToAuth(AuthRepository authRepository) {
    if (identical(_authRepository, authRepository) && _sub != null) return;
    _sub?.cancel();
    _authRepository = authRepository;
    _sub = authRepository.watchAuthState().listen((_) {
      notifyListeners();
    });
  }

  bool get isSignedIn => _authRepository?.currentUser != null;

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
