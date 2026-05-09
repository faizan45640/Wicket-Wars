import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';

/// Typed entry points for Firestore paths (like table names in SQL, but nested).
extension WicketWarsFirestore on FirebaseFirestore {
  DocumentReference<Map<String, dynamic>> userDocument(String uid) =>
      collection(FirestorePaths.users).doc(uid);

  CollectionReference<Map<String, dynamic>> userPlayers(String uid) =>
      userDocument(uid).collection('players');

  CollectionReference<Map<String, dynamic>> userMatchHistory(String uid) =>
      userDocument(uid).collection('matchHistory');

  DocumentReference<Map<String, dynamic>> matchRoomDocument(String roomId) =>
      collection(FirestorePaths.matchRooms).doc(roomId);

  CollectionReference<Map<String, dynamic>> leaderboardCollection() =>
      collection(FirestorePaths.leaderboard);
}
