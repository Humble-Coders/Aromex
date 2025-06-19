import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deletePurchaseWithReversal(Purchase purchase) async {
  // Validate input
  if (purchase.id == null || purchase.id!.isEmpty) {
    throw Exception('Purchase ID cannot be null or empty');
  }

  final purchaseRef = FirebaseFirestore.instance
      .collection('Purchases')
      .doc(purchase.id);

  try {
    // 1. Reverse supplier balance
    final supplierRef = purchase.supplierRef;

    final supplierDoc = await supplierRef.get();
    if (!supplierDoc.exists) {
      throw Exception('Supplier not found: ${supplierRef.id}');
    }

    final supplierData = supplierDoc.data();
    if (supplierData == null) {
      throw Exception('Supplier data is null');
    }

    final supplierDataMap = supplierData as Map<String, dynamic>;
    final currentBalance = (supplierDataMap['balance'] ?? 0.0) as num;
    final creditAmount = purchase.credit;

    await supplierRef.update({'balance': currentBalance - creditAmount});

    final paymentSourceName = balanceTypeTitles[purchase.paymentSource];
    if (paymentSourceName == null || paymentSourceName.isEmpty) {
      throw Exception('Invalid payment source: ${purchase.paymentSource}');
    }

    final balanceDoc =
        await FirebaseFirestore.instance
            .collection('Balances')
            .doc(paymentSourceName)
            .get();

    if (!balanceDoc.exists) {
      throw Exception('Balance document not found: $paymentSourceName');
    }

    final balanceData = balanceDoc.data();
    if (balanceData == null) {
      throw Exception('Balance data is null for: $paymentSourceName');
    }

    final balanceDataMap = balanceData;
    final balanceAmount = (balanceDataMap['amount'] ?? 0.0) as num;
    final purchaseAmount = purchase.amount;

    await balanceDoc.reference.update({
      'amount': balanceAmount + (purchaseAmount - creditAmount),
    });

    // 3. Reverse totalDue if credit was used
    if (creditAmount != 0) {
      final dueDoc =
          await FirebaseFirestore.instance
              .collection('Balances')
              .doc('Total Due')
              .get();

      if (!dueDoc.exists) {
        throw Exception('TotalDue document not found');
      }

      final dueData = dueDoc.data();
      if (dueData == null) {
        throw Exception('TotalDue data is null');
      }

      final dueDataMap = dueData;
      final dueAmount = (dueDataMap['amount'] ?? 0.0) as num;

      await dueDoc.reference.update({'amount': dueAmount - creditAmount});
    }

    // 4. Remove purchaseRef from phones and delete the phones
    final phones = purchase.phones;
    if (phones.isNotEmpty) {
      for (final phoneRef in phones) {
        try {
          // Check if phone document exists before updating
          final phoneDoc = await phoneRef.get();
          if (phoneDoc.exists) {
            await phoneRef.update({'purchaseRef': null});
            await phoneRef.delete();
          }
        } catch (e) {
          print('Warning: Failed to delete phone ${phoneRef.id}: $e');
          // Continue with other phones instead of failing entirely
        }
      }
    }

    // 5. Remove purchaseRef from supplier's transactionHistory
    try {
      await supplierRef.update({
        'transactionHistory': FieldValue.arrayRemove([purchaseRef]),
      });
    } catch (e) {
      print('Warning: Failed to update supplier transaction history: $e');
      // Don't fail the entire operation for this
    }

    // 6. Update totals
    try {
      final totalsDoc =
          await FirebaseFirestore.instance
              .collection('Data')
              .doc('Totals')
              .get();

      if (totalsDoc.exists) {
        final totalsData = totalsDoc.data();
        if (totalsData != null) {
          final totalsDataMap = totalsData;
          final currentTotalPurchases =
              (totalsDataMap['totalPurchases'] ?? 0).toInt();
          final currentTotalAmount =
              (totalsDataMap['totalAmount'] ?? 0.0).toDouble();

          final newTotalPurchases =
              (currentTotalPurchases - 1).clamp(0, double.infinity).toInt();
          final newTotalAmount = (currentTotalAmount - purchaseAmount).clamp(
            0.0,
            double.infinity,
          );

          await FirebaseFirestore.instance
              .collection('Data')
              .doc('Totals')
              .update({
                'totalPurchases': newTotalPurchases,
                'totalAmount': newTotalAmount,
              });
        }
      }
    } catch (e) {
      print('Warning: Failed to update totals: $e');
      // Don't fail the entire operation for this
    }

    // 7. Delete the purchase document (do this last)
    final purchaseDoc = await purchaseRef.get();
    if (purchaseDoc.exists) {
      await purchaseRef.delete();
    } else {
      print('Warning: Purchase document ${purchase.id} does not exist');
    }
  } catch (e) {
    print('Error deleting purchase: $e');
    rethrow;
  }
}
