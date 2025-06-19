import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/transaction.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class UpdateBalanceCard extends StatefulWidget {
  const UpdateBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.updatedAt,
    required this.icon,
    required this.balance,
  });
  final String title;
  final double amount;
  final String updatedAt;
  final Widget icon;
  final Balance balance;

  @override
  State<UpdateBalanceCard> createState() => _UpdateBalanceCardState();
}

class _UpdateBalanceCardState extends State<UpdateBalanceCard> {
  late final TextEditingController textController;
  late final TextEditingController notesController;

  String? newAmountError;
  bool isLoading = false; // Added loading state

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.amount.toString());
    notesController = TextEditingController(text: widget.balance.note ?? '');
  }

  @override
  void dispose() {
    textController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary.withAlpha(170), width: 1.0),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            right: -10,
            bottom: -10,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                'assets/images/wave.png',
                fit: BoxFit.fill,
                height: 120,
                width: double.infinity,
              ),
            ),
          ),
          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatCurrency(widget.amount, showTrail: true),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: textTheme.headlineMedium?.copyWith(
                                fontFamily: 'Nunito',
                                fontVariations: [
                                  const FontVariation('wght', 700),
                                ],
                                color:
                                    widget.amount < 0
                                        ? const Color.fromRGBO(244, 67, 54, 1)
                                        : const Color(0xFF166534),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Last updated at ${widget.updatedAt}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.secondaryContainer.withAlpha(13),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: widget.icon,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  title: "New Value",
                  textController: textController,
                  description: "Enter the new value",
                  isMandatory: true,
                  error: newAmountError,
                  onChanged: (value) {
                    setState(() {
                      newAmountError = null;
                      final parsedValue = double.tryParse(value.trim());
                      if (parsedValue == null) {
                        newAmountError = "Please enter a valid amount";
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  title: "Notes",
                  textController: notesController,
                  description: "Enter any notes",
                  isMandatory: false,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                Navigator.pop(context);
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
                          (!validate() || isLoading)
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final newAmountText =
                                      textController.text.trim();
                                  if (newAmountText.isEmpty) return;

                                  final parsedAmount = double.tryParse(
                                    newAmountText,
                                  );
                                  if (parsedAmount == null) return;

                                  final note =
                                      notesController.text.trim().isEmpty
                                          ? null
                                          : notesController.text.trim();

                                  await widget.balance.setAmount(
                                    parsedAmount,
                                    note: note,
                                    transactionType: TransactionType.self,
                                    category:
                                        widget.balance.type ==
                                                BalanceType.expenseRecord
                                            ? "Self"
                                            : null,
                                  );

                                  setState(() {
                                    isLoading = false;
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Balance updated successfully!",
                                        ),
                                        backgroundColor: colorScheme.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Failed to update balance: ${e.toString()}",
                                        ),
                                        backgroundColor: colorScheme.error,
                                      ),
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
                        "Update Value",
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool validate() {
    return textController.text.trim().isNotEmpty && newAmountError == null;
  }
}
