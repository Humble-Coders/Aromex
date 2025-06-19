import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class UpdateTotalOweDue extends StatefulWidget {
  const UpdateTotalOweDue({
    super.key,
    required this.title,
    required this.oweAmount,
    required this.dueAmount,
    required this.updatedAt,
    required this.icon,
    this.oweBalance,
    this.dueBalance,
  });
  final String title;
  final double oweAmount;
  final double dueAmount;
  final String updatedAt;
  final Widget icon;
  final Balance? oweBalance;
  final Balance? dueBalance;

  @override
  State<UpdateTotalOweDue> createState() => _UpdateTotalOweDueState();
}

class _UpdateTotalOweDueState extends State<UpdateTotalOweDue> {
  late final TextEditingController oweController;
  late final TextEditingController dueController;
  late final TextEditingController notesController;

  String? newOweError;
  String? newDueError;
  bool isLoading = false; // Added loading state

  @override
  void initState() {
    super.initState();
    oweController = TextEditingController(text: widget.oweAmount.toString());
    dueController = TextEditingController(text: widget.dueAmount.toString());
    notesController = TextEditingController(
      text: (widget.oweBalance?.note ?? widget.dueBalance?.note) ?? '',
    );
  }

  @override
  void dispose() {
    oweController.dispose();
    dueController.dispose();
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
                            Row(
                              children: [
                                Text(
                                  formatCurrency(
                                    widget.oweAmount,
                                    showTrail: true,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontFamily: 'Nunito',
                                    fontVariations: [
                                      const FontVariation('wght', 700),
                                    ],
                                    color:
                                        widget.oweAmount < 0
                                            ? const Color.fromRGBO(
                                              244,
                                              67,
                                              54,
                                              1,
                                            )
                                            : const Color(0xFF166534),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatCurrency(
                                    widget.dueAmount,
                                    showTrail: true,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontFamily: 'Nunito',
                                    fontVariations: [
                                      const FontVariation('wght', 700),
                                    ],
                                    color:
                                        widget.dueAmount < 0
                                            ? const Color.fromRGBO(
                                              244,
                                              67,
                                              54,
                                              1,
                                            )
                                            : const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
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
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        title: "Total Owe",
                        textController: oweController,
                        description: "Enter the new value",
                        isMandatory: true,
                        error: newOweError,
                        onChanged: (value) {
                          setState(() {
                            newOweError = null;
                            final parsedValue = double.tryParse(value.trim());
                            if (parsedValue == null) {
                              newOweError = "Please enter a valid amount";
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        title: "Total Due",
                        textController: dueController,
                        description: "Enter the new value",
                        isMandatory: true,
                        error: newDueError,
                        onChanged: (value) {
                          setState(() {
                            newDueError = null;
                            final parsedValue = double.tryParse(value.trim());
                            if (parsedValue == null) {
                              newDueError = "Please enter a valid amount";
                            }
                          });
                        },
                      ),
                    ),
                  ],
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
                                  final newOweText = oweController.text.trim();
                                  if (newOweText.isEmpty) return;

                                  final parsedOweAmount = double.tryParse(
                                    newOweText,
                                  );
                                  if (parsedOweAmount == null) return;
                                  final newDueText = dueController.text.trim();
                                  if (newDueText.isEmpty) return;
                                  final parsedDueAmount = double.tryParse(
                                    newDueText,
                                  );
                                  if (parsedDueAmount == null) return;
                                  final note =
                                      notesController.text.trim().isEmpty
                                          ? null
                                          : notesController.text.trim();

                                  if (widget.oweBalance != null) {
                                    await widget.oweBalance!.setAmount(
                                      parsedOweAmount,
                                      note: note,
                                    );
                                  }
                                  if (widget.dueBalance != null) {
                                    await widget.dueBalance!.setAmount(
                                      parsedDueAmount,
                                      note: note,
                                    );
                                  }

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
    return oweController.text.trim().isNotEmpty &&
        dueController.text.trim().isNotEmpty &&
        newOweError == null &&
        newDueError == null;
  }
}
