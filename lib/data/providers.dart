import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_user.dart';
import 'models/cricket_player.dart';
import 'models/leaderboard_entry.dart';
import 'models/match_room.dart';
import 'models/match_summary.dart';
import 'models/user_profile.dart';
import 'placeholder/placeholder_auth_repository.dart';
import 'placeholder/placeholder_leaderboard_repository.dart';
import 'placeholder/placeholder_match_history_repository.dart';
import 'placeholder/placeholder_match_repository.dart';
import 'placeholder/placeholder_squad_repository.dart';
import 'placeholder/placeholder_user_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/leaderboard_repository.dart';
import 'repositories/match_history_repository.dart';
import 'repositories/match_repository.dart';
import 'repositories/squad_repository.dart';
import 'repositories/user_repository.dart';

/// Swap these for `Firebase*` implementations after `flutterfire configure`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return PlaceholderAuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return PlaceholderUserRepository();
});

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  return PlaceholderSquadRepository();
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return PlaceholderMatchRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return PlaceholderLeaderboardRepository();
});

final matchHistoryRepositoryProvider = Provider<MatchHistoryRepository>((ref) {
  return PlaceholderMatchHistoryRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(uid);
});

final squadProvider = StreamProvider.family<List<CricketPlayer>, String>((ref, uid) {
  return ref.watch(squadRepositoryProvider).watchSquad(uid);
});

final leaderboardTopProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchTop(limit: 50);
});

final matchHistoryProvider =
    StreamProvider.family<List<MatchSummary>, String>((ref, uid) {
  return ref.watch(matchHistoryRepositoryProvider).watchRecent(uid);
});

/// Live room stream — replace with Firestore snapshots in real impl.
final matchRoomProvider = StreamProvider.family<MatchRoom?, String>((ref, roomId) {
  return ref.watch(matchRepositoryProvider).watchRoom(roomId);
});
