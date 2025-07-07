// Import your models
import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/currency_exchange/widgets/currency_form_widget.dart';
import 'package:aromex/pages/currency_exchange/widgets/entry_row_widget.dart.dart';
import 'package:aromex/pages/currency_exchange/widgets/filters_dialog.dart.dart';
// Import your existing services
import 'package:aromex/services/balance_calculator_service.dart';
import 'package:aromex/services/currency_service.dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personName;

  const PersonDetailScreen({super.key, required this.personName});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final BalanceCalculatorService _balanceCalculator =
      BalanceCalculatorService();

  // Data
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Middleman> middlemen = [];
  List<Person> person = [];
  List<Map<String, String>> allPeople = [];
  List<Map<String, dynamic>> allEntries = [];
  List<Map<String, dynamic>> personSpecificEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];

  // Loading state
  bool isLoading = true;

  // Search and filters
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isDateRangeActive = false;
  bool isPriceFilterActive = false;
  double? minAmount;
  double? maxAmount;

  // Person specific balance
  Map<String, double> personBalance = {'INR': 0, 'USD': 0, 'AED': 0};

  @override
  void initState() {
    super.initState();
    _loadInitialData();

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

  Future<void> _loadInitialData() async {
    await Future.wait([
      _currencyService.fetchCustomers().then((data) => customers = data),
      _currencyService.fetchSuppliers().then((data) => suppliers = data),
      _currencyService.fetchMiddlemen().then((data) => middlemen = data),
      _currencyService.fetchPerson().then((data) => person = data),
    ]);

    mergeAllPeople();
    await _loadAllEntries();
  }

  void mergeAllPeople() {
    setState(() {
      allPeople = [
        ...customers.map((c) => {'name': c.name, 'type': 'Customer'}),
        ...suppliers.map((s) => {'name': s.name, 'type': 'Supplier'}),
        ...middlemen.map((m) => {'name': m.name, 'type': 'Middleman'}),
        ...person.map((p) => {'name': p.name, 'type': 'Person'}),
      ];
    });
  }

  Future<void> _loadAllEntries() async {
    setState(() => isLoading = true);
    try {
      allEntries = await _currencyService.loadAllEntries();

      // Filter entries specific to this person
      personSpecificEntries =
          allEntries.where((entry) {
            return entry['person1'] == widget.personName ||
                entry['person2'] == widget.personName;
          }).toList();

      filteredEntries = personSpecificEntries;

      // Calculate person balance using the same service
      await _calculatePersonBalance();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _calculatePersonBalance() async {
    // Use the exact same balance calculation logic
    final balances = await _balanceCalculator.calculateBalanceReport(
      allEntries,
    );

    if (balances.containsKey(widget.personName)) {
      setState(() {
        personBalance = balances[widget.personName]!;
      });
    }
  }

  void filterEntries() {
    List<Map<String, dynamic>> baseList =
        searchQuery.isEmpty
            ? personSpecificEntries
            : personSpecificEntries.where((entry) {
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

    setState(() {
      filteredEntries = baseList;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.personName,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Summary Card
            _buildBalanceSummaryCard(),
            const SizedBox(height: 20),

            // Reuse CurrencyFormWidget with custom defaults
            CurrencyFormWidget(
              allPeople: allPeople,
              onEntryAdded: () {
                _loadAllEntries();
                _showSuccess('Entry added successfully!');
              },
              onError: _showError,
              // Pre-set default values for this person
              // defaultPerson1: 'Myself',
              // defaultPerson2: widget.personName,
            ),
            const SizedBox(height: 20),

            // Entries Section
            _buildEntriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance with ${widget.personName}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPersonType(widget.personName),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceItem('INR', personBalance['INR'] ?? 0),
              _buildBalanceItem('USD', personBalance['USD'] ?? 0),
              _buildBalanceItem('AED', personBalance['AED'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String currency, double balance) {
    final isPositive = balance > 0;
    final isNegative = balance < 0;

    return Column(
      children: [
        Text(
          currency,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${balance >= 0 ? '+' : ''}${NumberFormat('#,##0.00').format(balance)}',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPositive
                ? 'To Receive'
                : isNegative
                ? 'To Pay'
                : 'Settled',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntriesSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${personSpecificEntries.length} entries',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
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
            ),
          ),

          // Active filters display - same as main page
          if (isDateRangeActive || isPriceFilterActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isDateRangeActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
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
              ),
            ),

          // Entries List using the same EntryRowWidget
          Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child:
                isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        // Reuse the same EntryRowWidget
                        return EntryRowWidget(
                          entry: entry,
                          allPeople: allPeople,
                          allEntries:
                              allEntries, // Pass all entries for balance calculation
                          onDelete: (entryId) async {
                            await _currencyService.deleteEntry(entryId);
                            _showSuccess('Entry deleted successfully!');
                            _loadAllEntries();
                          },
                          balanceCalculator: _balanceCalculator,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              'No transactions found',
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
      ),
    );
  }

  String _getPersonType(String personName) {
    final person = allPeople.firstWhere(
      (p) => p['name'] == personName,
      orElse: () => {'type': 'Person'},
    );
    return person['type'] ?? 'Person';
  }
}
