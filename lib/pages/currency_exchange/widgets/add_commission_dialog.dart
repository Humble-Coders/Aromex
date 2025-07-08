import 'package:flutter/material.dart';

class AddCommissionDialog extends StatefulWidget {
  final String? selectedP1;
  final String? selectedP2;
  final String selectedRateCurrency;
  final TextEditingController commissionController;
  final Function(String, String)
  onCommissionPersonSelected; // Added currency parameter

  const AddCommissionDialog({
    super.key,
    required this.selectedP1,
    required this.selectedP2,
    required this.selectedRateCurrency,
    required this.commissionController,
    required this.onCommissionPersonSelected,
  });

  @override
  State<AddCommissionDialog> createState() => _AddCommissionDialogState();
}

class _AddCommissionDialogState extends State<AddCommissionDialog> {
  String? selectedCommissionPerson;
  String selectedCommissionCurrency = 'USD'; // Default currency

  final List<String> currencies = ['USD', 'INR', 'AED'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    List<String> availablePersons = [];
    if (widget.selectedP1 != null && widget.selectedP1!.isNotEmpty) {
      availablePersons.add(widget.selectedP1!);
    }
    if (widget.selectedP2 != null &&
        widget.selectedP2!.isNotEmpty &&
        widget.selectedP2 != widget.selectedP1) {
      availablePersons.add(widget.selectedP2!);
    }

    // Remove duplicates just in case
    availablePersons = availablePersons.toSet().toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.1,
        vertical: size.height * 0.15,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.monetization_on_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Commission',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select person and enter commission details',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person Selection
                  Text(
                    'Select Person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCommissionPerson,
                        hint: Text(
                          'Choose a person',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        items:
                            availablePersons.map((person) {
                              return DropdownMenuItem<String>(
                                value: person,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      person,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCommissionPerson = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amount and Currency Row
                  Text(
                    'Commission Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Amount Input
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                          child: TextField(
                            controller: widget.commissionController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.6,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.currency_exchange,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Currency Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCommissionCurrency,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                            items:
                                currencies.map((currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(
                                      currency,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCommissionCurrency = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed:
                        selectedCommissionPerson != null &&
                                widget.commissionController.text.isNotEmpty
                            ? () {
                              widget.onCommissionPersonSelected(
                                selectedCommissionPerson!,
                                selectedCommissionCurrency,
                              );
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Commission added for $selectedCommissionPerson',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Commission',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
