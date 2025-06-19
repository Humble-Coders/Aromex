import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/order.dart' as aromex_order;
import 'package:aromex/models/sale.dart';
import 'package:aromex/models/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/services/sale.dart';
import 'package:aromex/widgets/searchable_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinalSaleCard extends StatefulWidget {
  final aromex_order.Order order;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const FinalSaleCard({
    super.key,
    required this.onCancel,
    required this.order,
    required this.onSubmit,
  });

  @override
  State<FinalSaleCard> createState() => _FinalSaleCardState();
}

class _FinalSaleCardState extends State<FinalSaleCard> {
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _pstController = TextEditingController();
  late TextEditingController _amountController;
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  final TextEditingController _middlemanTotalController =
      TextEditingController();
  final TextEditingController _middlemanPaidController =
      TextEditingController();
  final TextEditingController _middlemancreditController =
      TextEditingController();
  BalanceType? paymentSource;

  List<Middleman> middlemen = [];
  final FocusNode middlemanFocusNode = FocusNode();
  Middleman? selectedMiddleman;

  Future<void> fetchMiddlemen() async {
    try {
      middlemen = await FirestoreHelper.getAll(
        Middleman.fromFirestore,
        FirebaseFirestore.instance.collection(Middleman.collectionName),
      );
    } catch (e) {
      middlemen = [];
    }
    setState(() {});
  }

  // Calculate Credit
  void updateCredit() {
    double total = double.tryParse(_totalController.text) ?? 0;
    double paid = double.tryParse(_paidController.text) ?? 0;

    if (paid > total) {
      setState(() {
        paidError = "Paid amount can't be more than total";
        creditError = null;
      });
      return;
    }

    setState(() {
      paidError = null;
      double credit = total - paid;
      _creditController.text = credit.toStringAsFixed(2);
      creditError = null;
    });
  }

  void updateMiddlemanCredit() {
    double total = double.tryParse(_middlemanTotalController.text) ?? 0;
    double paid = double.tryParse(_middlemanPaidController.text) ?? 0;

    if (paid > total) {
      setState(() {
        middlemanPaidError = "Paid amount can't be more than total";
        creditError = null;
      });
      return;
    }

    setState(() {
      middlemanPaidError = null;
      double credit = total - paid;
      _middlemancreditController.text = credit.toStringAsFixed(2);
      creditError = null;
    });
  }

  // Calculate Total
  void updateTotal() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double gst = double.tryParse(_gstController.text) ?? 0;
    double pst = double.tryParse(_pstController.text) ?? 0;

    double total = amount + (amount * gst / 100) + (amount * pst / 100);
    _totalController.text = total.toStringAsFixed(2);
    updateCredit();
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.order.amount.toStringAsFixed(2),
    );
    updateTotal();
    updateCredit();
    fetchMiddlemen();
  }

  // Errors
  String? gstError;
  String? pstError;
  String? paidError;
  String? middlemanPaidError;
  String? creditError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.onSurfaceVariant.withAlpha(50),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      title: "Amount",
                      textController: _amountController,
                      description: "Total amount of sale",
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "GST",
                      textController: _gstController,
                      description: "GST Percent on the total sale",
                      error: gstError,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            gstError = "GST cannot be empty";
                          });
                        } else if (double.tryParse(value) == null) {
                          setState(() {
                            gstError = "GST must be a number";
                          });
                        } else {
                          setState(() {
                            gstError = null;
                          });
                        }
                        updateTotal();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "PST",
                      textController: _pstController,
                      description: "PST Percent on the total sale",
                      error: pstError,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            pstError = "PST cannot be empty";
                          });
                        } else if (double.tryParse(value) == null) {
                          setState(() {
                            pstError = "PST must be a number";
                          });
                        } else {
                          setState(() {
                            pstError = null;
                          });
                        }
                        updateTotal();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Sources",
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<BalanceType>(
                          items: [
                            DropdownMenuItem(
                              value: BalanceType.cash,
                              child: Text(balanceTypeTitles[BalanceType.cash]!),
                            ),
                            DropdownMenuItem(
                              value: BalanceType.creditCard,
                              child: Text(
                                balanceTypeTitles[BalanceType.creditCard]!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: BalanceType.bank,
                              child: Text(balanceTypeTitles[BalanceType.bank]!),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              paymentSource = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Select Payment Source",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              Divider(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      title: "Total",
                      textController: _totalController,
                      description: "Total amount of sale",
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "Paid",
                      textController: _paidController,
                      description: "Total amount paid",
                      error: paidError,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            paidError = "Paid cannot be empty";
                          });
                        } else if (double.tryParse(value) == null) {
                          setState(() {
                            paidError = "Paid must be a number";
                          });
                        } else {
                          setState(() {
                            paidError = null;
                          });
                        }
                        updateCredit();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "Credit",
                      textController: _creditController,
                      description: "Total amount credit",
                      isReadOnly: true,
                      error: creditError,
                      onChanged: (value) {
                        if (double.tryParse(value) == null) {
                          setState(() {
                            creditError = "Credit must be a number";
                          });
                        } else {
                          setState(() {
                            creditError = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SearchableDropdown<Middleman>(
                      isMandatory: false,
                      title: "Middleman",
                      description: "The middleman for this sale",
                      items: middlemen,
                      selectedItem: selectedMiddleman,
                      onChanged: (middleman) {
                        setState(() {
                          selectedMiddleman = middleman;
                          if (middleman != null) {
                            _middlemanTotalController.text = middleman
                                .commission
                                .toStringAsFixed(2);
                            _middlemanPaidController.text = "0.00";
                            _middlemancreditController.text = middleman
                                .commission
                                .toStringAsFixed(2);
                          } else {
                            _middlemanTotalController.clear();
                            _middlemanPaidController.clear();
                            _middlemancreditController.clear();
                          }
                          updateMiddlemanCredit();
                        });
                      },
                      getLabel: (middleman) => middleman.name,
                      onClear: () {
                        setState(() {
                          selectedMiddleman = null;
                          _middlemanTotalController.clear();
                          _middlemanPaidController.clear();
                          _middlemancreditController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "Total",
                      isMandatory: selectedMiddleman != null,
                      textController: _middlemanTotalController,
                      description: "Middleman Commission",
                      isReadOnly: selectedMiddleman == null,
                      error: creditError,
                      onChanged: (value) {
                        if (double.tryParse(value) == null) {
                          setState(() {
                            creditError = "Total amount must be a number";
                          });
                        } else {
                          setState(() {
                            creditError = null;
                          });
                        }
                        updateMiddlemanCredit();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "Paid",
                      isMandatory: selectedMiddleman != null,
                      textController: _middlemanPaidController,
                      description: "Total amount paid",
                      isReadOnly: selectedMiddleman == null,
                      error: middlemanPaidError,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            middlemanPaidError = "Paid cannot be empty";
                          });
                        } else if (double.tryParse(value) == null) {
                          setState(() {
                            middlemanPaidError = "Paid must be a number";
                          });
                        } else {
                          setState(() {
                            middlemanPaidError = null;
                          });
                        }
                        updateMiddlemanCredit();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      isMandatory: selectedMiddleman != null,
                      title: "Credit",
                      textController: _middlemancreditController,
                      description: "Total amount credit",
                      isReadOnly: true,
                      error: creditError,
                      onChanged: (value) {
                        if (double.tryParse(value) == null) {
                          setState(() {
                            creditError = "Credit must be a number";
                          });
                        } else {
                          setState(() {
                            creditError = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onCancel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        (!validate())
                            ? null
                            : () async {
                              final sale = Sale(
                                orderNumber: widget.order.orderNumber!,
                                phones: widget.order.phones!,
                                originalPrice:
                                    widget.order.originalPrice ?? 0.0,
                                customerRef: widget.order.scref!,
                                amount: widget.order.amount,
                                customerName: widget.order.scName,
                                gst: double.parse(_gstController.text),
                                pst: double.parse(_pstController.text),
                                paymentSource: paymentSource!,
                                date: widget.order.date!,
                                total:
                                    double.tryParse(_totalController.text) ??
                                    0.0,
                                paid:
                                    double.tryParse(_paidController.text) ??
                                    0.0,
                                credit:
                                    double.tryParse(_creditController.text) ??
                                    0.0,
                                middlemanRef:
                                    selectedMiddleman?.snapshot?.reference,
                                mTotal:
                                    double.tryParse(
                                      _middlemanTotalController.text,
                                    ) ??
                                    0.0,
                                mPaid:
                                    double.tryParse(
                                      _middlemanPaidController.text,
                                    ) ??
                                    0.0,
                                mCredit:
                                    double.tryParse(
                                      _middlemancreditController.text,
                                    ) ??
                                    0.0,
                              );
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );
                              try {
                                await createSale(widget.order, sale);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Sale saved successfully"),
                                    ),
                                  );
                                  widget.onSubmit();
                                  Navigator.pop(context);

                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      TextEditingController noteController =
                                          TextEditingController();
                                      TextEditingController
                                      adjustmentController =
                                          TextEditingController();
                                      String? adjustmentError;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: Text(
                                              'Generate Bill',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                            ),
                                            content: Container(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.6,
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.4,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CustomTextField(
                                                    title: "Notes",
                                                    textController:
                                                        noteController,
                                                    description:
                                                        "This will be visible on the bill",
                                                  ),
                                                  const SizedBox(height: 8),
                                                  CustomTextField(
                                                    title: "Adjustment",
                                                    error: adjustmentError,
                                                    textController:
                                                        adjustmentController,
                                                    onChanged: (p0) {
                                                      setState(() {
                                                        if (p0.trim().isEmpty) {
                                                          adjustmentError =
                                                              null;
                                                          return;
                                                        }

                                                        try {
                                                          double.parse(p0);
                                                          adjustmentError =
                                                              null;
                                                        } catch (_) {
                                                          adjustmentError =
                                                              "Invalid number";
                                                        }
                                                      });
                                                    },
                                                    description:
                                                        "This will be subtracred from the total amount",
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    adjustmentError == null
                                                        ? () async {
                                                          // Get customer
                                                          Customer customer =
                                                              Customer.fromFirestore(
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .doc(
                                                                      widget
                                                                          .order
                                                                          .scref!
                                                                          .path,
                                                                    )
                                                                    .get(),
                                                              );
                                                          // Proceed to generate the bill
                                                          generateBill(
                                                            sale: sale,
                                                            customer: customer,
                                                            phones:
                                                                widget
                                                                    .order
                                                                    .phoneList,
                                                            note:
                                                                noteController
                                                                        .text
                                                                        .trim()
                                                                        .isNotEmpty
                                                                    ? noteController
                                                                        .text
                                                                        .trim()
                                                                    : null,
                                                            adjustment:
                                                                adjustmentController
                                                                        .text
                                                                        .trim()
                                                                        .isNotEmpty
                                                                    ? double.parse(
                                                                      adjustmentController
                                                                          .text
                                                                          .trim(),
                                                                    )
                                                                    : null,
                                                          );
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        }
                                                        : null,
                                                child: const Text('Generate'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      backgroundColor: colorScheme.primary,
                    ),
                    child: Text(
                      "Add Sale",
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool validate() {
    bool basicValidation =
        gstError == null &&
        pstError == null &&
        paidError == null &&
        creditError == null &&
        _amountController.text.trim().isNotEmpty &&
        _totalController.text.trim().isNotEmpty &&
        paymentSource != null &&
        _gstController.text.trim().isNotEmpty &&
        _pstController.text.trim().isNotEmpty &&
        _paidController.text.trim().isNotEmpty &&
        _creditController.text.trim().isNotEmpty;

    if (selectedMiddleman == null) {
      return basicValidation;
    }

    return basicValidation &&
        _middlemanTotalController.text.trim().isNotEmpty &&
        _middlemanPaidController.text.trim().isNotEmpty &&
        _middlemancreditController.text.trim().isNotEmpty;
  }
}
