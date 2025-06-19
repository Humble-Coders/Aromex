import 'package:aromex/models/phone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  String? orderNumber;
  DocumentReference? scref;
  String scName;
  DateTime? date;
  List<DocumentReference>? phones;
  double? originalPrice;
  double gst = 0.0;
  double amount = 0.0;
  List<Phone> phoneList = [];

  Order({
    required this.orderNumber,
    required this.scref,
    required this.scName,
    required this.date,
    required this.phones,
    required this.amount,
    required this.phoneList,
    this.originalPrice,
  }) {
    if (phones == null) {
      for (final phone in phoneList) {
        phones?.add(FirebaseFirestore.instance.doc(phone.documentReference));
      }
    }
  }
}
