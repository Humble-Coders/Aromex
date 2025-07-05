import 'package:flutter/material.dart';

class AddCommissionDialog extends StatefulWidget {
  final String? selectedP1;
  final String? selectedP2;
  final String selectedRateCurrency;
  final TextEditingController commissionController;
  final Function(String) onCommissionPersonSelected;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<String> availablePersons = [];
    if (widget.selectedP1 != null) availablePersons.add(widget.selectedP1!);
    if (widget.selectedP2 != null) availablePersons.add(widget.selectedP2!);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.add_circle, color: colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Add Commission',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select person and enter commission amount:',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCommissionPerson,
                hint: const Text(
                  'Select Person',
                  style: TextStyle(fontSize: 14),
                ),
                isExpanded: true,
                items:
                    availablePersons
                        .map(
                          (person) => DropdownMenuItem<String>(
                            value: person,
                            child: Text(
                              person,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCommissionPerson = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: widget.commissionController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Commission Amount',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceVariant,
                ),
                child: Text(
                  widget.selectedRateCurrency,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              selectedCommissionPerson != null &&
                      widget.commissionController.text.isNotEmpty
                  ? () {
                    widget.onCommissionPersonSelected(
                      selectedCommissionPerson!,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Commission added for $selectedCommissionPerson',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
