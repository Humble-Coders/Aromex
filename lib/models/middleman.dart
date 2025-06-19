import 'package:aromex/models/generic_firebase_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Middleman extends GenericFirebaseObject<Middleman> {
  final String name;
  final String phone;
  final String email;
  final String address;
  final double commission;
  final DateTime createdAt;
  final double balance;
  final Timestamp? updatedAt;
  final List<DocumentReference>? transactionHistory;

  static const collectionName = "Middlemen";
  @override
  String get collName => collectionName;

  Middleman({
    super.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    required this.commission,
    required this.createdAt,
    this.balance = 0.0,
    this.transactionHistory,
    super.snapshot,
    this.updatedAt,
  });

  @override
  factory Middleman.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Middleman(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      commission: (data['commission'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      balance: (data['balance'] ?? 0.0).toDouble(),
      transactionHistory:
          (data['transactionHistory'] as List<dynamic>?)
              ?.cast<DocumentReference>(),
      snapshot: doc,
      updatedAt: (data['updatedAt'] as Timestamp?),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'commission': commission,
      'createdAt': Timestamp.fromDate(createdAt),
      'balance': balance,
      'transactionHistory': transactionHistory ?? [],
      'updatedAt': Timestamp.now(),
    };
  }
}
