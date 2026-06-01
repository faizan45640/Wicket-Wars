import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_environment.dart';
import 'models/app_user.dart';
import 'models/catalog_player.dart';
import 'models/cricket_player.dart';
import 'models/leaderboard_entry.dart';
import 'models/match_room.dart';
import 'models/match_summary.dart';
import 'models/user_profile.dart';
import 'placeholder/placeholder_auth_repository.dart';
import 'placeholder/placeholder_leaderboard_repository.dart';
import 'placeholder/placeholder_match_history_repository.dart';
import 'placeholder/placeholder_match_repository.dart';
import 'placeholder/placeholder_players_catalog_repository.dart';
import 'placeholder/placeholder_squad_repository.dart';
import 'placeholder/placeholder_user_repository.dart';
import 'repositories/firebase_leaderboard_repository.dart';
import 'repositories/firebase_players_catalog_repository.dart';
import 'repositories/firebase_match_history_repository.dart';
import 'repositories/firebase_match_repository.dart';
import 'repositories/firebase_squad_repository.dart';
import 'repositories/firebase_user_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/leaderboard_repository.dart';
import 'repositories/match_history_repository.dart';
import 'repositories/match_repository.dart';
import 'repositories/players_catalog_repository.dart';
import 'repositories/squad_repository.dart';
import 'repositories/user_repository.dart';

final _firebaseAuthRepository = FirebaseAuthRepository();
final _firebaseUserRepository = FirebaseUserRepository();
final _firebaseSquadRepository = FirebaseSquadRepository();
final _firebaseMatchRepository = FirebaseMatchRepository();
final _firebaseLeaderboardRepository = FirebaseLeaderboardRepository();
final _firebaseMatchHistoryRepository = FirebaseMatchHistoryRepository();
final _firebasePlayersCatalogRepository = FirebasePlayersCatalogRepository();

final _placeholderAuthRepository = PlaceholderAuthRepository();
final _placeholderUserRepository = PlaceholderUserRepository();
final _placeholderSquadRepository = PlaceholderSquadRepository();
final _placeholderMatchRepository = PlaceholderMatchRepository();
final _placeholderLeaderboardRepository = PlaceholderLeaderboardRepository();
final _placeholderMatchHistoryRepository = PlaceholderMatchHistoryRepository();
final _placeholderPlayersCatalogRepository =
    PlaceholderPlayersCatalogRepository();

AuthRepository activeAuthRepository() {
  return AppEnvironment.useFirebase
      ? _firebaseAuthRepository
      : _placeholderAuthRepository;
}

/// Uses Firebase in production, and the local in-memory implementation when
/// Firebase is unavailable for the current platform.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return activeAuthRepository();
});

/// Data layer: production uses [FirebaseUserRepository], [FirebaseSquadRepository], etc.
/// In widget tests, override these providers with `Placeholder*` repositories so Firestore
/// is not required (see `test/widget_test.dart`).
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return AppEnvironment.useFirebase
      ? _firebaseUserRepository
      : _placeholderUserRepository;
});

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  return AppEnvironment.useFirebase
      ? _firebaseSquadRepository
      : _placeholderSquadRepository;
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return AppEnvironment.useFirebase
      ? _firebaseMatchRepository
      : _placeholderMatchRepository;
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return AppEnvironment.useFirebase
      ? _firebaseLeaderboardRepository
      : _placeholderLeaderboardRepository;
});

final matchHistoryRepositoryProvider = Provider<MatchHistoryRepository>((ref) {
  return AppEnvironment.useFirebase
      ? _firebaseMatchHistoryRepository
      : _placeholderMatchHistoryRepository;
});

final playersCatalogRepositoryProvider = Provider<PlayersCatalogRepository>((
  ref,
) {
  return AppEnvironment.useFirebase
      ? _firebasePlayersCatalogRepository
      : _placeholderPlayersCatalogRepository;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

final currentUidProvider = Provider<String?>((ref) {
  final userFromStream = ref.watch(authStateProvider).valueOrNull;
  return userFromStream?.uid ??
      ref.watch(authRepositoryProvider).currentUser?.uid;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(uid);
});

final squadProvider = StreamProvider.family<List<CricketPlayer>, String>((
  ref,
  uid,
) {
  return ref.watch(squadRepositoryProvider).watchSquad(uid);
});

final leaderboardTopProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchTop(limit: 50);
});

final matchHistoryProvider = StreamProvider.family<List<MatchSummary>, String>((
  ref,
  uid,
) {
  return ref.watch(matchHistoryRepositoryProvider).watchRecent(uid);
});

/// Live room stream — replace with Firestore snapshots in real impl.
final matchRoomProvider = StreamProvider.family<MatchRoom?, String>((
  ref,
  roomId,
) {
  return ref.watch(matchRepositoryProvider).watchRoom(roomId);
});

final playersCatalogProvider = StreamProvider<List<CatalogPlayer>>((ref) {
  return ref.watch(playersCatalogRepositoryProvider).watchCatalog();
});
