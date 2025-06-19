import 'package:aromex/models/generic_firebase_object.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer extends GenericFirebaseObject<Customer> {
  final String name;
  final String phone;
  final String email;
  final String address;
  final double balance;
  final DateTime createdAt;
  final Timestamp? updatedAt;
  final String notes;
  final List<DocumentReference>? transactionHistory;

  static const collectionName = "Customers";
  @override
  String get collName => collectionName;

  Customer({
    super.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    required this.createdAt,
    this.balance = 0.0,
    this.transactionHistory,
    super.snapshot,
    required this.updatedAt,
    this.notes = '',
  });

  @override
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      balance: (data['balance'] ?? 0.0).toDouble(),
      transactionHistory:
          (data['transactionHistory'] as List<dynamic>?)
              ?.cast<DocumentReference>(),
      snapshot: doc,
      updatedAt: (data['updatedAt'] as Timestamp?),
      notes: data['notes'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'balance': balance,
      'transactionHistory': transactionHistory ?? [],
      'updatedAt': Timestamp.now(),
      'notes': notes,
    };
  }
}
