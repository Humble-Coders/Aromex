import 'dart:async';

import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/currency_exchange/widgets/balance_report_tab_widget.dart.dart';
import 'package:aromex/pages/currency_exchange/widgets/entries_tab_widget.dart.dart';
import 'package:aromex/pages/home/main.dart';
import 'package:aromex/services/currency_service.dart.dart';
import 'package:flutter/material.dart';

import '../../services/balance_calculator_service.dart';
import 'widgets/currency_form_widget.dart';

class CurrencyEntryPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Pages)? onPageChange;

  const CurrencyEntryPage({super.key, this.onBack, this.onPageChange});

  @override
  State<CurrencyEntryPage> createState() => _CurrencyEntryPageState();
}

class _CurrencyEntryPageState extends State<CurrencyEntryPage>
    with TickerProviderStateMixin {
  final CurrencyService _currencyService = CurrencyService();
  final BalanceCalculatorService _balanceCalculator =
      BalanceCalculatorService();

  // Tab controller
  TabController? _tabController;

  // Data
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Middleman> middlemen = [];
  List<Person> person = [];
  List<Map<String, String>> allPeople = [];
  List<Map<String, dynamic>> allEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];

  // Loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
      filteredEntries = allEntries;
    } finally {
      setState(() => isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Currency Exchange',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        leading:
            widget.onBack != null
                ? IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                  onPressed: widget.onBack,
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrencyFormWidget(
              allPeople: allPeople,
              onEntryAdded: () {
                _loadAllEntries();
                _showSuccess('Entry added successfully!');
              },
              onError: _showError,
              onPageChange: widget.onPageChange,
            ),
            const SizedBox(height: 20),
            _buildEntriesDataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesDataSection() {
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
              indicatorColor: colorScheme.onPrimary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 18),
                      SizedBox(width: 8),
                      Text('All Entries'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 18),
                      SizedBox(width: 8),
                      Text('Balance Report'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                EntriesTabWidget(
                  allEntries: allEntries,
                  filteredEntries: filteredEntries,
                  isLoading: isLoading,
                  allPeople: allPeople,
                  onUpdateFilters: (filtered) {
                    setState(() {
                      filteredEntries = filtered;
                    });
                  },
                  onDeleteEntry: (entryId) async {
                    await _currencyService.deleteEntry(entryId);
                    _showSuccess('Entry deleted successfully!');
                    _loadAllEntries();
                  },
                  balanceCalculator: _balanceCalculator,
                ),
                BalanceReportTabWidget(
                  allEntries: allEntries,
                  allPeople: allPeople,
                  balanceCalculator: _balanceCalculator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
