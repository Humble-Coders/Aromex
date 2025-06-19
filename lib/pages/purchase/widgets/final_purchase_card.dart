import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/order.dart';
import 'package:aromex/models/purchase.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:aromex/services/purchase.dart';
import 'package:flutter/material.dart';

class FinalPurchaseCard extends StatefulWidget {
  final Order order;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const FinalPurchaseCard({
    super.key,
    required this.onCancel,
    required this.order,
    required this.onSubmit,
  });

  @override
  State<FinalPurchaseCard> createState() => _FinalPurchaseCardState();
}

class _FinalPurchaseCardState extends State<FinalPurchaseCard> {
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _pstController = TextEditingController();
  late TextEditingController _amountController;
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  BalanceType? paymentSource;

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
  }

  // Errors
  String? gstError;
  String? pstError;
  String? paidError;
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
                      description: "Total amount of purchase",
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      title: "GST",
                      textController: _gstController,
                      description: "GST Percent on the total purchase",
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
                      description: "PST Percent on the total purchase",
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
                      description: "Total amount of purchase",
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
                              final purchase = Purchase(
                                orderNumber: widget.order.orderNumber!,
                                phones: widget.order.phones!,
                                supplierRef: widget.order.scref!,
                                supplierName: widget.order.scName,
                                amount: widget.order.amount,
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
                                await createPurchase(widget.order, purchase);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Purchase saved successfully",
                                      ),
                                    ),
                                  );
                                  widget.onSubmit();
                                  Navigator.pop(context);
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
                      "Add Purchase",
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
    return gstError == null &&
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
  }
}
