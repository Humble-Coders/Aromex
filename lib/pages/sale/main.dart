import 'package:aromex/models/customer.dart';
import 'package:aromex/models/order.dart' as my_order;
import 'package:aromex/models/phone.dart';
import 'package:aromex/pages/sale/widgets/final_sale_card.dart';
import 'package:aromex/pages/sale/widgets/sale_page_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  SalePageState createState() => SalePageState();
}

class SaleCardSavedState {
  String? saleId;
  DateTime? date;
  DateTime? internalSelectedDate;
  List<Customer>? customers;
  Customer? selectedCustomer;
  List<Phone>? allPhones;
  List<DocumentReference> phoneRefs = [];
  List<Phone> phones = [];

  void clear() {
    saleId = null;
    date = null;
    internalSelectedDate = null;
    customers = null;
    selectedCustomer = null;
    phones.clear();
    phoneRefs.clear();
    allPhones = null;
  }
}

class SalePageState extends State<SalePage> {
  my_order.Order? order;
  int pageNo = 1;

  SaleCardSavedState savedState = SaleCardSavedState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child:
              pageNo == 1
                  ? SalePageCard(
                    savedState: savedState,
                    onSubmit: (my_order.Order order) {
                      setState(() {
                        this.order = order;
                        pageNo = 2;
                      });
                    },
                  )
                  : FinalSaleCard(
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
