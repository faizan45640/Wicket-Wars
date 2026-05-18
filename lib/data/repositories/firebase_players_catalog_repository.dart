import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_codec.dart';
import '../firestore/firestore_refs.dart';
import '../models/catalog_player.dart';
import 'players_catalog_repository.dart';

class FirebasePlayersCatalogRepository implements PlayersCatalogRepository {
  FirebasePlayersCatalogRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CatalogPlayer _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final decoded = decodeFirestoreMap(doc.data());
    decoded['id'] = decoded['id'] ?? doc.id;
    return CatalogPlayer.fromMap(decoded);
  }

  @override
  Stream<List<CatalogPlayer>> watchCatalog() {
    return _db.playersCatalog().snapshots().map(
          (snap) => snap.docs.map(_fromDoc).toList(),
        );
  }
}
