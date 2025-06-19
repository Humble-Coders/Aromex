import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { sale, purchase, self, unknown }

Map<TransactionType, String> transactionTypeTitles = {
  TransactionType.sale: 'Sale',
  TransactionType.purchase: 'Purchase',
  TransactionType.self: 'Self',
  TransactionType.unknown: 'Unknown',
};

class Transaction {
  static const collectionName = 'Transactions';
  final String? id;
  final double amount;
  final Timestamp time;
  final DocumentSnapshot? snapshot;
  final TransactionType type;
  final DocumentReference? saleRef;
  final DocumentReference? purchaseRef;
  final String? note;
  final String? category;

  Transaction({
    required this.amount,
    required this.time,
    this.id,
    this.saleRef,
    this.purchaseRef,
    this.snapshot,
    this.type = TransactionType.unknown,
    this.category,
    this.note,
  }) : assert(
         type != TransactionType.purchase || purchaseRef != null,
         'Purchase transactions must have a purchaseRef',
       ),
       assert(
         type != TransactionType.sale || saleRef != null,
         'Sale transactions must have a saleRef',
       ),
       assert(
         type != TransactionType.unknown ||
             (saleRef == null && purchaseRef == null),
         'Unknown transactions must not have saleRef or purchaseRef',
       );

  factory Transaction.fromJson(String? id, Map<String, dynamic> json) {
    return Transaction(
      id: id,
      amount: (json['amount'] as num).toDouble(),
      time: json['time'] as Timestamp,
      saleRef: json['saleRef'],
      category: json['category'],
      purchaseRef: json['purchaseRef'],
      type:
          transactionTypeTitles.entries
              .firstWhere(
                (entry) => entry.value == json['type'],
                orElse: () => MapEntry(TransactionType.unknown, 'Unknown'),
              )
              .key,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'time': time,
      'saleRef': saleRef,
      'purchaseRef': purchaseRef,
      'type': transactionTypeTitles[type],
      'note': note,
      'category': category,
    };
  }
}
