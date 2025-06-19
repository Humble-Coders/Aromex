import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/supplier/widgets/supplier_list.dart';
import 'package:aromex/pages/supplier/widgets/supplier_profile.dart';
import 'package:flutter/material.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  Supplier? supplier;
  int pageNo = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child:
            pageNo == 1
                ? SupplierList(
                  onTap: (Supplier supplier) {
                    setState(() {
                      this.supplier = supplier;
                      pageNo = 2;
                    });
                  },
                )
                : SupplierProfile(
                  supplier: supplier!,
                  onBack: () {
                    setState(() {
                      pageNo = 1;
                    });
                  },
                ),
      ),
    );
  }
}
