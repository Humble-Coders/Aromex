import 'package:aromex/models/supplier.dart';
import 'package:aromex/widgets/custom_list_tile.dart';
import 'package:aromex/widgets/search_bar.dart';
import 'package:aromex/widgets/pin_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SupplierList extends StatefulWidget {
  final Function(Supplier)? onTap;
  const SupplierList({super.key, this.onTap});

  @override
  State<SupplierList> createState() => _SupplierListState();
}

class _SupplierListState extends State<SupplierList> {
  bool isLoading = true;
  List<Supplier> suppliers = [];
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? deletingSupplierId; 

  // Search
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text;
      });
    });
  }

  void fetchSuppliers() {
    db
        .collection('Suppliers')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              suppliers =
                  snapshot.docs
                      .map((doc) => Supplier.fromFirestore(doc))
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
            SnackBar(content: Text('Error fetching suppliers: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers =
        suppliers.where((supplier) {
          return supplier.name.toLowerCase().contains(searchText.toLowerCase());
        }).toList();
    return Column(
      children: [
        const SizedBox(height: 12),
        CustomSearchBar(controller: searchController),
        const SizedBox(height: 12),
        Expanded(
          child:
              filteredSuppliers.isNotEmpty
                  ? ListView.builder(
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = filteredSuppliers[index];
                      return CustomListTile(
                        title: supplier.name,
                        subtitle: supplier.phone,
                        credit: supplier.balance.toString(),
                        email: supplier.email,
                        onTap: () {
                          widget.onTap?.call(supplier);
                        },
                        onDelete:
                            deletingSupplierId == supplier.id
                                ? null
                                : () async {
                                  final confirmed = await showPinDialog(
                                    context,
                                  );
                                  if (!confirmed) return;
                                  if (supplier.transactionHistory == null ||
                                      supplier.transactionHistory!.isEmpty) {
                                    setState(() {
                                      deletingSupplierId = supplier.id;
                                    });
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Suppliers')
                                          .doc(supplier.id)
                                          .delete();
                                      await FirebaseFirestore.instance
                                          .collection('Data')
                                          .doc('Totals')
                                          .update({
                                            'totalSuppliers':
                                                FieldValue.increment(-1),
                                            'supplierIds': FieldValue.arrayRemove([supplier.id]),
                                          });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Supplier deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error deleting supplier: $e',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        deletingSupplierId = null;
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot delete: Supplier has transactions',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        trailing:
                            deletingSupplierId == supplier.id
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
                      'No Suppliers Found',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
        ),
      ],
    );
  }
}
