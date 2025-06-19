import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/customer.dart';
import 'package:aromex/models/sale.dart';
import 'package:aromex/pages/home/pages/sale_detail_page.dart';
import 'package:aromex/pages/home/widgets/balance_card.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:aromex/widgets/profile_card.dart';
import 'package:aromex/widgets/update_credit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class CustomerProfile extends StatefulWidget {
  final VoidCallback? onBack;
  final Customer? customer;
  const CustomerProfile({super.key, this.onBack, required this.customer});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  List<Sale> sales = [];
  bool isLoading = true;
  late Customer currentCustomer; 
  SaleDetailPage? saleDetailPage;

  @override
  void initState() {
    super.initState();
    currentCustomer = widget.customer!; 
    loadSales();
  }

  Future<List<Sale>> fetchSales(List<DocumentReference>? refs) async {
    if (refs == null || refs.isEmpty) {
      return [];
    }

    try {
      final snapshots = await Future.wait(refs.map((ref) => ref.get()));
      return snapshots
          .where((snap) => snap.exists && snap.data() != null)
          .map((snap) => Sale.fromFirestore(snap))
          .toList();
    } catch (e) {
      print('Error fetching sales: $e');
      return [];
    }
  }

  Future<void> loadSales() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (currentCustomer.transactionHistory != null) {
        final fetched = await fetchSales(currentCustomer.transactionHistory);

        if (mounted) {
          setState(() {
            sales = fetched;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            sales = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error in loadSales: $e');
      if (mounted) {
        setState(() {
          sales = [];
          isLoading = false;
        });
      }
    }
  }

  // Method to refresh customer data from Firestore
  Future<void> refreshCustomerData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection(Customer.collectionName)
              .doc(currentCustomer.id)
              .get();

      if (doc.exists) {
        setState(() {
          currentCustomer = Customer.fromFirestore(doc);
        });
      }
    } catch (e) {
      print('Error refreshing customer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (saleDetailPage != null) {
      return saleDetailPage!;
    }

    Timestamp? updatedAtTimestamp = currentCustomer.updatedAt;
    String updatedAt = "N/A";
    if (updatedAtTimestamp != null) {
      final date = updatedAtTimestamp.toDate();
      updatedAt = DateFormat.yMd().add_jm().format(date);
    }

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
                name: currentCustomer.name,
                email: currentCustomer.email,
                phoneNumber: currentCustomer.phone,
                address: currentCustomer.address,
                createdAt: currentCustomer.createdAt,
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
                                  amount: currentCustomer.balance,
                                  updatedAt: updatedAt,
                                  icon: SvgPicture.asset(
                                    'assets/icons/credit_card.svg',
                                    width: 40,
                                    height: 40,
                                  ),
                                  documentId: currentCustomer.id!,
                                  collectionName: Customer.collectionName,
                                  onBalanceUpdated: () {
                                    // Refresh the customer data when balance is updated
                                    refreshCustomerData();
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                      amount: currentCustomer.balance,
                      updatedAt: updatedAt,
                      isLoading: false,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 16),
              sales.isNotEmpty
                  ? GenericCustomTable<Sale>(
                    onTap: (p) {
                      setState(() {
                        saleDetailPage = SaleDetailPage(
                          sale: p,
                          onBack: () {
                            setState(() {
                              saleDetailPage = null;
                            });
                          },
                        );
                      });
                    },
                    entries: sales,
                    headers: [
                      "Date",
                      "Order No.",
                      "Amount",
                      "Payment Source",
                      "Credit",
                    ],
                    valueGetters: [
                      (p) => DateFormat.yMd().format(p.date),
                      (p) => p.orderNumber,
                      (p) =>
                          NumberFormat.currency(symbol: '\$').format(p.amount),
                      (p) => balanceTypeTitles[p.paymentSource]!,
                      (p) =>
                          NumberFormat.currency(symbol: '\$').format(p.credit),
                    ],
                  )
                  : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                    child: Text(
                      'No Sales Found',
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
