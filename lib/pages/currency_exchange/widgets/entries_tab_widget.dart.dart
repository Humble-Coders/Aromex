import 'package:aromex/pages/currency_exchange/widgets/entry_row_widget.dart.dart';
import 'package:aromex/pages/currency_exchange/widgets/filters_dialog.dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/balance_calculator_service.dart';

class EntriesTabWidget extends StatefulWidget {
  final List<Map<String, dynamic>> allEntries;
  final List<Map<String, dynamic>> filteredEntries;
  final bool isLoading;
  final List<Map<String, String>> allPeople;
  final Function(List<Map<String, dynamic>>) onUpdateFilters;
  final Function(String) onDeleteEntry;
  final BalanceCalculatorService balanceCalculator;

  const EntriesTabWidget({
    super.key,
    required this.allEntries,
    required this.filteredEntries,
    required this.isLoading,
    required this.allPeople,
    required this.onUpdateFilters,
    required this.onDeleteEntry,
    required this.balanceCalculator,
  });

  @override
  State<EntriesTabWidget> createState() => _EntriesTabWidgetState();
}

class _EntriesTabWidgetState extends State<EntriesTabWidget> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isDateRangeActive = false;
  bool isPriceFilterActive = false;
  double? minAmount;
  double? maxAmount;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
      filterEntries();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterEntries() {
    List<Map<String, dynamic>> baseList =
        searchQuery.isEmpty
            ? widget.allEntries
            : widget.allEntries.where((entry) {
              final person1 = (entry['person1'] ?? '').toLowerCase();
              final person2 = (entry['person2'] ?? '').toLowerCase();
              final notes = (entry['notes'] ?? '').toLowerCase();
              final amount = entry['amount'].toString().toLowerCase();

              return person1.contains(searchQuery) ||
                  person2.contains(searchQuery) ||
                  notes.contains(searchQuery) ||
                  amount.contains(searchQuery);
            }).toList();

    // Apply date range filter
    if (isDateRangeActive) {
      baseList =
          baseList.where((entry) {
            final entryDate = entry['timestamp'] as DateTime;

            if (startDate != null && endDate != null) {
              return entryDate.isAfter(
                    startDate!.subtract(const Duration(days: 1)),
                  ) &&
                  entryDate.isBefore(endDate!.add(const Duration(days: 1)));
            } else if (startDate != null) {
              return entryDate.isAfter(
                startDate!.subtract(const Duration(days: 1)),
              );
            } else if (endDate != null) {
              return entryDate.isBefore(endDate!.add(const Duration(days: 1)));
            }
            return true;
          }).toList();
    }

    // Apply amount range filter
    if (isPriceFilterActive) {
      baseList =
          baseList.where((entry) {
            final amount = entry['amount'] as double;

            if (minAmount != null && maxAmount != null) {
              return amount >= minAmount! && amount <= maxAmount!;
            } else if (minAmount != null) {
              return amount >= minAmount!;
            } else if (maxAmount != null) {
              return amount <= maxAmount!;
            }
            return true;
          }).toList();
    }

    widget.onUpdateFilters(baseList);
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FiltersDialog(
            startDate: startDate,
            endDate: endDate,
            minAmount: minAmount,
            maxAmount: maxAmount,
            isDateRangeActive: isDateRangeActive,
            isPriceFilterActive: isPriceFilterActive,
            onApplyFilters: (filters) {
              setState(() {
                startDate = filters['startDate'];
                endDate = filters['endDate'];
                minAmount = filters['minAmount'];
                maxAmount = filters['maxAmount'];
                isDateRangeActive = filters['isDateRangeActive'];
                isPriceFilterActive = filters['isPriceFilterActive'];
              });
              filterEntries();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilter(colorScheme),
          if (isDateRangeActive || isPriceFilterActive) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
          const SizedBox(height: 20),
          Expanded(
            child:
                widget.filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : // In entries_tab_widget.dart, update the ListView.builder:
                    ListView.builder(
                      itemCount: widget.filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = widget.filteredEntries[index];
                        return EntryRowWidget(
                          entry: entry,
                          allPeople: widget.allPeople,
                          allEntries: widget.allEntries, // ADD THIS LINE
                          onDelete: widget.onDeleteEntry,
                          balanceCalculator: widget.balanceCalculator,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by person, amount or notes...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color:
                (isDateRangeActive || isPriceFilterActive)
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  (isDateRangeActive || isPriceFilterActive)
                      ? colorScheme.primary
                      : Colors.grey.shade200,
            ),
          ),
          child: IconButton(
            onPressed: _showFiltersDialog,
            icon: Icon(
              Icons.filter_list,
              color:
                  (isDateRangeActive || isPriceFilterActive)
                      ? colorScheme.primary
                      : Colors.grey.shade600,
            ),
            tooltip: 'Filters',
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isDateRangeActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  '${startDate != null ? DateFormat('dd/MM').format(startDate!) : ''} - ${endDate != null ? DateFormat('dd/MM').format(endDate!) : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                      isDateRangeActive = false;
                    });
                    filterEntries();
                  },
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        if (isPriceFilterActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${minAmount != null ? NumberFormat('#,##0').format(minAmount!) : '0'} - ₹${maxAmount != null ? NumberFormat('#,##0').format(maxAmount!) : '10000'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minAmount = null;
                      maxAmount = null;
                      isPriceFilterActive = false;
                    });
                    filterEntries();
                  },
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_exchange,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding a new transaction',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
