import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiltersDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final bool isDateRangeActive;
  final bool isPriceFilterActive;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FiltersDialog({
    super.key,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    required this.isDateRangeActive,
    required this.isPriceFilterActive,
    required this.onApplyFilters,
  });

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  late DateTime? startDate;
  late DateTime? endDate;
  late bool isDateRangeActive;
  late bool isPriceFilterActive;

  double minPossibleAmount = 0;
  double maxPossibleAmount = 10000;
  late RangeValues selectedRange;

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate;
    endDate = widget.endDate;
    isDateRangeActive = widget.isDateRangeActive;
    isPriceFilterActive = widget.isPriceFilterActive;

    selectedRange = RangeValues(
      widget.minAmount?.toDouble() ?? minPossibleAmount,
      widget.maxAmount?.toDouble() ?? maxPossibleAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_list,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSection(colorScheme),
            const SizedBox(height: 20),
            _buildAmountRangeSection(colorScheme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearAllFilters,
          child: Text(
            'Clear All',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Apply Filters',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker('Start Date', startDate, (date) {
                  setState(() {
                    startDate = date;
                    isDateRangeActive = true;
                  });
                }, colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker('End Date', endDate, (date) {
                  setState(() {
                    endDate = date;
                    isDateRangeActive = true;
                  });
                }, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color:
                selectedDate != null
                    ? colorScheme.primary
                    : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color:
                  selectedDate != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(selectedDate)
                  : label,
              style: TextStyle(
                fontSize: 14,
                color:
                    selectedDate != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                fontWeight:
                    selectedDate != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRangeSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Amount Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.2),
              valueIndicatorColor: colorScheme.primary,
              valueIndicatorTextStyle: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: RangeSlider(
              values: selectedRange,
              min: minPossibleAmount,
              max: maxPossibleAmount,
              divisions: 100,
              labels: RangeLabels(
                '₹${selectedRange.start.toStringAsFixed(0)}',
                '₹${selectedRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  selectedRange = values;
                  isPriceFilterActive = true;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountLabel(
                '₹${selectedRange.start.toStringAsFixed(0)}',
                colorScheme,
              ),
              _buildAmountLabel(
                '₹${selectedRange.end.toStringAsFixed(0)}',
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountLabel(String amount, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        amount,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      isDateRangeActive = false;
      isPriceFilterActive = false;
      selectedRange = RangeValues(minPossibleAmount, maxPossibleAmount);
    });
    Navigator.of(context).pop();
    widget.onApplyFilters({
      'startDate': null,
      'endDate': null,
      'minAmount': null,
      'maxAmount': null,
      'isDateRangeActive': false,
      'isPriceFilterActive': false,
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop();
    widget.onApplyFilters({
      'startDate': startDate,
      'endDate': endDate,
      'minAmount': isPriceFilterActive ? selectedRange.start : null,
      'maxAmount': isPriceFilterActive ? selectedRange.end : null,
      'isDateRangeActive': isDateRangeActive,
      'isPriceFilterActive': isPriceFilterActive,
    });
  }
}
