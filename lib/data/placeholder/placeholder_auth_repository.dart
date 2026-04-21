import 'dart:async';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'in_memory_store.dart';

class PlaceholderAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  PlaceholderAuthRepository() {
    InMemoryStore.instance.ensureInitialized();
    _user = AppUser(uid: InMemoryStore.demoUid, email: 'demo@wicketwars.local');
    _controller.add(_user);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInPlaceholder() async {
    _user = AppUser(uid: InMemoryStore.demoUid, email: 'demo@wicketwars.local');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;
}
