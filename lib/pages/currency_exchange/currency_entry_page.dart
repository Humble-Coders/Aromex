import 'dart:async';

import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/currency_exchange/perosndetailscreen.dart';
import 'package:aromex/pages/home/main.dart';
import 'package:aromex/pages/home/pages/add_people.dart';
import 'package:aromex/services/market_price.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyEntryPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Pages)? onPageChange;

  const CurrencyEntryPage({super.key, this.onBack, this.onPageChange});

  @override
  State<CurrencyEntryPage> createState() => _CurrencyEntryPageState();
}

class _CurrencyEntryPageState extends State<CurrencyEntryPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController person1Controller = TextEditingController();
  final TextEditingController person2Controller = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController commissionController = TextEditingController();
  final TextEditingController minAmountController = TextEditingController();
  final TextEditingController maxAmountController = TextEditingController();
  // People data
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Middleman> middlemen = [];
  List<Person> person = [];
  List<Map<String, String>> allPeople = [];

  // Form state
  String? selectedP1;
  String? selectedP2;
  String? selectedFromCurrency = 'INR';
  String? selectedToCurrency = 'USD';
  String? selectedAmountCurrency = 'INR';
  String? selectedRateCurrency = 'USD';
  String? transactionDirection = 'give_to';
  bool isCurrencyExchange = true;

  String? selectedCommissionPerson;
  final List<String> currencies = ['INR', 'USD', 'AED'];

  // Exchange rates
  final Map<String, Map<String, double>> exchangeRates = {
    'INR': {'USD': 0.012, 'AED': 0.044},
    'USD': {'INR': 83.0, 'AED': 3.67},
    'AED': {'INR': 22.6, 'USD': 0.27},
  };
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isDateRangeActive = false;
  bool isPriceFilterActive = false;
  double? minAmount;
  double? maxAmount;
  // Entries data
  List<Map<String, dynamic>> allEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];

  // Loading states
  bool isLoading = true;
  bool isSaving = false;

  // Search and filters

  // Tab controller
  TabController? _tabController;

  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
      filterEntries();
    });

    _updateExchangeRate();
    fetchCustomers();
    fetchSuppliers();
    fetchPerson();
    fetchMiddlemen();
    _loadAllEntries();
  }

  @override
  void dispose() {
    person1Controller.dispose();
    person2Controller.dispose();
    amountController.dispose();
    exchangeRateController.dispose();
    notesController.dispose();
    searchController.dispose();
    commissionController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> marketRates() async {
    await MarketPriceService.loadMarketRates();
    final Map<String, double> marketRates = MarketPriceService.marketRates;
    print(marketRates);
  }

  double? getMarketRate(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    return MarketPriceService.marketRates[key];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
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
            _buildOptimizedCurrencyForm(),
            const SizedBox(height: 20),
            _buildEntriesDataSection(),
          ],
        ),
      ),
    );
  }

  void _updateExchangeRate() {
    if (selectedAmountCurrency != null && selectedRateCurrency != null) {
      if (selectedAmountCurrency == selectedRateCurrency) {
        exchangeRateController.text = '1.0';
      } else {
        final rate =
            exchangeRates[selectedAmountCurrency]?[selectedRateCurrency];
        if (rate != null) {
          exchangeRateController.text = rate.toStringAsFixed(4);
        } else {
          exchangeRateController.text = '1.0';
        }
      }
    }
  }

  void fetchCustomers() {
    db
        .collection('Customers')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              customers =
                  snapshot.docs
                      .map((doc) => Customer.fromFirestore(doc))
                      .toList();
              mergeAllPeople();
            });
          });
        })
        .onError((error) {
          _showError(error.toString());
        });
  }

  void fetchSuppliers() {
    db
        .collection('Suppliers')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              suppliers =
                  snapshot.docs
                      .map((doc) => Supplier.fromFirestore(doc))
                      .toList();
              mergeAllPeople();
            });
          });
        })
        .onError((error) {
          _showError(error.toString());
        });
  }

  void fetchPerson() {
    db
        .collection('Person')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            person =
                snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList();
            mergeAllPeople();
          });
        })
        .onError((error) {
          _showError(error.toString());
        });
  }

  void fetchMiddlemen() {
    db
        .collection('Middlemen')
        .snapshots()
        .listen((snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              middlemen =
                  snapshot.docs
                      .map((doc) => Middleman.fromFirestore(doc))
                      .toList();
              mergeAllPeople();
            });
          });
        })
        .onError((error) {
          _showError(error.toString());
        });
  }

  void mergeAllPeople() {
    allPeople = [
      ...customers.map((c) => {'name': c.name, 'type': 'Customer'}),
      ...suppliers.map((s) => {'name': s.name, 'type': 'Supplier'}),
      ...middlemen.map((m) => {'name': m.name, 'type': 'Middleman'}),
      ...person.map((p) => {'name': p.name, 'type': 'Person'}),
    ];
  }

  Future<void> _loadAllEntries() async {
    setState(() => isLoading = true);

    try {
      final entriesSnapshot =
          await _firestore
              .collection('currency_exchanges')
              .orderBy('timestamp', descending: true)
              .get();

      List<Map<String, dynamic>> entries = [];

      for (var doc in entriesSnapshot.docs) {
        final data = doc.data();
        entries.add({
          'id': doc.id,
          'person1': data['person1'] ?? 'Unknown',
          'person2': data['person2'] ?? 'Unknown',
          'direction': data['direction'] ?? 'give_to',
          'fromCurrency': data['fromCurrency'] ?? 'INR',
          'toCurrency': data['toCurrency'] ?? 'USD',
          'amount': data['amount'] ?? 0,
          'exchangeRate': data['exchangeRate'] ?? 1.0,
          'convertedAmount': data['convertedAmount'] ?? 0,
          'commission': data['commission'] ?? 0,
          'commissionPerson': data['commissionPerson'],
          'notes': data['notes'] ?? '',
          'isCurrencyExchange': data['isCurrencyExchange'] ?? true,
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      setState(() {
        allEntries = entries;
        isLoading = false;
      });

      filterEntries();
    } catch (e) {
      _showError('Error loading entries: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  // filterEntries method
  void filterEntries() {
    List<Map<String, dynamic>> baseList =
        searchQuery.isEmpty
            ? allEntries
            : allEntries.where((entry) {
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

  bool _validateForm() {
    if (selectedP1 == null) {
      _showError('Please select Person 1');
      return false;
    }
    if (selectedP2 == null) {
      _showError('Please select Person 2');
      return false;
    }
    if (selectedP1 == selectedP2) {
      _showError('Please select different people for the transaction');
      return false;
    }
    if (amountController.text.trim().isEmpty) {
      _showError('Please enter an amount');
      return false;
    }
    if (isCurrencyExchange && exchangeRateController.text.trim().isEmpty) {
      _showError('Please enter exchange rate');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount greater than 0');
      return false;
    }

    return true;
  }

  Future<void> _confirmEntry() async {
    if (!_validateForm()) return;

    setState(() => isSaving = true);

    try {
      final amount = double.parse(amountController.text.trim());
      final exchangeRate =
          isCurrencyExchange
              ? double.parse(exchangeRateController.text.trim())
              : 1.0;
      final commission =
          double.tryParse(commissionController.text.trim()) ?? 0.0;
      final convertedAmount = amount * exchangeRate;

      final entry = {
        'person1': selectedP1,
        'person2': selectedP2,
        'direction': transactionDirection,
        'fromCurrency': isCurrencyExchange ? selectedAmountCurrency : 'USD',
        'toCurrency': isCurrencyExchange ? selectedRateCurrency : 'USD',
        'amount': amount,
        'exchangeRate': exchangeRate,
        'convertedAmount': convertedAmount,
        'commission': commission,
        'commissionPerson': selectedCommissionPerson,
        'notes': notesController.text.trim(),
        'isCurrencyExchange': isCurrencyExchange,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('currency_exchanges').add(entry);

      setState(() {
        selectedP1 = null;
        selectedP2 = null;
        amountController.clear();
        exchangeRateController.clear();
        commissionController.clear();
        notesController.clear();
        selectedCommissionPerson = null;
      });

      _showSuccess('Entry added successfully!');
      _loadAllEntries();
    } catch (e) {
      _showError('Error saving entry: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showAddCommissionDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    List<String> availablePersons = [];
    if (selectedP1 != null) availablePersons.add(selectedP1!);
    if (selectedP2 != null) availablePersons.add(selectedP2!);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                          controller: commissionController,
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
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
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
                          selectedRateCurrency ?? 'USD',
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
                              commissionController.text.isNotEmpty
                          ? () {
                            Navigator.of(context).pop();
                            _showSuccess(
                              'Commission added for $selectedCommissionPerson',
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
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String entryId) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Entry',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this entry? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntry(entryId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await _firestore.collection('currency_exchanges').doc(entryId).delete();
      _showSuccess('Entry deleted successfully!');
      _loadAllEntries();
    } catch (e) {
      _showError('Error deleting entry: ${e.toString()}');
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

  void _showAddPersonDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPerson()),
    );
  }

  // Enhanced form with better UI
  Widget _buildOptimizedCurrencyForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.currency_exchange,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'New Transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isCurrencyExchange
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Exchange',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isCurrencyExchange
                                ? colorScheme.primary
                                : Colors.grey,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: isCurrencyExchange,
                        onChanged: (value) {
                          setState(() {
                            isCurrencyExchange = value;
                            if (!value) {
                              selectedAmountCurrency =
                                  selectedRateCurrency = 'USD';
                              exchangeRateController.text = '1.0';
                            } else {
                              selectedAmountCurrency = 'INR';
                              selectedRateCurrency = 'USD';
                              _updateExchangeRate();
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main form
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Person 1
                _buildEnhancedDropdown(
                  value: selectedP1,
                  hint: 'From',
                  icon: Icons.person_outline,
                  items: [
                    {'name': 'Myself', 'type': 'You'},
                    ...allPeople,
                  ],
                  onChanged: (value) => setState(() => selectedP1 = value),
                  width: 140,
                ),
                const SizedBox(width: 10),

                // Direction
                _buildDirectionSelector(),
                const SizedBox(width: 10),

                // Person 2
                _buildEnhancedDropdown(
                  value: selectedP2,
                  hint: 'To',
                  icon: Icons.person,
                  items: [
                    {'name': 'Myself', 'type': 'You'},
                    ...allPeople,
                  ],
                  onChanged: (value) => setState(() => selectedP2 = value),
                  width: 140,
                ),
                const SizedBox(width: 10),

                // Currency and Amount
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      if (isCurrencyExchange) ...[
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedAmountCurrency,
                              isExpanded: true,
                              isDense: true,
                              items:
                                  currencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(
                                        currency,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedAmountCurrency = value;
                                  _updateExchangeRate();
                                });
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 70,
                          height: 45,
                          alignment: Alignment.center,
                          child: const Text(
                            'USD',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Amount',
                            hintStyle: TextStyle(fontSize: 13),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Exchange Rate section with dropdowns on both sides
                if (isCurrencyExchange) ...[
                  const SizedBox(width: 10),
                  _buildExchangeRateSection(),
                ],

                const SizedBox(width: 10),

                // Action buttons
                if (isCurrencyExchange) ...[
                  _buildActionButton(
                    icon: Icons.calculate,
                    label:
                        commissionController.text.isEmpty
                            ? 'Commission'
                            : '${commissionController.text}',
                    onPressed: _showAddCommissionDialog,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],

                _buildActionButton(
                  icon: Icons.person_add,
                  onPressed: _showAddPersonDialog,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: isSaving ? null : _confirmEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child:
                      isSaving
                          ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                          : const Text(
                            'Add Entry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ],
            ),
          ),

          // Notes field
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.note_add, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: notesController,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add notes (optional)',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced dropdown with icon
  Widget _buildEnhancedDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
    required double width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint, style: const TextStyle(fontSize: 13)),
                isExpanded: true,
                isDense: true,
                items:
                    items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['name'],
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Direction selector with better UI
  Widget _buildDirectionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: transactionDirection,
            isDense: true,
            items: [
              DropdownMenuItem(
                value: 'give_to',
                child: Row(
                  children: const [
                    Icon(Icons.arrow_forward, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('Give to', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'take_from',
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text('Take from', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            onChanged: (value) => setState(() => transactionDirection = value),
          ),
        ),
      ),
    );
  }

  // Exchange rate section with dropdowns on both sides
  Widget _buildExchangeRateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // From currency dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAmountCurrency,
                isDense: true,
                items:
                    currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAmountCurrency = value;
                    _updateExchangeRate();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.compare_arrows, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: exchangeRateController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // To currency dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRateCurrency,
                isDense: true,
                items:
                    currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRateCurrency = value;
                    _updateExchangeRate();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action button helper
  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
          // Tab Bar with enhanced design
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

          // Tab Views
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [_buildAllEntriesTab(), _buildBalanceReportTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllEntriesTab() {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Row
          Row(
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

          // Active filters display
          if (isDateRangeActive || isPriceFilterActive) ...[
            const SizedBox(height: 12),
            Wrap(
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
                      border: Border.all(color: Colors.blue.shade200, width: 1),
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
          ],

          const SizedBox(height: 20),

          // Entries list in tabular form
          Expanded(
            child:
                filteredEntries.isEmpty
                    ? Center(
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        return FutureBuilder<Widget>(
                          future: _buildTabularEntryRow(entry),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text('Error loading entry row'),
                                ),
                              );
                            }
                            return snapshot.data ?? const SizedBox.shrink();
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // _showFiltersDialog method
  void _showFiltersDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    // Default slider values
    double minPossibleAmount = 0;
    double maxPossibleAmount = 10000;
    RangeValues selectedRange = RangeValues(
      minAmount?.toDouble() ?? minPossibleAmount,
      maxAmount?.toDouble() ?? maxPossibleAmount,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                    // Date Filter Section
                    Container(
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
                              Icon(
                                Icons.date_range,
                                size: 20,
                                color: colorScheme.primary,
                              ),
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
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: startDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        startDate = date;
                                        isDateRangeActive = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color:
                                            startDate != null
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
                                              startDate != null
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          startDate != null
                                              ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(startDate!)
                                              : 'Start Date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                startDate != null
                                                    ? colorScheme.onSurface
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                            fontWeight:
                                                startDate != null
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: endDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        endDate = date;
                                        isDateRangeActive = true;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color:
                                            endDate != null
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
                                              endDate != null
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          endDate != null
                                              ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(endDate!)
                                              : 'End Date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                endDate != null
                                                    ? colorScheme.onSurface
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                            fontWeight:
                                                endDate != null
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount Range with Slider
                    Container(
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
                              Icon(
                                Icons.currency_rupee,
                                size: 20,
                                color: colorScheme.primary,
                              ),
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
                              inactiveTrackColor: colorScheme.primary
                                  .withOpacity(0.2),
                              thumbColor: colorScheme.primary,
                              overlayColor: colorScheme.primary.withOpacity(
                                0.2,
                              ),
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
                                  minAmount = values.start.toDouble();
                                  maxAmount = values.end.toDouble();
                                  isPriceFilterActive = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${selectedRange.start.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${selectedRange.end.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                      isDateRangeActive = false;
                      minAmount = null;
                      maxAmount = null;
                      isPriceFilterActive = false;
                      selectedRange = RangeValues(
                        minPossibleAmount,
                        maxPossibleAmount,
                      );
                    });
                    Navigator.of(context).pop();
                    filterEntries();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    filterEntries();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
          },
        );
      },
    );
  }

  // Tabular entry row with all information in one line
  Future<Widget> _buildTabularEntryRow(Map<String, dynamic> entry) async {
    final colorScheme = Theme.of(context).colorScheme;
    final timestamp = entry['timestamp'] as DateTime;
    final person1 = entry['person1'];
    final person2 = entry['person2'];
    final amount = entry['amount'] as num? ?? 0;
    final convertedAmount = entry['convertedAmount'] as num? ?? 0;
    final fromCurrency = entry['fromCurrency'] ?? '';
    final toCurrency = entry['toCurrency'] ?? '';
    final exchangeRate = entry['exchangeRate'] as num? ?? 0;
    final notes = entry['notes'] ?? '';
    final isCurrencyEntry = entry['isCurrencyExchange'] ?? false;
    final direction = entry['direction'] ?? 'give_to';
    final commission = entry['commission'] as num? ?? 0;
    final commissionPerson = entry['commissionPerson'];

    // Calculate expected profit - FIXED LOGIC
    double expectedProfit = 0;
    String expectedProfitText = '';
    double marketRate = 0;
    double yourRate = 0;

    if (isCurrencyEntry && exchangeRate > 0) {
      marketRate = getMarketRate(fromCurrency, toCurrency) ?? 0;
      yourRate = exchangeRate.toDouble();

      if (marketRate > 0) {
        // Calculate the difference in rates
        double rateDifference = yourRate - marketRate;
        // Calculate profit/loss based on the amount exchanged
        expectedProfit = amount.toDouble() * rateDifference;

        // Format the expected profit text
        if (expectedProfit.abs() > 0.01) {
          expectedProfitText =
              '${expectedProfit > 0 ? '+' : ''}${NumberFormat('#,##0.00').format(expectedProfit)}';
        }
      }
    }

    // Calculate final balance including commission
    Map<String, Map<String, double>> finalBalances =
        await _calculateFinalBalances(entry);

    // Determine what I gave and got - FIXED LOGIC
    double gave = 0;
    double got = 0;
    String gaveCurrency = '';
    String gotCurrency = '';

    // Handle transactions involving myself
    if (person1 == 'Myself') {
      if (direction == 'give_to') {
        // I gave to person2
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
        if (isCurrencyEntry) {
          got = convertedAmount.toDouble();
          gotCurrency = toCurrency;
        }
      } else {
        // take_from - I took from person2
        got = amount.toDouble();
        gotCurrency = fromCurrency;
        if (isCurrencyEntry) {
          gave = convertedAmount.toDouble();
          gaveCurrency = toCurrency;
        }
      }
    } else if (person2 == 'Myself') {
      if (direction == 'give_to') {
        // Person1 gave to me
        got = amount.toDouble();
        gotCurrency = fromCurrency;
        // if (isCurrencyEntry) {
        //   gave = convertedAmount.toDouble();
        //   gaveCurrency = toCurrency;
        // }
      } else {
        // take_from - Person1 took from me
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
        // if (isCurrencyEntry) {
        //   got = convertedAmount.toDouble();
        //   gotCurrency = toCurrency;
        // }
      }
    } else {
      // Transaction between two other people - show what was exchanged
      if (direction == 'give_to') {
        // Person1 gave to Person2
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
        if (isCurrencyEntry) {
          got = convertedAmount.toDouble();
          gotCurrency = toCurrency;
        }
      } else {
        // Person1 took from Person2
        got = amount.toDouble();
        gotCurrency = fromCurrency;
        if (isCurrencyEntry) {
          gave = convertedAmount.toDouble();
          gaveCurrency = toCurrency;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCurrencyEntry ? Colors.purple.shade300 : Colors.grey.shade300,
          width: isCurrencyEntry ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Currency Exchange Header Tag (if currency exchange)
          if (isCurrencyEntry) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade100, Colors.purple.shade50],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 16,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CURRENCY EXCHANGE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$fromCurrency → $toCurrency',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Main row with full width utilization
                Row(
                  children: [
                    // Date & Time - Fixed width
                    SizedBox(
                      width: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd MMM').format(timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Persons with arrow - Fixed width
                    SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PersonDetailScreen(
                                          personName: person1,
                                        ),
                                  ),
                                );
                              },
                              child: Text(
                                person1 == 'Myself' ? 'Me' : person1,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      person1 == 'Myself'
                                          ? Colors.blue.shade700
                                          : Colors.purple.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Icon(
                            direction == 'give_to'
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color:
                                direction == 'give_to'
                                    ? Colors.green
                                    : Colors.red,
                            size: 16,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PersonDetailScreen(
                                          personName: person2,
                                        ),
                                  ),
                                );
                              },
                              child: Text(
                                person2 == 'Myself' ? 'Me' : person2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      person2 == 'Myself'
                                          ? Colors.blue.shade700
                                          : Colors.purple.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // GAVE Section - Fixed width
                    SizedBox(
                      width: 85,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              gave > 0
                                  ? Colors.red.shade50
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                gave > 0
                                    ? Colors.red.shade200
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'GAVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                    gave > 0
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gave > 0
                                  ? NumberFormat('#,##0').format(gave)
                                  : '0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    gave > 0
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              gaveCurrency.isNotEmpty ? gaveCurrency : '-',
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    gave > 0
                                        ? Colors.red.shade600
                                        : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // GOT Section - Fixed width
                    SizedBox(
                      width: 85,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              got > 0
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                got > 0
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'GOT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                    got > 0
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              got > 0 ? NumberFormat('#,##0').format(got) : '0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    got > 0
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              gotCurrency.isNotEmpty ? gotCurrency : '-',
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    got > 0
                                        ? Colors.green.shade600
                                        : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Exchange Rate with market comparison - Fixed width
                    if (isCurrencyEntry) ...[
                      SizedBox(
                        width: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '1 $fromCurrency =',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              Text(
                                '${exchangeRate.toStringAsFixed(2)} $toCurrency',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              if (marketRate > 0) ...[
                                const SizedBox(height: 1),
                                Text(
                                  'Market: ${marketRate.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Expected Profit Column - ALWAYS SHOW FOR CURRENCY EXCHANGE
                    if (isCurrencyEntry) ...[
                      SizedBox(
                        width: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                expectedProfit > 0
                                    ? Colors.green.shade50
                                    : expectedProfit < 0
                                    ? Colors.red.shade50
                                    : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  expectedProfit > 0
                                      ? Colors.green.shade200
                                      : expectedProfit < 0
                                      ? Colors.red.shade200
                                      : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'EXPECTED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      expectedProfit > 0
                                          ? Colors.green.shade700
                                          : expectedProfit < 0
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'PROFIT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      expectedProfit > 0
                                          ? Colors.green.shade700
                                          : expectedProfit < 0
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                expectedProfitText.isNotEmpty
                                    ? expectedProfitText
                                    : '0.00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      expectedProfit > 0
                                          ? Colors.green.shade700
                                          : expectedProfit < 0
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                toCurrency.isNotEmpty ? toCurrency : '-',
                                style: TextStyle(
                                  fontSize: 8,
                                  color:
                                      expectedProfit > 0
                                          ? Colors.green.shade600
                                          : expectedProfit < 0
                                          ? Colors.red.shade600
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Commission Details - Fixed width
                    if (commission > 0 && commissionPerson != null) ...[
                      SizedBox(
                        width: 85,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'COMMISSION',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                NumberFormat('#,##0').format(commission),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                commissionPerson.length > 8
                                    ? '${commissionPerson.substring(0, 8)}...'
                                    : commissionPerson,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Person Balance Section - LARGER USD ONLY
                    Expanded(
                      flex: 2, // Made it bigger by giving it more flex
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ), // Increased padding
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PERSON BALANCES (USD)',
                              style: TextStyle(
                                fontSize: 10, // Increased font size
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6), // Increased spacing
                            // Show USD balances only for persons in this transaction
                            ...finalBalances.entries
                                .where(
                                  (e) => e.key == person1 || e.key == person2,
                                )
                                .take(3)
                                .map((e) {
                                  final person = e.key;
                                  final balances = e.value;
                                  final usdBalance = balances['USD'] ?? 0;

                                  String displayName =
                                      person.length >
                                              12 // Increased character limit
                                          ? '${person.substring(0, 12)}...'
                                          : person;

                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 4,
                                    ), // Increased margin
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ), // Increased padding
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getPersonIcon(person),
                                          size: 14, // Increased icon size
                                          color: _getPersonColor(person),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ), // Increased spacing
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            displayName,
                                            style: TextStyle(
                                              fontSize:
                                                  11, // Increased font size
                                              fontWeight: FontWeight.w600,
                                              color: _getPersonColor(person),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ), // Increased spacing
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ), // Increased padding
                                            decoration: BoxDecoration(
                                              color:
                                                  usdBalance > 0
                                                      ? Colors.green
                                                          .withOpacity(0.15)
                                                      : usdBalance < 0
                                                      ? Colors.red.withOpacity(
                                                        0.15,
                                                      )
                                                      : Colors.grey.withOpacity(
                                                        0.15,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    4,
                                                  ), // Increased border radius
                                              border: Border.all(
                                                color:
                                                    usdBalance > 0
                                                        ? Colors.green.shade300
                                                        : usdBalance < 0
                                                        ? Colors.red.shade300
                                                        : Colors.grey.shade300,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              '${usdBalance > 0 ? '+' : ''}${NumberFormat('#,##0.00').format(usdBalance)} USD',
                                              style: TextStyle(
                                                fontSize:
                                                    9, // Increased font size
                                                color:
                                                    usdBalance > 0
                                                        ? Colors.green.shade700
                                                        : usdBalance < 0
                                                        ? Colors.red.shade700
                                                        : Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Delete Button - Fixed width
                    SizedBox(
                      width: 30,
                      child: IconButton(
                        onPressed: () => _showDeleteConfirmation(entry['id']),
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),

                // Notes section (if exists)
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPersonIcon(String personName) {
    final personType = _getPersonType(personName);
    switch (personType) {
      case 'Customer':
        return Icons.person;
      case 'Supplier':
        return Icons.business;
      case 'Middleman':
        return Icons.handshake;
      default:
        return Icons.account_circle;
    }
  }

  String _getPersonType(String personName) {
    final person = allPeople.firstWhere(
      (p) => p['name'] == personName,
      orElse: () => {'type': 'Person'},
    );
    return person['type'] ?? 'Person';
  }

  // Calculate final balances including commission logic
  Future<Map<String, Map<String, double>>> _calculateFinalBalances(
    Map<String, dynamic> entry,
  ) async {
    print('🔵 STARTING BALANCE CALCULATION');
    print('Entry: $entry');

    Map<String, Map<String, double>> balances = {};

    // Get persons involved in this transaction
    final person1 = entry['person1'] as String;
    final person2 = entry['person2'] as String;

    print('🔵 Person1: $person1, Person2: $person2');

    // Initialize balances for all persons involved (except Myself)
    for (var person in [person1, person2]) {
      if (person != 'Myself') {
        balances[person] = {'INR': 0, 'USD': 0, 'AED': 0};
        print('🔵 Initialized balance for $person: ${balances[person]}');

        // Fetch existing balance from person's account if available
        await _fetchPersonExistingBalance(person, balances[person]!);
        print(
          '🔵 After fetching existing balance for $person: ${balances[person]}',
        );
      }
    }

    // Calculate cumulative balance from all transactions up to and including this point
    final entryTimestamp = entry['timestamp'] as DateTime;

    print('🔵 Entry timestamp: $entryTimestamp');
    print('🔵 Total allEntries count: ${allEntries.length}');

    // Sort entries by timestamp in chronological order (oldest first)
    List<Map<String, dynamic>> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) {
      DateTime aTime = a['timestamp'] as DateTime;
      DateTime bTime = b['timestamp'] as DateTime;
      return aTime.compareTo(bTime);
    });

    print('🔵 Processing entries in chronological order:');
    for (var e in sortedEntries) {
      print('🔵 Entry timestamp: ${e['timestamp']}');
    }

    for (var e in sortedEntries) {
      final timestamp = e['timestamp'] as DateTime;
      print('🔵 Processing entry with timestamp: $timestamp');

      // Include transactions that are before OR at the same time as current entry
      if (timestamp.isAfter(entryTimestamp)) {
        print('🔵 Skipping entry - timestamp is after current entry');
        continue;
      }

      final p1 = e['person1'] as String;
      final p2 = e['person2'] as String;
      final dir = e['direction'] as String;
      final amt = (e['amount'] as num).toDouble();
      final convAmt = (e['convertedAmount'] as num).toDouble();
      final fromCur = e['fromCurrency'] as String;
      final toCur = e['toCurrency'] as String;
      final isCurrEx = e['isCurrencyExchange'] as bool;

      print(
        '🔵 Entry details: p1=$p1, p2=$p2, dir=$dir, amt=$amt, convAmt=$convAmt, fromCur=$fromCur, toCur=$toCur, isCurrEx=$isCurrEx',
      );

      // Case 1: Transaction involves Myself
      if (p1 == 'Myself' || p2 == 'Myself') {
        String otherPerson = p1 == 'Myself' ? p2 : p1;
        if (otherPerson == 'Myself') {
          print('🔵 Skipping entry - both persons are Myself');
          continue;
        }

        print('🔵 Other person: $otherPerson');

        // Only calculate for persons in current entry
        if (!balances.containsKey(otherPerson)) {
          print('🔵 Skipping entry - otherPerson not in balances map');
          continue;
        }

        print('🔵 Balance before processing: ${balances[otherPerson]}');

        // Balance calculation logic:
        // Positive balance = They owe me (I gave them money or they took from me)
        // Negative balance = I owe them (They gave me money or I took from them)

        if (dir == 'give_to') {
          // Person1 gave money to Person2
          if (p1 == 'Myself') {
            // I gave money to otherPerson -> They owe me (POSITIVE)
            print('🔵 I gave money to $otherPerson -> They owe me (POSITIVE)');
            print('🔵 Adding $amt to $fromCur balance');
            balances[otherPerson]![fromCur] =
                (balances[otherPerson]![fromCur] ?? 0) + amt;

            if (isCurrEx) {
              print(
                '🔵 Currency exchange: Subtracting $convAmt from $toCur balance',
              );
              balances[otherPerson]![toCur] =
                  (balances[otherPerson]![toCur] ?? 0) - convAmt;
            }
          } else {
            // otherPerson gave money to me -> I owe them (NEGATIVE)
            print('🔵 $otherPerson gave money to me -> I owe them (NEGATIVE)');
            print('🔵 Subtracting $amt from $fromCur balance');
            balances[otherPerson]![fromCur] =
                (balances[otherPerson]![fromCur] ?? 0) - amt;

            if (isCurrEx) {
              print('🔵 Currency exchange: Adding $convAmt to $toCur balance');
              balances[otherPerson]![toCur] =
                  (balances[otherPerson]![toCur] ?? 0) + convAmt;
            }
          }
        } else if (dir == 'take_from') {
          // Person1 took money from Person2
          if (p1 == 'Myself') {
            // I took money from otherPerson -> I owe them (NEGATIVE)
            print('🔵 I took money from $otherPerson -> I owe them (NEGATIVE)');
            print('🔵 Subtracting $amt from $fromCur balance');
            balances[otherPerson]![fromCur] =
                (balances[otherPerson]![fromCur] ?? 0) - amt;

            if (isCurrEx) {
              print('🔵 Currency exchange: Adding $convAmt to $toCur balance');
              balances[otherPerson]![toCur] =
                  (balances[otherPerson]![toCur] ?? 0) + convAmt;
            }
          } else {
            // otherPerson took money from me -> They owe me (POSITIVE)
            print(
              '🔵 $otherPerson took money from me -> They owe me (POSITIVE)',
            );
            print('🔵 Adding $amt to $fromCur balance');
            balances[otherPerson]![fromCur] =
                (balances[otherPerson]![fromCur] ?? 0) + amt;

            if (isCurrEx) {
              print(
                '🔵 Currency exchange: Subtracting $convAmt from $toCur balance',
              );
              balances[otherPerson]![toCur] =
                  (balances[otherPerson]![toCur] ?? 0) - convAmt;
            }
          }
        }

        print('🔵 Balance after processing: ${balances[otherPerson]}');
      }
      // Case 2: Transaction between two other people (not involving Myself)
      // These transactions don't affect my balance with them directly
      else if (balances.containsKey(p1) && balances.containsKey(p2)) {
        print('🔵 Transaction between $p1 and $p2 (not involving Myself)');
        print(
          '🔵 This transaction does not affect my balance with either person',
        );
        print('🔵 Keeping balances unchanged');
      } else {
        print(
          '🔵 Skipping entry - does not involve persons in current calculation',
        );
      }
    }

    // Apply commission if exists in current entry
    final commissionPerson = entry['commissionPerson'];
    final commission = (entry['commission'] as num?)?.toDouble() ?? 0;
    final toCurrency = entry['toCurrency'] ?? 'USD';

    print('🔵 COMMISSION PROCESSING:');
    print('🔵 Commission person: $commissionPerson');
    print('🔵 Commission amount: $commission');
    print('🔵 Commission currency: $toCurrency');

    if (commissionPerson != null &&
        commission > 0 &&
        commissionPerson != 'Myself') {
      if (balances.containsKey(commissionPerson)) {
        print(
          '🔵 Adding commission $commission to $commissionPerson in $toCurrency',
        );
        print(
          '🔵 Before commission: ${balances[commissionPerson]![toCurrency]}',
        );
        balances[commissionPerson]![toCurrency] =
            (balances[commissionPerson]![toCurrency] ?? 0) + commission;
        print(
          '🔵 After commission: ${balances[commissionPerson]![toCurrency]}',
        );
      } else {
        print('🔵 Commission person not in balances map');
      }
    } else {
      print('🔵 No commission to apply');
    }

    print('🔵 FINAL BALANCES:');
    balances.forEach((person, balance) {
      print('🔵 $person: $balance');
    });

    return balances;
  }

  // Fixed fetch existing balance method
  Future<void> _fetchPersonExistingBalance(
    String personName,
    Map<String, double> balance,
  ) async {
    try {
      print('🟢 FETCHING EXISTING BALANCE FOR: $personName');

      // Try to fetch from each collection based on person type
      String? personType = _getPersonType(personName);
      String collection = '';

      switch (personType) {
        case 'Customer':
          collection = 'Customers';
          break;
        case 'Supplier':
          collection = 'Suppliers';
          break;
        case 'Middleman':
          collection = 'Middlemen';
          break;
        default:
          collection = 'Person';
          break;
      }

      print('🟢 Searching in collection: $collection');

      final querySnapshot =
          await _firestore
              .collection(collection)
              .where('name', isEqualTo: personName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        print('🟢 Found person data: $data');

        // Handle existing balance - it could be either a number or a map
        if (data.containsKey('balance')) {
          final existingBalance = data['balance'];
          print('🟢 Found existing balance: $existingBalance');

          if (existingBalance != null) {
            if (existingBalance is Map) {
              // Balance is stored as a map of currencies
              existingBalance.forEach((key, value) {
                String currency = key.toString();
                double amount = (value as num).toDouble();
                balance[currency] = (balance[currency] ?? 0) + amount;
                print(
                  '🟢 Added existing balance: $currency = $amount, Total now: ${balance[currency]}',
                );
              });
            } else if (existingBalance is num) {
              // Balance is stored as a single number (assuming USD)
              double amount = existingBalance.toDouble();
              balance['USD'] = (balance['USD'] ?? 0) + amount;
              print(
                '🟢 Added existing balance as USD: $amount, Total now: ${balance['USD']}',
              );
            }
          }
        } else {
          print('🟢 No existing balance found for $personName');
        }
      } else {
        print('🟢 Person $personName not found in collection $collection');
      }

      print(
        '🟢 Final balance for $personName after fetching existing: $balance',
      );
    } catch (e) {
      print('🔴 Error fetching existing balance for $personName: $e');
    }
  }

  // Helper method to update person balance in database
  Future<void> _updatePersonBalanceInDatabase(
    String personName,
    Map<String, double> newBalance,
  ) async {
    try {
      print('🟡 UPDATING BALANCE IN DATABASE FOR: $personName');

      String? personType = _getPersonType(personName);
      String collection = '';

      switch (personType) {
        case 'Customer':
          collection = 'Customers';
          break;
        case 'Supplier':
          collection = 'Suppliers';
          break;
        case 'Middleman':
          collection = 'Middlemen';
          break;
        default:
          collection = 'Person';
          break;
      }

      final querySnapshot =
          await _firestore
              .collection(collection)
              .where('name', isEqualTo: personName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        // Convert balance to a format suitable for database storage
        Map<String, double> balanceToStore = {};
        newBalance.forEach((currency, amount) {
          if (amount != 0) {
            // Only store non-zero balances
            balanceToStore[currency] = amount;
          }
        });

        await docRef.update({
          'balance': balanceToStore.isEmpty ? 0 : balanceToStore,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print(
          '🟡 Successfully updated balance for $personName: $balanceToStore',
        );
      } else {
        print('🟡 Person $personName not found for balance update');
      }
    } catch (e) {
      print('🔴 Error updating balance for $personName: $e');
    }
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Transaction Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Date',
                    DateFormat('dd MMM yyyy').format(entry['timestamp']),
                  ),
                  _buildDetailRow(
                    'Time',
                    DateFormat('hh:mm a').format(entry['timestamp']),
                  ),
                  _buildDetailRow('From', entry['person1']),
                  _buildDetailRow('To', entry['person2']),
                  _buildDetailRow('Direction', entry['direction']),
                  _buildDetailRow(
                    'Amount',
                    '${entry['amount']} ${entry['fromCurrency']}',
                  ),
                  if (entry['isCurrencyExchange']) ...[
                    _buildDetailRow(
                      'Exchange Rate',
                      entry['exchangeRate'].toStringAsFixed(4),
                    ),
                    _buildDetailRow(
                      'Converted',
                      '${entry['convertedAmount']} ${entry['toCurrency']}',
                    ),
                  ],
                  if (entry['commission'] != null && entry['commission'] > 0)
                    _buildDetailRow(
                      'Commission',
                      '${entry['commission']} to ${entry['commissionPerson']}',
                    ),
                  if (entry['notes'].isNotEmpty)
                    _buildDetailRow('Notes', entry['notes']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _navigateToPersonDetails(String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personName: personName),
      ),
    );
  }

  // Export to Excel functionality
  // void _exportToExcel() {
  //   try {
  //     // Create CSV content
  //     List<List<dynamic>> rows = [];

  //     // Add headers
  //     rows.add([
  //       'Date',
  //       'Time',
  //       'Person 1',
  //       'Direction',
  //       'Person 2',
  //       'From Currency',
  //       'Amount',
  //       'Exchange Rate',
  //       'To Currency',
  //       'Converted Amount',
  //       'Commission Person',
  //       'Commission',
  //       'Notes',
  //     ]);

  //     // Add data rows
  //     for (var entry in allEntries) {
  //       rows.add([
  //         DateFormat('dd/MM/yyyy').format(entry['timestamp']),
  //         DateFormat('HH:mm').format(entry['timestamp']),
  //         entry['person1'],
  //         entry['direction'],
  //         entry['person2'],
  //         entry['fromCurrency'],
  //         entry['amount'],
  //         entry['exchangeRate'],
  //         entry['toCurrency'],
  //         entry['convertedAmount'],
  //         entry['commissionPerson'] ?? '',
  //         entry['commission'] ?? 0,
  //         entry['notes'],
  //       ]);
  //     }

  //     // Convert to CSV string
  //     String csv = const ListToCsvConverter().convert(rows);

  //     // Create blob and download
  //     final bytes = utf8.encode(csv);
  //     final blob = html.Blob([bytes]);
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     final anchor =
  //         html.document.createElement('a') as html.AnchorElement
  //           ..href = url
  //           ..style.display = 'none'
  //           ..download =
  //               'currency_exchanges_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

  //     html.document.body!.children.add(anchor);
  //     anchor.click();
  //     html.document.body!.children.remove(anchor);
  //     html.Url.revokeObjectUrl(url);

  //     _showSuccess('Data exported successfully!');
  //   } catch (e) {
  //     _showError('Error exporting data: ${e.toString()}');
  //   }
  // }

  // Enhanced Balance Report Tab
  Widget _buildBalanceReportTab() {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate balances for each person with "Myself" using EXACT same logic as _calculateFinalBalances
    Map<String, Map<String, double>> personBalances = {};

    // Get all unique persons (excluding Myself)
    Set<String> allPersons = {};
    for (var entry in allEntries) {
      final person1 = entry['person1'] as String;
      final person2 = entry['person2'] as String;

      if (person1 != 'Myself') allPersons.add(person1);
      if (person2 != 'Myself') allPersons.add(person2);
    }

    // Initialize balances for all persons
    for (var person in allPersons) {
      personBalances[person] = {'INR': 0, 'USD': 0, 'AED': 0};

      // Fetch existing balance from person's account if available
      _fetchPersonExistingBalance(person, personBalances[person]!);
    }

    // FIXED: Sort entries by timestamp in chronological order (oldest first)
    List<Map<String, dynamic>> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) {
      DateTime aTime = a['timestamp'] as DateTime;
      DateTime bTime = b['timestamp'] as DateTime;
      return aTime.compareTo(bTime);
    });

    // Process all entries in chronological order
    for (var e in sortedEntries) {
      final p1 = e['person1'] as String;
      final p2 = e['person2'] as String;
      final dir = e['direction'] as String;
      final amt = (e['amount'] as num).toDouble();
      final convAmt = (e['convertedAmount'] as num).toDouble();
      final fromCur = e['fromCurrency'] as String;
      final toCur = e['toCurrency'] as String;
      final isCurrEx = e['isCurrencyExchange'] as bool;

      // Case 1: Transaction involves Myself
      if (p1 == 'Myself' || p2 == 'Myself') {
        String otherPerson = p1 == 'Myself' ? p2 : p1;
        if (otherPerson == 'Myself') continue;

        // Only calculate for persons in personBalances
        if (!personBalances.containsKey(otherPerson)) continue;

        // EXACT SAME LOGIC as _calculateFinalBalances:
        // Positive balance = They owe me (I gave them money)
        // Negative balance = I owe them (They gave me money)

        if (dir == 'give_to') {
          // Person1 gave money to Person2
          if (p1 == 'Myself') {
            // I gave money to otherPerson -> They owe me (POSITIVE)
            personBalances[otherPerson]![fromCur] =
                (personBalances[otherPerson]![fromCur] ?? 0) + amt;

            if (isCurrEx) {
              personBalances[otherPerson]![toCur] =
                  (personBalances[otherPerson]![toCur] ?? 0) - convAmt;
            }
          } else {
            // otherPerson gave money to me -> I owe them (NEGATIVE)
            personBalances[otherPerson]![fromCur] =
                (personBalances[otherPerson]![fromCur] ?? 0) - amt;

            if (isCurrEx) {
              personBalances[otherPerson]![toCur] =
                  (personBalances[otherPerson]![toCur] ?? 0) + convAmt;
            }
          }
        } else if (dir == 'take_from') {
          // Person1 took money from Person2 (Person2 gave to Person1)
          if (p1 == 'Myself') {
            // I took money from otherPerson -> I owe them (NEGATIVE)
            personBalances[otherPerson]![fromCur] =
                (personBalances[otherPerson]![fromCur] ?? 0) - amt;

            if (isCurrEx) {
              personBalances[otherPerson]![toCur] =
                  (personBalances[otherPerson]![toCur] ?? 0) + convAmt;
            }
          } else {
            // otherPerson took money from me -> They owe me (POSITIVE)
            personBalances[otherPerson]![fromCur] =
                (personBalances[otherPerson]![fromCur] ?? 0) + amt;

            if (isCurrEx) {
              personBalances[otherPerson]![toCur] =
                  (personBalances[otherPerson]![toCur] ?? 0) - convAmt;
            }
          }
        }
      }
      // Case 2: Transaction between two other people (not involving Myself)
      else if (personBalances.containsKey(p1) &&
          personBalances.containsKey(p2)) {
        if (dir == 'give_to') {
          // p1 gave money to p2, so p2 owes p1
          // From my perspective: p1's balance with me decreases (they have less to give me)
          // p2's balance with me increases (they have more to give me)
          personBalances[p1]![fromCur] =
              (personBalances[p1]![fromCur] ?? 0) - amt;
          personBalances[p2]![fromCur] =
              (personBalances[p2]![fromCur] ?? 0) + amt;

          if (isCurrEx) {
            personBalances[p1]![toCur] =
                (personBalances[p1]![toCur] ?? 0) + convAmt;
            personBalances[p2]![toCur] =
                (personBalances[p2]![toCur] ?? 0) - convAmt;
          }
        } else if (dir == 'take_from') {
          // p1 took money from p2, so p1 owes p2
          personBalances[p1]![fromCur] =
              (personBalances[p1]![fromCur] ?? 0) + amt;
          personBalances[p2]![fromCur] =
              (personBalances[p2]![fromCur] ?? 0) - amt;

          if (isCurrEx) {
            personBalances[p1]![toCur] =
                (personBalances[p1]![toCur] ?? 0) - convAmt;
            personBalances[p2]![toCur] =
                (personBalances[p2]![toCur] ?? 0) + convAmt;
          }
        }
      }

      // Apply commission for this entry
      final commissionPerson = e['commissionPerson'];
      final commission = (e['commission'] as num?)?.toDouble() ?? 0;
      final commissionCurrency = e['toCurrency'] ?? 'USD';

      if (commissionPerson != null &&
          commission > 0 &&
          commissionPerson != 'Myself' &&
          personBalances.containsKey(commissionPerson)) {
        personBalances[commissionPerson]![commissionCurrency] =
            (personBalances[commissionPerson]![commissionCurrency] ?? 0) +
            commission;
      }
    }

    // Remove persons with zero balances in all currencies
    personBalances.removeWhere((person, balances) {
      return balances.values.every((balance) => balance == 0);
    });

    if (personBalances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 56,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No balance data available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding transactions to see balances',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assessment,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Net balance with Myself',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Excel-like table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Person column header
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300),
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Person',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      // Currency headers
                      ...['INR', 'USD', 'AED'].map((currency) {
                        return Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  currency,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                // Table rows
                ...personBalances.entries.map((entry) {
                  final personName = entry.key;
                  final balances = entry.value;

                  // Calculate net total in INR (removed - no longer needed)
                  // double netTotalInINR = 0;
                  // netTotalInINR += balances['INR'] ?? 0;
                  // netTotalInINR += (balances['USD'] ?? 0) * 83.0; // USD to INR
                  // netTotalInINR += (balances['AED'] ?? 0) * 22.6; // AED to INR

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Person name
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _getPersonColor(
                                      personName,
                                    ).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      personName.substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getPersonColor(personName),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        personName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _getPersonType(personName),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Currency balances
                        ...['INR', 'USD', 'AED'].map((currency) {
                          final balance = balances[currency] ?? 0;
                          final isPositive = balance > 0;
                          final isNegative = balance < 0;

                          return Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isPositive
                                        ? Colors.green.withOpacity(0.05)
                                        : isNegative
                                        ? Colors.red.withOpacity(0.05)
                                        : Colors.transparent,
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    NumberFormat(
                                      '#,##0.00',
                                    ).format(balance.abs()),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isPositive
                                              ? Colors.green.shade700
                                              : isNegative
                                              ? Colors.red.shade700
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isPositive
                                              ? Colors.green.withOpacity(0.2)
                                              : isNegative
                                              ? Colors.red.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPositive
                                          ? 'To Receive'
                                          : isNegative
                                          ? 'To Pay'
                                          : 'Settled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isPositive
                                                ? Colors.green.shade800
                                                : isNegative
                                                ? Colors.red.shade800
                                                : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),

                // Summary row
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      ...['INR', 'USD', 'AED'].map((currency) {
                        double total = 0;
                        for (var balance in personBalances.values) {
                          total += balance[currency] ?? 0;
                        }
                        return Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              NumberFormat('#,##0.00').format(total.abs()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    total > 0
                                        ? Colors.green.shade700
                                        : total < 0
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Export button
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // _exportToExcel();
              },
              icon: const Icon(Icons.download),
              label: const Text('Export to Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPersonColor(String personName) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[personName.hashCode % colors.length];
  }

  // String _getPersonType(String personName) {
  //   final person = allPeople.firstWhere(
  //     (p) => p['name'] == personName,
  //     orElse: () => {'type': 'Person'},
  //   );
  //   return person['type'] ?? 'Person';
  // }

  String _calculateGrandTotal(Map<String, Map<String, double>> personBalances) {
    double grandTotal = 0;
    for (var balances in personBalances.values) {
      grandTotal += balances['INR'] ?? 0;
      grandTotal += (balances['USD'] ?? 0) * 83.0;
      grandTotal += (balances['AED'] ?? 0) * 22.6;
    }
    return NumberFormat('#,##0.00').format(grandTotal.abs());
  }
}

// CSV Converter class
// class ListToCsvConverter {
//   const ListToCsvConverter();

//   String convert(List<List<dynamic>> data) {
//     StringBuffer buffer = StringBuffer();

//     for (var row in data) {
//       buffer.writeln(row.map((e) => '"${e.toString()}"').join(','));
//     }

//     return buffer.toString();
//   }
