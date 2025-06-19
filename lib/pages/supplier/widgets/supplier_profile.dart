import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/purchase.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/home/pages/purchase_detail_page.dart';
import 'package:aromex/pages/home/widgets/balance_card.dart';
import 'package:aromex/widgets/profile_card.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:aromex/widgets/update_credit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class SupplierProfile extends StatefulWidget {
  final VoidCallback? onBack;
  final Supplier? supplier;
  const SupplierProfile({super.key, this.onBack, required this.supplier});

  @override
  State<SupplierProfile> createState() => _SupplierProfileState();
}

class _SupplierProfileState extends State<SupplierProfile> {
  List<Purchase> purchases = [];
  bool isLoading = true;
  late Supplier currentSupplier; // Track current supplier state
  PurchaseDetailPage? purchaseDetailPage;
  @override
  void initState() {
    super.initState();
    currentSupplier = widget.supplier!; // Initialize with the passed supplier
    loadPurchases();
  }

  Future<List<Purchase>> fetchPurchases(List<DocumentReference> refs) async {
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    return snapshots.map((snap) => Purchase.fromFirestore(snap)).toList();
  }

  Future<void> loadPurchases() async {
    if (currentSupplier.transactionHistory != null) {
      final fetched = await fetchPurchases(currentSupplier.transactionHistory!);
      setState(() {
        purchases = fetched;
        isLoading = false;
      });
    }
  }

  // Method to refresh supplier data from Firestore
  Future<void> refreshSupplierData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection(Supplier.collectionName)
              .doc(currentSupplier.id)
              .get();

      if (doc.exists) {
        setState(() {
          currentSupplier = Supplier.fromFirestore(doc);
        });
      }
    } catch (e) {
      print('Error refreshing supplier data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (purchaseDetailPage != null) {
      return purchaseDetailPage!;
    }

    Timestamp? updatedAtTimestamp = currentSupplier.updatedAt;
    final date = updatedAtTimestamp?.toDate();
    String updatedAt = DateFormat.yMd().add_jm().format(date!);

    return SingleChildScrollView(
      child: Card(
        color: colorScheme.secondary,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 12, 36, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(height: 16),
              ProfileCard(
                name: currentSupplier.name,
                email: currentSupplier.email,
                phoneNumber: currentSupplier.phone,
                address: currentSupplier.address,
                createdAt: currentSupplier.createdAt,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BalanceCard(
                      icon: SvgPicture.asset(
                        'assets/icons/credit_card.svg',
                        width: 40,
                        height: 40,
                      ),
                      title: "Credit Details",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.125,
                                  vertical:
                                      MediaQuery.of(context).size.height *
                                      0.125,
                                ),
                                child: UpdateCredit(
                                  title: "Update Credit",
                                  amount: currentSupplier.balance,
                                  updatedAt: updatedAt,
                                  icon: SvgPicture.asset(
                                    'assets/icons/credit_card.svg',
                                    width: 40,
                                    height: 40,
                                  ),
                                  documentId: currentSupplier.id!,
                                  collectionName: Supplier.collectionName,
                                  onBalanceUpdated: () {
                                    // Refresh the supplier data when balance is updated
                                    refreshSupplierData();
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      amount:
                          currentSupplier
                              .balance, // Use currentSupplier instead
                      updatedAt: updatedAt,
                      isLoading: false,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              purchases.isNotEmpty
                  ? GenericCustomTable<Purchase>(
                    onTap: (p) {
                      setState(() {
                        purchaseDetailPage = PurchaseDetailPage(
                          purchase: p,
                          onBack: () {
                            setState(() {
                              purchaseDetailPage = null;
                            });
                          },
                        );
                      });
                    },
                    entries: purchases,
                    headers: [
                      "Date",
                      "Order No.",
                      "Amount",
                      "Payment Source",
                      "Credit",
                    ],
                    valueGetters: [
                      (p) => p.date.toString(),
                      (p) => p.orderNumber,
                      (p) => p.amount.toString(),
                      (p) => balanceTypeTitles[p.paymentSource]!,
                      (p) => p.credit.toString(),
                    ],
                  )
                  : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                    child: Text(
                      'No Purchases Found',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
