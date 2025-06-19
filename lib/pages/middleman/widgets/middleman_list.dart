import 'package:aromex/models/middleman.dart';
import 'package:aromex/widgets/custom_list_tile.dart';
import 'package:aromex/widgets/search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aromex/widgets/pin_dialog.dart';

class MiddlemanList extends StatefulWidget {
  final Function(Middleman)? onTap;
  const MiddlemanList({super.key, this.onTap});

  @override
  State<MiddlemanList> createState() => _MiddlemanListState();
}

class _MiddlemanListState extends State<MiddlemanList> {
  bool isLoading = true;
  List<Middleman> middlemen = [];
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String? deletingMiddlemanId;

  // Search
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    fetchmiddlemen();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text;
      });
    });
  }

  void fetchmiddlemen() {
    db
        .collection('Middlemen')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              middlemen =
                  snapshot.docs
                      .map((doc) => Middleman.fromFirestore(doc))
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
            SnackBar(content: Text('Error fetching middlemen: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final filteredmiddlemen =
        middlemen.where((middleman) {
          return middleman.name.toLowerCase().contains(
            searchText.toLowerCase(),
          );
        }).toList();
    return Column(
      children: [
        const SizedBox(height: 12),
        CustomSearchBar(controller: searchController),
        const SizedBox(height: 12),
        Expanded(
          child:
              filteredmiddlemen.isNotEmpty
                  ? ListView.builder(
                    itemCount: filteredmiddlemen.length,
                    itemBuilder: (context, index) {
                      final middleman = filteredmiddlemen[index];
                      return CustomListTile(
                        title: middleman.name,
                        subtitle: middleman.phone,
                        credit: middleman.balance.toString(),
                        email: middleman.email,
                        onTap: () {
                          widget.onTap?.call(middleman);
                        },
                        onDelete:
                            deletingMiddlemanId == middleman.id
                                ? null
                                : () async {
                                  final confirmed = await showPinDialog(
                                    context,
                                  );
                                  if (!confirmed) return;
                                  if (middleman.transactionHistory == null ||
                                      middleman.transactionHistory!.isEmpty) {
                                    setState(() {
                                      deletingMiddlemanId = middleman.id;
                                    });
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('Middlemen')
                                          .doc(middleman.id)
                                          .delete();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Middleman deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error deleting middleman: $e',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        deletingMiddlemanId = null;
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot delete: Middleman has transactions',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        trailing:
                            deletingMiddlemanId == middleman.id
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
                      'No middlemen Found',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
        ),
      ],
    );
  }
}
