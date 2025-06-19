import 'package:aromex/models/customer.dart';
import 'package:aromex/widgets/custom_list_tile.dart';
import 'package:aromex/widgets/search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aromex/widgets/pin_dialog.dart';

class CustomerList extends StatefulWidget {
  final Function(Customer)? onTap;
  const CustomerList({super.key, this.onTap});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  bool isLoading = true;
  List<Customer> customers = [];
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? deletingCustomerId; 

  // Search
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text;
      });
    });
  }

  void fetchCustomers() {
    db
        .collection('Customers')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              customers =
                  snapshot.docs
                      .map((doc) => Customer.fromFirestore(doc))
                      .toList();
            });
          });
        })
        .onError((error) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching customers: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers =
        customers.where((customer) {
          return customer.name.toLowerCase().contains(searchText.toLowerCase());
        }).toList();
    return Column(
      children: [
        const SizedBox(height: 12),
        CustomSearchBar(controller: searchController),
        const SizedBox(height: 12),
        Expanded(
          child:
              filteredCustomers.isNotEmpty
                  ? ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return CustomListTile(
                        title: customer.name,
                        subtitle: customer.phone,
                        credit: customer.balance.toString(),
                        email: customer.email,
                        onTap: () {
                          widget.onTap!(customer);
                        },
                        onDelete:
                            deletingCustomerId == customer.id
                                ? null
                                : () async {
                                  final confirmed = await showPinDialog(
                                    context,
                                  );
                                  if (!confirmed) return;
                                  if (customer.transactionHistory == null ||
                                      customer.transactionHistory!.isEmpty) {
                                    setState(() {
                                      deletingCustomerId = customer.id;
                                    });
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Customers')
                                          .doc(customer.id)
                                          .delete();
                                      await FirebaseFirestore.instance
                                          .collection('Data')
                                          .doc('Totals')
                                          .update({
                                            'totalCustomers':
                                                FieldValue.increment(-1),
                                            'customerIds': FieldValue.arrayRemove([customer.id]),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Customer deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error deleting customer: $e',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        deletingCustomerId = null;
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot delete: Customer has transactions',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        trailing:
                            deletingCustomerId == customer.id
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : null,
                      );
                    },
                  )
                  : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                    child: Text(
                      'No Customers Found',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
        ),
      ],
    );
  }
}
