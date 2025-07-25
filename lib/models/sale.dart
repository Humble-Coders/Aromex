import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/bill.dart';
import 'package:aromex/models/bill_customer.dart';
import 'package:aromex/models/bill_item.dart';
import 'package:aromex/models/customer.dart';
import 'package:aromex/models/generic_firebase_object.dart';
import 'package:aromex/models/phone.dart';
import 'package:aromex/models/phone_brand.dart';
import 'package:aromex/models/phone_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aromex/models/phone.dart';


class Sale extends GenericFirebaseObject<Sale> {
  final String orderNumber;
  final DateTime date;
  final double amount;
  final double gst;
  final double pst;
  final BalanceType paymentSource;
  final double total;
  final double paid;
  final double credit;
  final DocumentReference customerRef;
  final List<DocumentReference> phones;
  final DocumentReference? middlemanRef;
  final double mTotal;
  final double mPaid;
  final double mCredit;
  final String? customerName;
  final double originalPrice;

  Sale({
    super.id,
    super.snapshot,
    required this.orderNumber,
    required this.amount,
    required this.gst,
    required this.pst,
    required this.paymentSource,
    required this.date,
    this.total = 0.0,
    this.paid = 0.0,
    this.credit = 0.0,
    required this.customerRef,
    required this.phones,
    this.middlemanRef,
    this.mTotal = 0.0,
    this.mPaid = 0.0,
    this.mCredit = 0.0,
    required this.customerName,
    required this.originalPrice,
  });

  static const collectionName = "Sales";
  @override
  String get collName => collectionName;

  @override
  Map<String, dynamic> toFirestore() {
    return {
      "orderNumber": orderNumber,
      "originalPrice": originalPrice,
      "amount": amount,
      "gst": gst,
      "pst": pst,
      "paymentSource": balanceTypeTitles[paymentSource],
      "date": date,
      "total": total,
      "paid": paid,
      "credit": credit,
      "customerId": customerRef,
      "phones": phones,
      "middlemanId": middlemanRef,
      "mTotal": mTotal,
      "mPaid": mPaid,
      "mCredit": mCredit,
      "customerName": customerName,
    };
  }

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      orderNumber: data["orderNumber"],
      originalPrice: (data["originalPrice"] ?? 0.0).toDouble(),
      amount: (data['amount'] ?? 0.0).toDouble(),
      gst: (data['gst'] ?? 0.0).toDouble(),
      pst: (data['pst'] ?? 0.0).toDouble(),
      paymentSource: BalanceType.values.firstWhere(
        (type) => type.toString() == 'BalanceType.${data["paymentSource"]}',
        orElse: () => BalanceType.cash,
      ),
      date: (data['date'] as Timestamp).toDate(),
      total: (data['total'] ?? 0.0).toDouble(),
      paid: (data['paid'] ?? 0.0).toDouble(),
      credit: (data['credit'] ?? 0.0).toDouble(),
      customerRef: data["customerId"],
      phones:
          (data['phones'] as List<dynamic>)
              .map((e) => e as DocumentReference)
              .toList(),
      snapshot: doc,
      middlemanRef: data["middlemanId"],
      mTotal: (data['mTotal'] ?? 0.0).toDouble(),
      mPaid: (data['mPaid'] ?? 0.0).toDouble(),
      mCredit: (data['mCredit'] ?? 0.0).toDouble(),
      customerName: data["customerName"] ?? "",
    );
  }
}

Future<void> generateBill({
  required Sale sale,
  required Customer customer,
  required List<Phone> phones,
  double? adjustment,
  String? note,
}) async {
  print("Starting generateBill function");
  print("Number of phones: ${phones.length}");

  if (phones.isEmpty) {
    throw Exception("No phones available for bill generation");
  }

  List<BillItem> items = [];
  Map<String, List<Phone>> groupedPhones = {};

  // Group phones by model, color, capacity, and price
  for (var phone in phones) {
    String key = "${phone.modelRef?.id ?? 'unknown'}_${phone.color}_${phone.capacity}_${phone.price}";
    if (!groupedPhones.containsKey(key)) {
      groupedPhones[key] = [];
    }
    groupedPhones[key]!.add(phone);
  }

  // Create bill items for each group
  for (var entry in groupedPhones.entries) {
    Phone phone = entry.value.first;
    int quantity = entry.value.length;

    String modelName = "Unknown Model";
    String brandName = "Unknown Brand";

    try {
      // Fetch model name
      if (phone.modelRef != null) {
        DocumentSnapshot modelDoc = await phone.modelRef!.get();
        if (modelDoc.exists) {
          Map<String, dynamic> modelData = modelDoc.data() as Map<String, dynamic>;
          modelName = modelData['name'] ?? "Unknown Model";
        }
      }

      // Fetch brand name
      if (phone.brandRef != null) {
        DocumentSnapshot brandDoc = await phone.brandRef!.get();
        if (brandDoc.exists) {
          Map<String, dynamic> brandData = brandDoc.data() as Map<String, dynamic>;
          brandName = brandData['name'] ?? "Unknown Brand";
        }
      }
    } catch (e) {
      print("Error loading phone details: $e");
    }

    String itemTitle = "$brandName $modelName, ${phone.color}, ${phone.capacity}GB";
    print("Adding bill item: $itemTitle x $quantity @ ${phone.price}");

    items.add(
      BillItemImpl(
        quantity: quantity,
        title: itemTitle,
        unitPrice: phone.price,
      ),
    );
  }

  print("Total bill items created: ${items.length}");

  if (items.isEmpty) {
    throw Exception("No bill items could be generated");
  }

  // Create the bill
  Bill bill = Bill(
    time: sale.date,
    customer: BillCustomer(
      name: customer.name,
      address: customer.address.replaceAll(",", "\n"),
    ),
    orderNumber: sale.orderNumber,
    items: items,
    note: note,
    adjustment: adjustment,
  );

  try {
    print("Generating PDF invoice with ${bill.items.length} items");
    await generatePdfInvoice(bill);
    print("PDF bill generated successfully");
  } catch (e) {
    print("Error generating PDF bill: $e");
    throw e;
  }
}
