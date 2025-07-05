import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import '../models/middleman.dart';
import '../models/person.dart';
import '../models/supplier.dart';

class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Customer>> fetchCustomers() async {
    final snapshot = await _firestore.collection('Customers').get();
    return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final snapshot = await _firestore.collection('Suppliers').get();
    return snapshot.docs.map((doc) => Supplier.fromFirestore(doc)).toList();
  }

  Future<List<Middleman>> fetchMiddlemen() async {
    final snapshot = await _firestore.collection('Middlemen').get();
    return snapshot.docs.map((doc) => Middleman.fromFirestore(doc)).toList();
  }

  Future<List<Person>> fetchPerson() async {
    final snapshot = await _firestore.collection('Person').get();
    return snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList();
  }

  Future<List<Map<String, dynamic>>> loadAllEntries() async {
    final entriesSnapshot =
        await _firestore
            .collection('currency_exchanges')
            .orderBy('timestamp', descending: true)
            .get();

    List<Map<String, dynamic>> entries = [];

    for (var doc in entriesSnapshot.docs) {
      final data = doc.data();
      entries.add({
        'id': doc.id,
        'person1': data['person1'] ?? 'Unknown',
        'person2': data['person2'] ?? 'Unknown',
        'direction': data['direction'] ?? 'give_to',
        'fromCurrency': data['fromCurrency'] ?? 'INR',
        'toCurrency': data['toCurrency'] ?? 'USD',
        'amount': data['amount'] ?? 0,
        'exchangeRate': data['exchangeRate'] ?? 1.0,
        'convertedAmount': data['convertedAmount'] ?? 0,
        'commission': data['commission'] ?? 0,
        'commissionPerson': data['commissionPerson'],
        'notes': data['notes'] ?? '',
        'isCurrencyExchange': data['isCurrencyExchange'] ?? true,
        'timestamp':
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      });
    }

    return entries;
  }

  Future<void> deleteEntry(String entryId) async {
    await _firestore.collection('currency_exchanges').doc(entryId).delete();
  }
}
