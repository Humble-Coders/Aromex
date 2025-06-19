import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  // static Future<List<T>> getAll<T>(
  //   T Function(DocumentSnapshot snapshot) fromFirestore,
  //   String collection,
  // ) async {
  //   QuerySnapshot snapshot =
  //       await FirebaseFirestore.instance.collection(collection).get();
  //   return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  // }

  static Future<List<T>> getAll<T>(
    T Function(DocumentSnapshot snapshot) fromFirestore,
    CollectionReference collectionRef, {
    Map<String, dynamic>? whereIsEqualClause,
    String? whereNull,
  }) async {
    final snapshot =
        whereNull == null
            ? await collectionRef.get()
            : await collectionRef
                .where(
                  whereNull,
                  isNull: true,
                )
                .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  static Future<T?> findById<T>(
    String id,
    T Function(DocumentSnapshot snapshot) fromFirestore,
    String collection,
  ) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection(collection).doc(id).get();
    if (doc.exists) {
      return fromFirestore(doc);
    }
    return null;
  }

  static Future<int> count<T>(String collection) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  static Future<void> addToCollection(
    String collection,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance.collection(collection).add(data);
  }
}
