import 'package:aromex/models/generic_firebase_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneBrand extends GenericFirebaseObject<PhoneBrand> {
  String name;

  static const collectionName = "PhoneBrands";
  @override
  String get collName => collectionName;

  PhoneBrand({super.id, required this.name, super.snapshot});

  factory PhoneBrand.empty() {
    return PhoneBrand(id: "", name: "");
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {"name": name};
  }

  static PhoneBrand fromFirestore(DocumentSnapshot doc) {
    return PhoneBrand(id: doc.id, name: doc["name"], snapshot: doc);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PhoneBrand) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
