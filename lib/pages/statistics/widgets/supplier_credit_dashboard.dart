import 'package:aromex/pages/statistics/widgets/summary_card.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aromex/models/supplier.dart';

class SupplierCreditDashboard extends StatefulWidget {
  const SupplierCreditDashboard({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<SupplierCreditDashboard> createState() => _SupplierCreditDashboard();
}

class _SupplierCreditDashboard extends State<SupplierCreditDashboard> {
  String selectedPeriod = 'Day';
  String? selectedMonth;
  String searchQuery = '';
  String sortBy = 'Amount';
  bool sortAscending = false;
  bool isLoading = true;
  int? selectedYear;
  DateTime? selectedDate;

  final List<String> periods = ['Day', 'Month', 'Year'];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<String> sortOptions = ['Amount', 'Supplier', 'Date'];

  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(6, (index) => currentYear - index);
  }

  List<Supplier> allSuppliers = [];
  List<Supplier> filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    fetchCreditBalanceData();
  }

  Future<void> fetchCreditBalanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection(Supplier.collectionName)
              .get();

      final suppliers =
          querySnapshot.docs
              .map((doc) => Supplier.fromFirestore(doc))
              .where((supplier) => supplier.balance != 0)
              .toList();

      setState(() {
        allSuppliers = suppliers;
        isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      print('Error fetching suppliers: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading supplier data: $e')),
        );
      }
    }
  }

  DateTimeRange getDateRange() {
    final now = DateTime.now();
    DateTime start, end;

    switch (selectedPeriod) {
      case 'Day':
        final targetDate = selectedDate ?? now;
        start = DateTime(targetDate.year, targetDate.month, targetDate.day);
        end = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          23,
          59,
          59,
        );
        break;
      case 'Month':
        if (selectedMonth != null) {
          final monthIndex = months.indexOf(selectedMonth!) + 1;
          final year = selectedYear ?? now.year;
          start = DateTime(year, monthIndex, 1);
          end = DateTime(year, monthIndex + 1, 0, 23, 59, 59);
        } else {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
        break;
      case 'Year':
        final year = selectedYear ?? now.year;
        start = DateTime(year, 1, 1);
        end = DateTime(year, 12, 31, 23, 59, 59);
        break;
      default:
        final targetDate = selectedDate ?? now;
        start = DateTime(targetDate.year, targetDate.month, targetDate.day);
        end = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          23,
          59,
          59,
        );
    }

    return DateTimeRange(start: start, end: end);
  }

  void _applyFiltersAndSort() {
    setState(() {
      final dateRange = getDateRange();

      // Filter by search query AND date range
      filteredSuppliers =
          allSuppliers.where((supplier) {
            // Search filter
            bool matchesSearch = searchQuery.isEmpty;
            if (!matchesSearch) {
              final searchLower = searchQuery.toLowerCase();
              matchesSearch =
                  supplier.name.toLowerCase().contains(searchLower) ||
                  supplier.phone.toLowerCase().contains(searchLower) ||
                  supplier.email.toLowerCase().contains(searchLower);
            }

            // Date filter - check if supplier was created or updated within the date range
            bool matchesDate = true;
            if (selectedPeriod != 'All') {
              final supplierDate =
                  supplier.updatedAt?.toDate() ?? supplier.createdAt;
              matchesDate =
                  supplierDate.isAfter(
                    dateRange.start.subtract(Duration(days: 1)),
                  ) &&
                  supplierDate.isBefore(dateRange.end.add(Duration(days: 1)));
            }

            return matchesSearch && matchesDate;
          }).toList();

      // Sort items
      filteredSuppliers.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'Amount':
            comparison = a.balance.abs().compareTo(b.balance.abs());
            break;
          case 'Supplier':
            comparison = a.name.compareTo(b.name);
            break;
          case 'Date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
        }
        return sortAscending ? comparison : -comparison;
      });
    });
  }

  void _onPeriodChanged(String period) {
    setState(() {
      selectedPeriod = period;
      if (period != 'Month') {
        selectedMonth = null;
      }
      if (period != 'Year' && period != 'Month') {
        selectedYear = null;
      }
      if (period != 'Day') {
        selectedDate = null;
      }
    });

    _applyFiltersAndSort();
  }

  void _onMonthChanged(String? month) {
    setState(() {
      selectedMonth = month;
    });

    _applyFiltersAndSort();
  }

  void _onYearChanged(int? year) {
    setState(() {
      selectedYear = year;
    });

    _applyFiltersAndSort();
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      selectedDate = date;
    });

    _applyFiltersAndSort();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final totalItems = filteredSuppliers.length;
    final totalOwed = filteredSuppliers.fold<double>(
      0,
      (sum, supplier) => sum + supplier.balance.abs(),
    );
    final averageOwed = totalItems > 0 ? totalOwed / totalItems : 0.0;
    final highestDebt =
        filteredSuppliers.isEmpty
            ? 0.0
            : filteredSuppliers
                .map((supplier) => supplier.balance.abs())
                .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Card(
        margin: const EdgeInsets.all(12),
        color: colorScheme.secondary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Controls Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  // Period Selector
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          periods.map((period) {
                            final isSelected = selectedPeriod == period;
                            return InkWell(
                              onTap: () => _onPeriodChanged(period),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  period,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color:
                                        isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date Selector for Day
                  if (selectedPeriod == 'Day')
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              selectedDate != null
                                  ? DateFormat.yMMMd().format(selectedDate!)
                                  : 'Select Date',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Month Selector
                  if (selectedPeriod == 'Month')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        hint: Text('Select Month', style: textTheme.bodyMedium),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items:
                            months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                        onChanged: _onMonthChanged,
                      ),
                    ),
                  // Year Selector
                  if (selectedPeriod == 'Year' ||
                      selectedPeriod == 'Month') ...[
                    if (selectedPeriod == 'Month') const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: selectedYear,
                        hint: Text('Select Year', style: textTheme.bodyMedium),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items:
                            years.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }).toList(),
                        onChanged: _onYearChanged,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Search and Controls Row
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (value) {
                          searchQuery = value;
                          _applyFiltersAndSort();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search Suppliers',
                          prefixIcon: const Icon(Icons.search),
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
                    const SizedBox(width: 16),
                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort),
                          const SizedBox(width: 8),
                          Text('Sort by: '),
                          DropdownButton<String>(
                            value: sortBy,
                            underline: const SizedBox(),
                            items:
                                sortOptions.map((option) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => sortBy = value!);
                              _applyFiltersAndSort();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            onPressed: () {
                              setState(() => sortAscending = !sortAscending);
                              _applyFiltersAndSort();
                            },
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Refresh Button
                    IconButton(
                      onPressed: fetchCreditBalanceData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              if (isLoading)
                const Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Total Suppliers',
                        value: totalItems.toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Total Owed',
                        value: formatCurrency(totalOwed),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Average Debt',
                        value: formatCurrency(averageOwed),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Highest Debt',
                        value: formatCurrency(highestDebt),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Credit Balance Section Title
              Text(
                'Credit Balance',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Credit Balance Table
              GenericCustomTable<Supplier>(
                entries: [...filteredSuppliers],
                headers: [
                  'Name',
                  'Phone',
                  'Email',
                  'Amount Owed',
                  'Status',
                  'Last Updated',
                ],
                valueGetters: [
                  (supplier) => supplier.name,
                  (supplier) => supplier.phone,
                  (supplier) => supplier.email.isEmpty ? 'N/A' : supplier.email,
                  (supplier) => formatCurrency(supplier.balance.abs()),
                  (supplier) =>
                      supplier.balance > 0
                          ? 'We Owe'
                          : supplier.balance < 0
                          ? 'They Owe'
                          : 'Settled',
                  (supplier) => DateFormat.yMd().format(
                    supplier.updatedAt?.toDate() ?? supplier.createdAt,
                  ),
                ],
                onTap: (supplier) {
                  // Handle tap - show detailed view
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Supplier Details'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${supplier.name}'),
                              const SizedBox(height: 8),
                              Text('Phone: ${supplier.phone}'),
                              const SizedBox(height: 8),
                              if (supplier.email.isNotEmpty) ...[
                                Text('Email: ${supplier.email}'),
                                const SizedBox(height: 8),
                              ],
                              if (supplier.address.isNotEmpty) ...[
                                Text('Address: ${supplier.address}'),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                'Balance: ${formatCurrency(supplier.balance)}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Created: ${DateFormat.yMMMd().format(supplier.createdAt)}',
                              ),
                              if (supplier.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notes: ${supplier.notes}'),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
