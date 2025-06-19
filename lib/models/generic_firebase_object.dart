import 'package:cloud_firestore/cloud_firestore.dart';

abstract class GenericFirebaseObject<T> {
  String? id;
  String get collName;
  DocumentSnapshot? snapshot;
  GenericFirebaseObject({this.id, this.snapshot});

  Map<String, dynamic> toFirestore();
  Future<DocumentReference> create() async {
    DocumentReference ref = await FirebaseFirestore.instance
        .collection(collName)
        .add(toFirestore());
    id = ref.id;
    return ref;
  }

  Future<void> save() async {
    if (id == null) throw Exception("ID is required to update");
    await FirebaseFirestore.instance
        .collection(collName)
        .doc(id)
        .set(toFirestore());
  }

  Future<void> delete() async {
    if (id == null) throw Exception("ID is required to delete");
    await FirebaseFirestore.instance.collection(collName).doc(id).delete();
  }
}
