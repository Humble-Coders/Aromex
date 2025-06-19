import 'package:aromex/models/generic_firebase_object.dart';
import 'package:aromex/models/phone_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Phone extends GenericFirebaseObject<Phone> {
  DocumentReference modelRef;
  DocumentSnapshot? model;
  DocumentReference? brandRef;
  DocumentSnapshot? brand;
  String color;
  double capacity;
  String imei;
  bool status;
  String carrier;
  DocumentReference? storageLocationRef;
  DocumentSnapshot? storageLocation;
  double price = 0.0;
  double? sellingPrice;
  DocumentReference? saleRef;
  DocumentReference? purchaseRef;

  String get collectionName => "${modelRef.path}/Phones";
  static String collectionNameByModel(PhoneModel model) {
    return "${model.collName}/${model.id}/Phones";
  }

  String get documentReference {
    return "${modelRef.path}/Phones/$id";
  }

  @override
  String get collName => collectionName;

  Phone({
    super.id,
    required this.modelRef,
    this.model,
    required this.color,
    required this.capacity,
    required this.price,
    required this.imei,
    required this.status,
    required this.carrier,
    required this.storageLocationRef,
    this.storageLocation,
    super.snapshot,
    this.brand,
    this.brandRef,
    this.sellingPrice,
    this.saleRef,
    this.purchaseRef,
  });

  Future<void> loadModel() async {
    model = await modelRef.get();
  }

  Future<void> loadBrand() async {
    if (brandRef != null) {
      brand = await brandRef!.get();
    }
  }

  Future<void> loadStorageLocation() async {
    if (storageLocationRef != null) {
      storageLocation = await storageLocationRef!.get();
    }
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      "color": color,
      "capacity": capacity,
      "price": price,
      "imei": imei,
      "status": status,
      "carrier": carrier,
      "storageLocationRef": storageLocationRef,
      "modelRef": modelRef,
      "brandRef": brandRef,
      "sellingPrice": sellingPrice,
      "saleRef": saleRef,
      "purchaseRef": purchaseRef,
    };
  }

  factory Phone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Phone(
      id: doc.id,
      modelRef: doc.reference.parent.parent!,
      color: doc["color"],
      capacity: doc["capacity"].toDouble(),
      price: doc["price"].toDouble(),
      imei: doc["imei"],
      status: doc["status"],
      carrier: doc["carrier"],
      storageLocationRef: doc["storageLocationRef"] as DocumentReference,
      snapshot: doc,
      brandRef: doc["brandRef"] as DocumentReference,
      sellingPrice: (data["sellingPrice"] as num?)?.toDouble(),
      saleRef: data["saleRef"] as DocumentReference?,
      purchaseRef: data["purchaseRef"] as DocumentReference?,
    );
  }

  @override
  String toString() {
    return "Phone: $id, ${modelRef.path}, $color, $capacity, $price, $imei, $status, $carrier, ${storageLocationRef?.path}, $sellingPrice";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Phone) return false;
    return id == other.id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
