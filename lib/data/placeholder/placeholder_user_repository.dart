import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import 'in_memory_store.dart';

class PlaceholderUserRepository implements UserRepository {
  final InMemoryStore _store = InMemoryStore.instance;

  PlaceholderUserRepository() {
    _store.ensureInitialized();
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    if (uid == InMemoryStore.demoUid) return _store.demoProfile;
    return null;
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    if (profile.uid == InMemoryStore.demoUid) {
      _store.demoProfile = profile;
    }
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield await getProfile(uid);
  }
}
