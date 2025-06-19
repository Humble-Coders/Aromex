import 'package:aromex/models/phone.dart';
import 'package:aromex/models/sale.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:flutter/material.dart';

class SalePhonesPage extends StatefulWidget {
  const SalePhonesPage({super.key, required this.sale, required this.onBack});

  final VoidCallback onBack;
  final Sale sale;
  @override
  State<SalePhonesPage> createState() => _SalePhonesPageState();
}

class _SalePhonesPageState extends State<SalePhonesPage> {
  List<Map<String, dynamic>> phoneList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getPhoneData();
  }

  void getPhoneData() async {
    final phones = <Map<String, dynamic>>[];

    for (final phoneRef in widget.sale.phones) {
      final doc = await phoneRef.get();
      if (!doc.exists) continue;

      final phone = Phone.fromFirestore(doc);
      await Future.wait([
        phone.loadModel(),
        phone.loadBrand(),
      ]);

      final modelName = phone.model?.get('name') ?? 'Unknown Model';
      final brandName = phone.brand?.get('name') ?? 'Unknown Brand';

      final revenue = phone.sellingPrice ?? 0.0;
      final cost = phone.price;
      final profit = revenue - cost;

      phones.add({
        'brand': brandName,
        'model': modelName,
        'profit': profit,
        'revenue': revenue,
      });
    }

    setState(() {
      phoneList = phones;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Card(
              margin: const EdgeInsets.all(12),
              color: colorScheme.secondary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                    ),
                    GenericCustomTable<Map<String, dynamic>>(
                      entries: phoneList,
                      headers: ['Brand', 'Model', 'Profit', 'Revenue'],
                      valueGetters: [
                        (item) => item['brand'],
                        (item) => item['model'],
                        (item) => formatCurrency(item['profit']),
                        (item) => formatCurrency(item['revenue']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
