import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/sale.dart';
import 'package:aromex/pages/statistics/widgets/summary_card.dart';
import 'package:aromex/util.dart';
import 'package:aromex/widgets/generic_custom_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiddlemanRevenueDashboard extends StatefulWidget {
  const MiddlemanRevenueDashboard({super.key, this.onBack});
  final VoidCallback? onBack;
  @override
  State<MiddlemanRevenueDashboard> createState() => _MiddlemanDashboardState();
}

class _MiddlemanDashboardState extends State<MiddlemanRevenueDashboard> {
  String selectedPeriod = 'Day';
  String? selectedMonth;
  String searchQuery = '';
  String sortBy = 'A to Z';
  bool sortAscending = true;
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
  final List<String> sortOptions = ['A to Z', 'Revenue', 'Date'];

  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(6, (index) => currentYear - index);
  }

  List<Middleman> allMiddlemen = [];
  List<Middleman> filteredMiddlemen = [];
  Map<String, double> middlemanRevenue = {};
  List<Sale> allSales = [];

  @override
  void initState() {
    super.initState();
    fetchMiddlemanData();
  }

  Future<void> fetchMiddlemanData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch middlemen
      final middlemenSnapshot =
          await FirebaseFirestore.instance
              .collection(Middleman.collectionName)
              .get();

      // Fetch ALL sales that have middlemen - we'll filter by date in memory
      final salesQuery =
          await FirebaseFirestore.instance
              .collection(Sale.collectionName)
              .where('middlemanId', isNotEqualTo: null)
              .get();

      // Store all sales
      allSales = salesQuery.docs
          .map((doc) => Sale.fromFirestore(doc))
          .toList();

      // Create middleman list
      List<Middleman> middlemen = [];
      for (var middlemanDoc in middlemenSnapshot.docs) {
        final middleman = Middleman.fromFirestore(middlemanDoc);
        middlemen.add(middleman);
      }

      setState(() {
        allMiddlemen = middlemen;
        isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      print('Error fetching middlemen: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading middleman data: $e')),
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
        end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
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
        end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
    }

    return DateTimeRange(start: start, end: end);
  }

  void _applyFiltersAndSort() {
    setState(() {
      final dateRange = getDateRange();
      
      // Filter sales by date range
      final filteredSales = allSales.where((sale) {
        final saleDate = sale.date; 
        return saleDate.isAfter(dateRange.start.subtract(Duration(days: 1))) &&
               saleDate.isBefore(dateRange.end.add(Duration(days: 1)));
      }).toList();

      // Calculate revenue for each middleman within the date range
      Map<String, double> revenueMap = {};
      for (var sale in filteredSales) {
        if (sale.middlemanRef != null) {
          final middlemanId = sale.middlemanRef!.id;
          final commission = sale.mTotal;
          revenueMap[middlemanId] =
              (revenueMap[middlemanId] ?? 0.0) + commission;
        }
      }

      middlemanRevenue = revenueMap;

      // Filter middlemen by search query
      filteredMiddlemen = allMiddlemen.where((middleman) {
        if (searchQuery.isEmpty) return true;
        
        final searchLower = searchQuery.toLowerCase();
        return middleman.name.toLowerCase().contains(searchLower) ||
            middleman.phone.toLowerCase().contains(searchLower) ||
            middleman.email.toLowerCase().contains(searchLower);
      }).toList();

      // Sort items
      filteredMiddlemen.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'A to Z':
            comparison = a.name.compareTo(b.name);
            break;
          case 'Revenue':
            final aRevenue = middlemanRevenue[a.id] ?? 0.0;
            final bRevenue = middlemanRevenue[b.id] ?? 0.0;
            comparison = bRevenue.compareTo(aRevenue);

            if (comparison == 0) {
              comparison = a.name.compareTo(b.name);
            }
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

    final totalMiddlemen = filteredMiddlemen.length;
    final totalRevenue = filteredMiddlemen.fold<double>(
      0.0,
      (sum, middleman) => sum + (middlemanRevenue[middleman.id] ?? 0.0),
    );
    final averageRevenue =
        totalMiddlemen > 0 ? totalRevenue / totalMiddlemen : 0.0;
    final maxRevenue =
        filteredMiddlemen.isEmpty
            ? 0.0
            : filteredMiddlemen
                .map((middleman) => middlemanRevenue[middleman.id] ?? 0.0)
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          hintText: 'Search Middlemen',
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
                      onPressed: fetchMiddlemanData,
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
                        title: 'Total Middlemen',
                        value: totalMiddlemen.toString(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Total Revenue',
                        value: formatCurrency(totalRevenue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Avg Revenue',
                        value: formatCurrency(averageRevenue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: 'Max Revenue',
                        value: formatCurrency(maxRevenue),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Middlemen Section Title
              Text(
                'Middlemen',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Middlemen Table
              GenericCustomTable<Middleman>(
                entries: [...filteredMiddlemen],
                headers: ['Middleman', 'Revenue'],
                valueGetters: [
                  (middleman) => middleman.name,
                  (middleman) =>
                      formatCurrency(middlemanRevenue[middleman.id] ?? 0.0),
                ],
                onTap: (middleman) {
                  // Handle tap - show detailed view
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Middleman Details'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${middleman.name}'),
                              const SizedBox(height: 8),
                              Text('Phone: ${middleman.phone}'),
                              const SizedBox(height: 8),
                              if (middleman.email.isNotEmpty) ...[
                                Text('Email: ${middleman.email}'),
                                const SizedBox(height: 8),
                              ],
                              if (middleman.address.isNotEmpty) ...[
                                Text('Address: ${middleman.address}'),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                'Commission Rate: ${middleman.commission.toStringAsFixed(2)}%',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Revenue: ${formatCurrency(middlemanRevenue[middleman.id] ?? 0.0)}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Balance: ${formatCurrency(middleman.balance)}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Created: ${DateFormat.yMMMd().format(middleman.createdAt)}',
                              ),
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