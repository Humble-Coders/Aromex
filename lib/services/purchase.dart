import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/order.dart' as aromex_order;
import 'package:aromex/models/phone.dart';
import 'package:aromex/models/purchase.dart';
import 'package:aromex/models/transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createPurchase(aromex_order.Order order, Purchase purchase) async {
  await createPhoneRef(order.phoneList, order.phones!);
  final purchaseRef = await purchase.create();

  for (final phone in order.phoneList) {
    phone.purchaseRef = purchaseRef;
    await phone.save();
  }

  await deductBalance(
    purchase.paymentSource,
    purchase.total,
    purchase.credit,
    purchaseRef,
  );
  await addCreditToSupplier(order.scref!, purchase.credit);
  await addPurchaseToSupplier(order.scref!, purchaseRef);
  await updatePurchaseStats(purchase.total, order.scref!);
}

Future<void> deductBalance(
    BalanceType paymentSource,
    double amount,
    double credit,
    DocumentReference purchaseRef,
    ) async {
  amount -= credit;

  await Future.wait([
    Balance.fromType(paymentSource).then((balance) async {
      await balance.removeAmount(
        amount,
        transactionType: TransactionType.purchase,
        purchaseRef: purchaseRef,
      );
    }),
    if (true)
      Balance.fromType(BalanceType.totalDue).then((balance) async {
        await balance.addAmount(
          credit,
          transactionType: TransactionType.purchase,
          purchaseRef: purchaseRef,
        );
      }),
  ]);
}

Future<void> addCreditToSupplier(DocumentReference scref, double credit) async {
  final docRef = FirebaseFirestore.instance
      .collection('Suppliers')
      .doc(scref.id);

  final snapshot = await docRef.get();
  final data = snapshot.data()!;
  final currentBalance = (data['balance'] ?? 0.0) as num;

  await docRef.update({'balance': currentBalance + credit});
}

Future<void> addPurchaseToSupplier(
    DocumentReference scref,
    DocumentReference purchaseRef,
    ) async {
  await FirebaseFirestore.instance.collection('Suppliers').doc(scref.id).update(
    {
      'transactionHistory': FieldValue.arrayUnion([purchaseRef]),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  );
}

Future<void> createPhoneRef(
    List<Phone> phones,
    List<DocumentReference> phoneRefs,
    ) async {
  for (final phone in phones) {
    DocumentReference ref = await phone.create();
    phoneRefs.add(ref);
  }
}

Future<void> updatePurchaseStats(double amount, DocumentReference scref) async {
  final totalsRef = FirebaseFirestore.instance.collection('Data').doc('Totals');

  try {
    final totalsSnapshot = await totalsRef.get();

    if (!totalsSnapshot.exists) {
      await totalsRef.set({
        'totalPurchases': 1,
        'totalAmount': amount,
        'supplierIds': [scref.id],
        'totalSuppliers': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = totalsSnapshot.data()!;
    final currentTotalPurchases = (data['totalPurchases'] ?? 0) as num;
    final currentTotalAmount = (data['totalAmount'] ?? 0.0) as num;

    List<String> supplierIds = List<String>.from(data['supplierIds'] ?? []);

    bool isNewSupplier = !supplierIds.contains(scref.id);

    if (isNewSupplier) {
      supplierIds.add(scref.id);
    }

    await totalsRef.update({
      'totalPurchases': currentTotalPurchases + 1,
      'totalAmount': currentTotalAmount + amount,
      'supplierIds': supplierIds,
      'totalSuppliers': supplierIds.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error updating purchase stats: $e');
  }
}