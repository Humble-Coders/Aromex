import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateCredit extends StatefulWidget {
  const UpdateCredit({
    super.key,
    required this.title,
    required this.amount,
    required this.updatedAt,
    required this.icon,
    required this.documentId,
    required this.collectionName,
    this.onBalanceUpdated,
  });
  
  final String title;
  final double amount;
  final String updatedAt;
  final Widget icon;
  final String documentId;
  final String collectionName; 
  final VoidCallback? onBalanceUpdated;

  @override
  State<UpdateCredit> createState() => _UpdateCreditState();
}

class _UpdateCreditState extends State<UpdateCredit> {
  late final TextEditingController textController;

  String? newAmountError;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.amount.toString());
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _updateBalance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final newAmountText = textController.text.trim();
      if (newAmountText.isEmpty) return;

      final parsedAmount = double.tryParse(newAmountText);
      if (parsedAmount == null) return;

      // Update balance in Firestore
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.documentId)
          .update({
        'balance': parsedAmount,
        'updatedAt': Timestamp.now(),
      });

      setState(() {
        isLoading = false;
      });

      if (context.mounted) {
        Navigator.pop(context);
        
        // Call the callback to refresh the parent widget
        widget.onBalanceUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Balance updated successfully!"),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
            content: Text("Failed to update balance: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
                                color: widget.amount < 0
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading
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
                      onPressed: (!validate() || isLoading) ? null : _updateBalance,
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