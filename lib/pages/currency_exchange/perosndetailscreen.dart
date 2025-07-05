import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/home/pages/add_people.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personName;

  const PersonDetailScreen({super.key, required this.personName});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  @override
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController person1Controller = TextEditingController();
  final TextEditingController person2Controller = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController commissionController = TextEditingController();
  final Map<String, Map<String, double>> exchangeRates = {
    'INR': {'USD': 0.012, 'AED': 0.044},
    'USD': {'INR': 83.0, 'AED': 3.67},
    'AED': {'INR': 22.6, 'USD': 0.27},
  };

  // Entries data
  List<Map<String, dynamic>> allEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];

  // Loading states
  bool isLoading = true;
  bool isSaving = false;

  // Search and filters
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isDateRangeActive = false;
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Middleman> middlemen = [];
  List<Person> person = [];
  List<Map<String, String>> allPeople = [];
  // Tab controller
  TabController? _tabController;

  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 2, vsync: this);

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

  // Fetch methods
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

  String? selectedP1;
  String? selectedP2;
  String? selectedFromCurrency = 'INR';
  String? selectedToCurrency = 'USD';
  String? selectedAmountCurrency = 'INR';
  String? selectedRateCurrency = 'USD';
  String? transactionDirection = 'give_to';
  String? selectedCommissionPerson;

  bool isCurrencyExchange = true;
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

  final List<String> currencies = ['INR', 'USD', 'AED'];

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

    // Determine available persons for commission
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

                  // Person selector (only Person 1 and Person 2)
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

                  // Amount and currency row
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
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                ],

                _buildActionButton(
                  icon: Icons.person_add,
                  onPressed: _showAddPersonDialog,
                  color: colorScheme.secondary,
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personName ?? 'Person Details',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _buildOptimizedCurrencyForm(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('currency_exchanges')
                      .where('person1', isEqualTo: widget.personName)
                      .snapshots(),
              builder: (context, snapshot1) {
                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('currency_exchanges')
                          .where('person2', isEqualTo: widget.personName)
                          .snapshots(),
                  builder: (context, snapshot2) {
                    if (snapshot1.connectionState == ConnectionState.waiting ||
                        snapshot2.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs1 = snapshot1.data?.docs ?? [];
                    final docs2 = snapshot2.data?.docs ?? [];
                    final allDocs = [...docs1, ...docs2];

                    allDocs.sort((a, b) {
                      final aTime = (a['timestamp'] as Timestamp).toDate();
                      final bTime = (b['timestamp'] as Timestamp).toDate();
                      return bTime.compareTo(aTime);
                    });

                    double totalBalance = 0;
                    for (var tx in allDocs) {
                      if (tx['person1'] == widget.personName) {
                        totalBalance -= tx['convertedAmount'] ?? 0;
                      } else if (tx['person2'] == widget.personName) {
                        totalBalance += tx['convertedAmount'] ?? 0;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance with ${widget.personName}:',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${totalBalance >= 0 ? '+' : '-'} ₹${totalBalance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  totalBalance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: allDocs.length,
                              itemBuilder: (context, index) {
                                final tx = allDocs[index];
                                final timestamp =
                                    (tx['timestamp'] as Timestamp).toDate();
                                final gavePerson = tx['person1'];
                                final gotPerson = tx['person2'];
                                final amount = tx['amount'];
                                final converted = tx['convertedAmount'];
                                final from = tx['fromCurrency'];
                                final to = tx['toCurrency'];
                                final exchangeRate = tx['exchangeRate'];
                                final notes = tx['notes'];

                                final isGiving =
                                    gavePerson == widget.personName;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(timestamp),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '$exchangeRate Rate',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$gavePerson → $gotPerson',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((notes as String).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            notes,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Gave: ₹$amount $from',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                          Text(
                                            'Got: ₹$converted $to',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
