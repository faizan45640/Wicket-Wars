import 'package:cloud_firestore/cloud_firestore.dart';

/// Turns Firestore [Timestamp] values into UTC ISO-8601 strings so existing
/// [fromMap] factories (written for JSON-style strings) keep working.
dynamic firestoreDecode(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), firestoreDecode(v)));
  }
  if (value is Iterable) {
    return value.map(firestoreDecode).toList();
  }
  return value;
}

Map<String, dynamic> decodeFirestoreMap(Map<String, dynamic> data) {
  final out = firestoreDecode(data);
  return Map<String, dynamic>.from(out as Map);
}
