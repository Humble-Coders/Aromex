import 'package:aromex/models/order.dart';
import 'package:aromex/models/phone.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/purchase/widgets/final_purchase_card.dart';
import 'package:aromex/pages/purchase/widgets/purchase_page_card.dart';
import 'package:flutter/material.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  PurchasePageState createState() => PurchasePageState();
}

class PurchaseCardSavedState {
  String? orderId;
  DateTime? date;
  DateTime? internalSelectedDate;
  List<Supplier>? suppliers;
  Supplier? selectedSupplier;
  List<Phone> phones = [];

  void clear() {
    orderId = null;
    date = null;
    internalSelectedDate = null;
    suppliers = null;
    selectedSupplier = null;
    phones.clear();
  }
}

class PurchasePageState extends State<PurchasePage> {
  Order? order;
  int pageNo = 1;

  PurchaseCardSavedState savedState = PurchaseCardSavedState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child:
              pageNo == 1
                  ? PurchasePageCard(
                    savedState: savedState,
                    onSubmit: (Order order) {
                      setState(() {
                        this.order = order;
                        pageNo = 2;
                      });
                    },
                  )
                  : FinalPurchaseCard(
                    order: order!,
                    onCancel: () {
                      setState(() {
                        pageNo = 1;
                      });
                    },
                    onSubmit: () {
                      setState(() {
                        order = null;
                        savedState.clear();
                        pageNo = 1;
                      });
                    },
                  ),
        ),
      ),
    );
  }
}
