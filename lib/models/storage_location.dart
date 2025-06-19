import 'package:aromex/models/generic_firebase_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageLocation extends GenericFirebaseObject<StorageLocation> {
  String name;

  StorageLocation({super.id, required this.name, super.snapshot});

  factory StorageLocation.empty() {
    return StorageLocation(name: "");
  }

  static const String collectionName = "StorageLocations";
  @override
  String get collName => collectionName;

  @override
  Map<String, dynamic> toFirestore() {
    return {"name": name};
  }

  static StorageLocation fromFirestore(DocumentSnapshot doc) {
    return StorageLocation(id: doc.id, name: doc["name"], snapshot: doc);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StorageLocation) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
