import 'dart:async';

import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/models/customer.dart';
import 'package:aromex/models/middleman.dart';
import 'package:aromex/models/person.dart';
import 'package:aromex/models/supplier.dart';
import 'package:aromex/pages/Journal/main.dart';
import 'package:aromex/pages/home/main.dart';
import 'package:aromex/pages/home/pages/add_people.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class JournalEntryPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Pages)? onPageChange;
  final String? initialJournalTitle;

  const JournalEntryPage({
    super.key,
    this.onBack,
    this.onPageChange,
    this.initialJournalTitle,
  });

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;
  String _lastCheckedTitle = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        leading:
            widget.onBack != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                )
                : null,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JournalReportPage(),
                ),
              );
            },
            child: const Text(
              'Journal Report',
              style: TextStyle(
                color: Colors.white, // or any color that matches your theme
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildTransactionForm(), _buildJournalDataSection()],
        ),
      ),
    );
  }

  // Form controllers
  final TextEditingController journalTitleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // People data
  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  List<Middleman> middlemen = [];
  List<Person> person = [];
  List<Map<String, String>> allPeople = [];

  // Form state
  String? selectedP1;
  String? selectedP2;
  String? transactionType = 'debit';
  String? direction = 'from';

  // Journal entries data
  List<Map<String, dynamic>> journalEntries = [];
  List<Map<String, dynamic>> filteredJournalEntries = [];
  List<List<Map<String, dynamic>>> pages = [];
  int currentPageIndex = 0;

  // Current journal specific data
  List<Map<String, dynamic>> currentJournalEntries = [];
  Map<String, double> currentJournalBalances = {};
  List<Map<String, dynamic>> currentJournalCreditDebitSummary = [];

  // Loading states
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isSaving = false;
  bool isLoadingJournalData = false;

  // Pagination
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  final int perPage = 10;

  // Search and filters
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  bool isDateRangeActive = false;

  // Journal management
  bool journalExists = false;
  String? existingJournalTitle;
  bool showJournalOptions = false;
  bool hasEntriesInJournal = false;
  bool _hasShownDialog = false; // Flag to prevent multiple dialogs

  // Tab controller for journal history and credit/debit tabs
  TabController? _tabController;

  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get currentPageEntries {
    if (pages.isEmpty) return [];
    return pages[currentPageIndex];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
      filterJournalEntries();
    });

    // Initialize with passed journal title if available
    if (widget.initialJournalTitle != null) {
      journalTitleController.text = widget.initialJournalTitle!;
    }

    journalTitleController.addListener(_onJournalTitleChanged);

    fetchCustomers();
    fetchSuppliers();
    fetchPerson();
    fetchMiddlemen();

    // Only load journal entries if a title is provided
    if (widget.initialJournalTitle != null) {
      _checkJournalExists(widget.initialJournalTitle!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    journalTitleController.dispose();
    amountController.dispose();
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // Journal title change handler with automatic dialog
  void _onJournalTitleChanged() {
    final title = journalTitleController.text.trim();

    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Only proceed if title actually changed
    if (title == _lastCheckedTitle) return;

    if (title.isNotEmpty) {
      // Debounce the check to avoid multiple rapid calls
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (title != _lastCheckedTitle) {
          _lastCheckedTitle = title;
          _checkJournalExists(title);
          _loadJournalEntries();
        }
      });
    } else {
      // Reset everything if title is empty
      _lastCheckedTitle = '';
      setState(() {
        journalExists = false;
        showJournalOptions = false;
        hasEntriesInJournal = false;
        currentJournalEntries.clear();
        currentJournalBalances.clear();
        currentJournalCreditDebitSummary.clear();
        journalEntries.clear();
        filteredJournalEntries.clear();
        pages.clear();
        _hasShownDialog = false;
      });
    }
  }

  void _resetDialogState() {
    setState(() {
      _hasShownDialog = false;
      _lastCheckedTitle = '';
    });
  }
  // Add these methods to your _JournalEntryPageState class

  // NEW METHOD: Update individual entity balances after journal entry
  Future<void> _updateEntityBalances() async {
    try {
      if (selectedP1 != null && selectedP1 != 'I' && selectedP1 != 'Me') {
        await _updatePersonBalance(selectedP1!);
      }

      if (selectedP2 != null && selectedP2 != 'I' && selectedP2 != 'Me') {
        await _updatePersonBalance(selectedP2!);
      }
    } catch (e) {
      debugPrint('Error updating entity balances: $e');
    }
  }

  // Update balance for a specific person (Customer, Supplier, Middleman, or Person)
  Future<void> _updatePersonBalance(String personName) async {
    try {
      // Find the person type and reference
      Map<String, dynamic>? personData = _findPersonData(personName);
      if (personData == null) return;

      String entityType = personData['type'];
      DocumentReference? entityRef = personData['ref'];

      // Create entity-specific journal
      final entityJournalTitle = '${entityType}_${personName}_Transactions';
      final entityJournalRef = FirebaseFirestore.instance
          .collection('journals')
          .doc(entityJournalTitle);

      // Create journal if it doesn't exist
      await entityJournalRef.set({
        'title': entityJournalTitle,
        'type': entityType.toLowerCase(),
        'entityRef': entityRef,
        'entityName': personName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add the journal entry to entity's individual journal
      final amount = double.parse(amountController.text.trim());

      await entityJournalRef.collection('entries').add({
        'amount': amount,
        'direction': direction,
        'p1': selectedP1,
        'p2': selectedP2,
        'transactionType': transactionType == 'debit' ? 'takes' : 'gives',
        'timestamp': FieldValue.serverTimestamp(),
        'sourceJournal': journalTitleController.text.trim(),
        'description':
            'Journal Entry from ${journalTitleController.text.trim()}',
      });

      debugPrint('Entity balance updated for $personName ($entityType)');
    } catch (e) {
      debugPrint('Error updating balance for $personName: $e');
    }
  }

  // Find person data from all people collections
  Map<String, dynamic>? _findPersonData(String personName) {
    // Check in customers
    for (var customer in customers) {
      if (customer.name == personName) {
        return {
          'type': 'Customer',
          'ref': customer.snapshot?.reference,
          'entity': customer,
        };
      }
    }

    // Check in suppliers
    for (var supplier in suppliers) {
      if (supplier.name == personName) {
        return {
          'type': 'Supplier',
          'ref': supplier.snapshot?.reference,
          'entity': supplier,
        };
      }
    }

    // Check in middlemen
    for (var middleman in middlemen) {
      if (middleman.name == personName) {
        return {
          'type': 'Middleman',
          'ref': middleman.snapshot?.reference,
          'entity': middleman,
        };
      }
    }

    // Check in persons
    for (var p in person) {
      if (p.name == personName) {
        return {'type': 'Person', 'ref': p.snapshot?.reference, 'entity': p};
      }
    }

    return null;
  }

  // 2. Fixed _calculateTotals method to match Journal Report structure
  Map<String, double> _calculateTotals(
    List<Map<String, dynamic>> transactions,
  ) {
    double totalCredit = 0; // Money I effectively received
    double totalDebit = 0; // Money I effectively gave

    for (var transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      final p1 = transaction['p1'] as String;
      final p2 = transaction['p2'] as String;
      final direction = transaction['direction'];

      if (p1 == 'I') {
        // I am directly involved
        if (direction == 'to') {
          // I give money → Debit
          totalDebit += amount;
        } else if (direction == 'from') {
          // I receive money → Credit
          totalCredit += amount;
        }
      } else if (p2 == 'I') {
        // I am directly involved
        if (direction == 'to') {
          // Someone gives to I → Credit
          totalCredit += amount;
        } else if (direction == 'from') {
          // Someone receives from I → Debit
          totalDebit += amount;
        }
      } else {
        // Neither is I - facilitated transaction
        if (direction == 'to') {
          // P1 gives to P2 (I facilitate) → Both reduce my receivables
          totalCredit += amount; // I effectively received from both parties
        } else if (direction == 'from') {
          // P1 receives from P2 (I facilitate) → Both increase my payables
          totalDebit += amount; // I effectively gave to both parties
        }
      }
    }

    return {'credit': totalCredit, 'debit': totalDebit};
  }

  Map<String, double> _calculatePersonTotals(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, double> personTotals = {};

    for (var transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      final p1 = transaction['p1'] as String;
      final p2 = transaction['p2'] as String;
      final direction = transaction['direction'];

      if (p1 == 'I') {
        // I am directly involved as giver/receiver
        if (direction == 'to') {
          // I give to P2 → P2 owes me (+ve)
          personTotals[p2] = (personTotals[p2] ?? 0) + amount;
        } else if (direction == 'from') {
          // I receive from P2 → I owe P2 (-ve)
          personTotals[p2] = (personTotals[p2] ?? 0) - amount;
        }
      } else if (p2 == 'I') {
        // I am directly involved as receiver/giver
        if (direction == 'to') {
          // P1 gives to I → I owe P1 (-ve)
          personTotals[p1] = (personTotals[p1] ?? 0) - amount;
        } else if (direction == 'from') {
          // P1 receives from I → P1 owes me (+ve)
          personTotals[p1] = (personTotals[p1] ?? 0) + amount;
        }
      } else {
        // Neither is I - I facilitate the transaction
        if (direction == 'to') {
          // P1 gives to P2 (I facilitate)
          // P1 paid on my behalf, so P1 owes me less
          personTotals[p1] = (personTotals[p1] ?? 0) - amount;
          // P2 received on my behalf, so P2 owes me less
          personTotals[p2] = (personTotals[p2] ?? 0) - amount;
        } else if (direction == 'from') {
          // P1 receives from P2 (I facilitate)
          // P1 received on my behalf, so P1 owes me more
          personTotals[p1] = (personTotals[p1] ?? 0) + amount;
          // P2 paid on my behalf, so P2 owes me more
          personTotals[p2] = (personTotals[p2] ?? 0) + amount;
        }
      }
    }

    return personTotals;
  }

  // Check if journal exists and automatically show dialog
  Future<void> _checkJournalExists(String title) async {
    try {
      final journalDoc =
          await _firestore.collection('journals').doc(title).get();

      final exists = journalDoc.exists;

      setState(() {
        journalExists = exists;
        existingJournalTitle = exists ? title : null;
        showJournalOptions = exists;
      });

      // Only show dialog if:
      // 1. Journal exists
      // 2. Dialog hasn't been shown for this title
      // 3. This is not an initial journal title (user typed it)
      if (exists &&
          !_hasShownDialog &&
          widget.initialJournalTitle == null &&
          title == _lastCheckedTitle) {
        // Ensure it's still the current title

        _hasShownDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && journalTitleController.text.trim() == title) {
            _showJournalOptionsDialog();
          }
        });
      }

      if (exists) {
        await _loadCurrentJournalData(title);
      }
    } catch (e) {
      debugPrint('Error checking journal existence: $e');
    }
  }

  // Load current journal specific data

  // Key fixes in Journal Entry Page:

  // 1. Fixed _loadCurrentJournalData method - consistent calculation logic
  Future<void> _loadCurrentJournalData(String journalTitle) async {
    setState(() {
      isLoadingJournalData = true;
    });

    try {
      final journalRef = _firestore.collection('journals').doc(journalTitle);
      final entriesSnapshot =
          await journalRef
              .collection('entries')
              .orderBy('timestamp', descending: true)
              .get();

      List<Map<String, dynamic>> entries = [];
      Map<String, double> personBalances = {};

      for (var doc in entriesSnapshot.docs) {
        final data = doc.data();
        entries.add({
          'id': doc.id,
          'journalId': journalTitle,
          'title': journalTitle,
          'amount': data['amount'] ?? 0,
          'direction': data['direction'] ?? 'unknown',
          'p1': data['p1'] ?? 'Unknown',
          'p2': data['p2'] ?? 'Unknown',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'transactionType': data['transactionType'] ?? 'general',
        });

        // FIXED: Consistent balance calculation logic
        final p1 = data['p1'] ?? 'Unknown';
        final p2 = data['p2'] ?? 'Unknown';
        final amount = (data['amount'] ?? 0).toDouble();
        final direction = data['direction'] ?? 'from';

        if (direction == 'to') {
          // p1 gives to p2 (p1 has debit/negative balance, p2 has credit/positive balance)
          personBalances[p1] = (personBalances[p1] ?? 0) - amount;
          personBalances[p2] = (personBalances[p2] ?? 0) + amount;
        } else if (direction == 'from') {
          // p1 receives from p2 (p1 has credit/positive balance, p2 has debit/negative balance)
          personBalances[p1] = (personBalances[p1] ?? 0) + amount;
          personBalances[p2] = (personBalances[p2] ?? 0) - amount;
        }
      }

      // Create credit/debit summary with consistent structure
      // Create credit/debit summary - only show I-related balances
      List<Map<String, dynamic>> creditDebitSummary = [];
      personBalances.forEach((person, balance) {
        if (person != 'I' && balance != 0) {
          // Exclude 'I' and zero balances
          creditDebitSummary.add({
            'person': person,
            'credit': balance > 0 ? balance : 0.0,
            'debit': balance < 0 ? balance.abs() : 0.0,
            'balance': balance,
          });
        }
      });

      // Sort by total activity (credit + debit)
      creditDebitSummary.sort((a, b) {
        double totalA = a['credit'] + a['debit'];
        double totalB = b['credit'] + b['debit'];
        return totalB.compareTo(totalA);
      });

      setState(() {
        currentJournalEntries = entries;
        currentJournalBalances = personBalances;
        currentJournalCreditDebitSummary = creditDebitSummary;
        hasEntriesInJournal = entries.isNotEmpty;
        isLoadingJournalData = false;
      });
    } catch (e) {
      debugPrint('Error loading journal data: $e');
      setState(() {
        isLoadingJournalData = false;
      });
    }
  }

  // Enhanced journal options dialog
  void _showJournalOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Journal Already Exists'),
          content: Text(
            'The journal "${journalTitleController.text}" already exists. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRenameDialog();
              },
              child: const Text('Change Name'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Don't reset _hasShownDialog here since we want to continue with existing journal
                _refreshPage();
              },
              child: const Text('Continue Editing'),
            ),
          ],
        );
      },
    );
  }

  // Enhanced rename dialog
  void _showRenameDialog() {
    final TextEditingController renameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter New Journal Name'),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              hintText: 'New journal name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear the title and reset all flags
                journalTitleController.clear();
                setState(() {
                  _hasShownDialog = false;
                  _lastCheckedTitle = '';
                });
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (renameController.text.trim().isNotEmpty) {
                  // Reset flags when changing to new name
                  setState(() {
                    _hasShownDialog = false;
                    _lastCheckedTitle = '';
                  });
                  journalTitleController.text = renameController.text.trim();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // Page refresh method
  void _refreshPage() {
    final currentTitle = journalTitleController.text.trim();
    setState(() {
      // Reset all states
      currentJournalEntries.clear();
      currentJournalBalances.clear();
      currentJournalCreditDebitSummary.clear();
      journalEntries.clear();
      filteredJournalEntries.clear();
      pages.clear();
      currentPageIndex = 0;
      isLoading = true;
      isLoadingJournalData = true;
    });

    // Reload data
    if (currentTitle.isNotEmpty) {
      _loadCurrentJournalData(currentTitle);
      _loadJournalEntries();
    }
  }

  // Add Person Dialog
  void _showAddPersonDialog() {
    AddPerson();
  }

  // Add new person to Firebase

  // Fetch methods for people data
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
    debugPrint("[fetchPerson] Setting up listener for Person collection...");

    db
        .collection('Person')
        .snapshots()
        .listen((snapshot) {
          debugPrint(
            "[fetchPerson] Snapshot received with ${snapshot.docs.length} documents.",
          );

          if (!mounted) {
            debugPrint("[fetchPerson] Widget not mounted. Skipping setState.");
            return;
          }

          setState(() {
            person =
                snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList();
            debugPrint(
              "[fetchPerson] Updated person list with ${person.length} entries.",
            );
            mergeAllPeople();
            debugPrint("[fetchPerson] mergeAllPeople() called.");
          });
        })
        .onError((error) {
          debugPrint("[fetchPerson] Error occurred: $error");
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

  // Updated to load only entries for the current journal title
  Future<void> _loadJournalEntries({bool loadMore = false}) async {
    final currentTitle = journalTitleController.text.trim();
    if (currentTitle.isEmpty) {
      setState(() {
        journalEntries.clear();
        filteredJournalEntries.clear();
        pages.clear();
        isLoading = false;
      });
      return;
    }

    if (loadMore && (!hasMore || isLoadingMore)) return;

    setState(() {
      if (loadMore) {
        isLoadingMore = true;
      } else {
        isLoading = true;
      }
    });

    try {
      final journalDoc =
          await _firestore.collection('journals').doc(currentTitle).get();

      if (!journalDoc.exists) {
        setState(() {
          journalEntries.clear();
          filteredJournalEntries.clear();
          pages.clear();
          isLoading = false;
          isLoadingMore = false;
        });
        return;
      }

      Query entriesQuery = journalDoc.reference
          .collection('entries')
          .orderBy('timestamp', descending: true);

      if (isDateRangeActive) {
        if (startDate != null) {
          entriesQuery = entriesQuery.where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
          );
        }
        if (endDate != null) {
          final DateTime endDatePlusOne = endDate!.add(const Duration(days: 1));
          entriesQuery = entriesQuery.where(
            'timestamp',
            isLessThan: endDatePlusOne,
          );
        }
      }

      if (loadMore && lastDocument != null) {
        entriesQuery = entriesQuery.startAfterDocument(lastDocument!);
      }

      entriesQuery = entriesQuery.limit(perPage);

      final entriesSnapshot = await entriesQuery.get();

      final journalTransactions =
          entriesSnapshot.docs.map((entryDoc) {
            final entryData = entryDoc.data() as Map<String, dynamic>;
            return {
              'id': entryDoc.id,
              'journalId': currentTitle,
              'title': currentTitle,
              'amount': entryData['amount'] ?? 0,
              'direction': entryData['direction'] ?? 'unknown',
              'p1': entryData['p1'] ?? 'Unknown',
              'p2': entryData['p2'] ?? 'Unknown',
              'timestamp':
                  (entryData['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              'transactionType': entryData['transactionType'] ?? 'general',
            };
          }).toList();

      if (entriesSnapshot.docs.isNotEmpty) {
        lastDocument = entriesSnapshot.docs.last;
      }

      setState(() {
        if (loadMore) {
          journalEntries.addAll(journalTransactions);
        } else {
          journalEntries = journalTransactions;
        }

        isLoading = false;
        isLoadingMore = false;
        hasMore = journalTransactions.length == perPage;

        filterJournalEntries(takeBackToFirstPage: !loadMore);
      });
    } catch (e) {
      _showError('Error loading entries: ${e.toString()}');
      debugPrint('Error details: $e');
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void filterJournalEntries({bool takeBackToFirstPage = true}) {
    List<Map<String, dynamic>> baseList =
        searchQuery.isEmpty
            ? journalEntries
            : journalEntries.where((entry) {
              final title = (entry['title'] ?? '').toLowerCase();
              final p1 = (entry['p1'] ?? '').toLowerCase();
              final p2 = (entry['p2'] ?? '').toLowerCase();
              final amount = entry['amount'].toString().toLowerCase();
              final transactionType =
                  (entry['transactionType'] ?? '').toLowerCase();

              return title.contains(searchQuery) ||
                  p1.contains(searchQuery) ||
                  p2.contains(searchQuery) ||
                  amount.contains(searchQuery) ||
                  transactionType.contains(searchQuery);
            }).toList();

    setState(() {
      filteredJournalEntries = baseList;
      pages = [];
      for (var i = 0; i < baseList.length; i += perPage) {
        pages.add(
          baseList.sublist(
            i,
            i + perPage > baseList.length ? baseList.length : i + perPage,
          ),
        );
      }
      currentPageIndex = takeBackToFirstPage ? 0 : currentPageIndex;
    });
  }

  // Form validation and submission
  bool _validateForm() {
    if (selectedP1 == null) {
      _showError('Please select the first person');
      return false;
    }
    if (journalTitleController.text.isEmpty) {
      _showError('Please Enter the Journal Title');
      return false;
    }
    if (selectedP2 == null) {
      _showError('Please select the second person');
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

      final entry = {
        'p1': selectedP1,
        'transactionType': transactionType == 'debit' ? 'takes' : 'gives',
        'direction': direction,
        'p2': selectedP2,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final journalTitle =
          journalTitleController.text.trim().isNotEmpty
              ? journalTitleController.text.trim()
              : "Untitled";

      final journalRef = _firestore.collection('journals').doc(journalTitle);

      // Add entry to main journal
      await journalRef.set({'title': journalTitle}, SetOptions(merge: true));
      await journalRef.collection('entries').add(entry);

      // NEW: Update entity balances
      await _updateEntityBalances();

      setState(() {
        amountController.clear();
        selectedP1 = null;
        selectedP2 = null;
        showJournalOptions = false;
        hasEntriesInJournal = true;
        _hasShownDialog = false;
      });

      _showSuccess('Entry added successfully!');
      _updateNetBalances();

      // Refresh the entire page data
      _refreshPage();
    } catch (e) {
      _showError('Error saving entry: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateNetBalances() async {
    final result = await loadAndCalculateCreditDebit();

    final oweBalance = await Balance.fromType(BalanceType.totalOwe);
    final dueBalance = await Balance.fromType(BalanceType.totalDue);

    await oweBalance.setAmount(result['debit']!);
    await dueBalance.setAmount(result['credit']!);
  }

  Future<Map<String, double>> loadAndCalculateCreditDebit() async {
    try {
      final journalsSnapshot = await _firestore.collection('journals').get();
      double credit = 0;
      double debit = 0;

      for (var journalDoc in journalsSnapshot.docs) {
        final entriesSnapshot =
            await journalDoc.reference
                .collection('entries')
                .orderBy('timestamp', descending: true)
                .get();

        for (var entryDoc in entriesSnapshot.docs) {
          final data = entryDoc.data();
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final direction = data['direction'];

          if (direction == 'to') {
            credit += amount;
          } else if (direction == 'from') {
            debit += amount;
          }
        }
      }

      return {'credit': credit, 'debit': debit};
    } catch (e) {
      debugPrint('Error loading or calculating totals: $e');
      return {'credit': 0, 'debit': 0};
    }
  }

  void _updateDirection(String? newTransactionType) {
    setState(() {
      transactionType = newTransactionType;
      direction = newTransactionType == 'credit' ? 'to' : 'from';
    });
  }

  // Date range filter methods
  String get _dateRangeText {
    if (!isDateRangeActive) return 'Select Date Range';

    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    if (startDate != null && endDate != null) {
      return '${formatter.format(startDate!)} - ${formatter.format(endDate!)}';
    } else if (startDate != null) {
      return 'From ${formatter.format(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${formatter.format(endDate!)}';
    }
    return 'Select Date Range';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Range'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        tempStartDate != null
                            ? DateFormat('MM/dd/yyyy').format(tempStartDate!)
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tempStartDate = picked;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        tempEndDate != null
                            ? DateFormat('MM/dd/yyyy').format(tempEndDate!)
                            : 'Not set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            tempEndDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop({'startDate': tempStartDate, 'endDate': tempEndDate});
                  },
                  child: const Text('APPLY'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        startDate = result['startDate'];
        endDate = result['endDate'];
        isDateRangeActive = (startDate != null || endDate != null);

        lastDocument = null;
        currentPageIndex = 0;
        isLoading = true;
        _loadJournalEntries();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      isDateRangeActive = false;

      lastDocument = null;
      currentPageIndex = 0;
      isLoading = true;
      _loadJournalEntries();
    });
  }

  // UI helper methods
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

  // Widget builders
  Widget buildPersonDropdown({
    required String? selectedValue,
    required String hint,
    required void Function(String?) onChanged,
    required double width,
    required List<Map<String, String>> allPeople,
    required bool isP1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, String>> dropdownItems = [
      {'name': isP1 ? 'I' : 'I', 'type': 'You'},
      ...allPeople,
    ];

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(
            hint,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          menuMaxHeight: 200,
          isDense: false,
          dropdownColor: colorScheme.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          items:
              dropdownItems.map((person) {
                return DropdownMenuItem<String>(
                  value: person['name'],
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            person['name'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            person['type'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          onChanged: dropdownItems.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildTransactionForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Journal Input in same row
          Row(
            children: [
              Text(
                'Journal Entry',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: journalTitleController,
                  decoration: InputDecoration(
                    hintText: 'Journal Title',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon:
                        journalExists
                            ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                            : null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Single row transaction details
          Row(
            children: [
              // Person 1
              Expanded(
                flex: 3,
                child: buildPersonDropdown(
                  selectedValue: selectedP1,
                  hint: 'Person 1',
                  onChanged: (value) => setState(() => selectedP1 = value),
                  width: double.infinity,
                  allPeople: allPeople,
                  isP1: true,
                ),
              ),
              const SizedBox(width: 8),

              // Debit/Credit dropdown
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceVariant,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: transactionType,
                    hint: const Text('Type', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    isDense: true,
                    items: [
                      DropdownMenuItem(
                        value: 'debit',
                        child: Text(
                          'Debit',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'credit',
                        child: Text(
                          'Credit',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        transactionType = value;
                        direction = value == 'debit' ? 'to' : 'from';
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Person 2
              Expanded(
                flex: 3,
                child: buildPersonDropdown(
                  selectedValue: selectedP2,
                  hint: 'Person 2',
                  onChanged: (value) => setState(() => selectedP2 = value),
                  width: double.infinity,
                  allPeople: allPeople,
                  isP1: false,
                ),
              ),

              const SizedBox(width: 8),

              // Amount field
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    prefixText: '\$',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Add Person button
              IconButton(
                onPressed: () => _showAddPersonDialog(),
                icon: Icon(Icons.person_add, color: colorScheme.primary),
                tooltip: 'Add Person',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Add button
              ElevatedButton(
                onPressed: isSaving ? null : _confirmEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    isSaving
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        : const Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJournalDataSection() {
    final colorScheme = Theme.of(context).colorScheme;

    // Only show tabs if journal exists AND has entries
    if (journalTitleController.text.trim().isEmpty ||
        (!journalExists && !hasEntriesInJournal)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.history), text: 'Journal History'),
                Tab(
                  icon: Icon(Icons.account_balance),
                  text: 'Credit/Debit Summary',
                ),
              ],
            ),
          ),

          // Tab Views - Increased height for better scrolling
          SizedBox(
            height: 500, // Increased from 400 to 500
            child: TabBarView(
              controller: _tabController,
              children: [_buildJournalHistoryTab(), _buildCreditDebitTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoadingJournalData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentJournalEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No entries found in this journal',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filter Row
          Row(
            children: [
              Text(
                'Total Entries: ${currentJournalEntries.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _dateRangeText,
                        style: TextStyle(
                          color:
                              isDateRangeActive
                                  ? Theme.of(context).primaryColor
                                  : Colors.black54,
                          fontWeight:
                              isDateRangeActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => _selectDateRange(context),
                    ),
                    if (isDateRangeActive)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: _clearDateFilter,
                        tooltip: 'Clear date filter',
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[600]!, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.grey[50]!, Colors.grey[100]!],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[600]!,
                            width: 1.5,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Date Column
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'DATE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Creditor Column (Person who receives money)
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'CREDITOR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF059669),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Debtor Column (Person who gives money)
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'DEBTOR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFFDC2626),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Amount Column
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: const Center(
                                child: Text(
                                  'AMOUNT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2563EB),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Body - Dynamic size based on entries
                    Column(
                      children:
                          currentJournalEntries.asMap().entries.map((mapEntry) {
                            final index = mapEntry.key;
                            final entry = mapEntry.value;
                            final isEvenRow = index % 2 == 0;

                            // Determine creditor and debtor based on direction
                            String creditor = '';
                            String debtor = '';

                            if (entry['direction'] == 'to') {
                              // P1 gives to P2 -> P1 is debtor, P2 is creditor
                              debtor = entry['p1'] ?? '';
                              creditor = entry['p2'] ?? '';
                            } else if (entry['direction'] == 'from') {
                              // P1 takes from P2 -> P1 is creditor, P2 is debtor
                              creditor = entry['p1'] ?? '';
                              debtor = entry['p2'] ?? '';
                            }

                            return Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color:
                                    isEvenRow ? Colors.white : Colors.grey[25],
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[500]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Date
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey[500]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(entry['timestamp']),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Creditor (Person who receives money)
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey[500]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          creditor,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Debtor (Person who gives money)
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey[500]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          debtor,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Amount
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '\$${NumberFormat('#,##,##0').format(entry['amount'])}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w500,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Fixed Credit/Debit tab to show consistent data structure
  Widget _buildCreditDebitTab() {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoadingJournalData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentJournalCreditDebitSummary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No balance data available',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate totals using the same logic as Journal Report
    double totalCredit = 0;
    double totalDebit = 0;

    for (var summary in currentJournalCreditDebitSummary) {
      totalCredit += summary['credit'];
      totalDebit += summary['debit'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary Cards - Same structure as Journal Report

          // Person-wise table - Same structure as Journal Report
          Text(
            'Person-wise Balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[600]!, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header - Excel style
                Container(
                  height: 50, // Increased from 35 to 50
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey[50]!, Colors.grey[100]!],
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[600]!, width: 1.5),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Person Name Column
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ), // Increased padding
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Center(
                            // Center aligned
                            child: Text(
                              'PERSON NAME',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Increased from 11 to 14
                                color: Color(0xFF374151),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Credit Column
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ), // Increased padding
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Center(
                            // Center aligned
                            child: Text(
                              'CREDIT',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Increased from 11 to 14
                                color: Color(0xFF059669),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Debit Column
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ), // Increased padding
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Center(
                            // Center aligned
                            child: Text(
                              'DEBIT',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Increased from 11 to 14
                                color: Color(0xFFDC2626),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Balance Column
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ), // Increased padding
                          child: const Center(
                            // Center aligned
                            child: Text(
                              'BALANCE',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Increased from 11 to 14
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Body - Compact dynamic rows
                Column(
                  children:
                      currentJournalCreditDebitSummary.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final summary = entry.value;
                        final balance = summary['balance'] ?? 0.0;
                        final isEvenRow = index % 2 == 0;

                        return Container(
                          height: 45, // Increased from 32 to 45
                          decoration: BoxDecoration(
                            color: isEvenRow ? Colors.white : Colors.grey[25],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[500]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Person Name
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ), // Increased padding
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[500]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    // Center aligned
                                    child: Text(
                                      summary['person'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13, // Increased from 11 to 13
                                        color: Color(0xFF374151),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              // Credit
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ), // Increased padding
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[500]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    // Center aligned
                                    child: Text(
                                      summary['credit'] > 0
                                          ? '\$${NumberFormat('#,##,##0').format(summary['credit'])}'
                                          : '',
                                      style: TextStyle(
                                        fontSize: 13, // Increased from 11 to 13
                                        fontWeight:
                                            summary['credit'] > 0
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                        color:
                                            summary['credit'] > 0
                                                ? const Color(0xFF059669)
                                                : Colors.transparent,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Debit
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ), // Increased padding
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[500]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    // Center aligned
                                    child: Text(
                                      summary['debit'] > 0
                                          ? '\$${NumberFormat('#,##,##0').format(summary['debit'])}'
                                          : '',
                                      style: TextStyle(
                                        fontSize: 13, // Increased from 11 to 13
                                        fontWeight:
                                            summary['debit'] > 0
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                        color:
                                            summary['debit'] > 0
                                                ? const Color(0xFFDC2626)
                                                : Colors.transparent,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Balance
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ), // Increased padding
                                  child: Center(
                                    // Center aligned
                                    child: Text(
                                      '\$${NumberFormat('#,##,##0').format(balance.abs())}',
                                      style: TextStyle(
                                        fontSize: 13, // Increased from 11 to 13
                                        fontWeight: FontWeight.w600,
                                        color:
                                            balance > 0
                                                ? const Color(0xFF059669)
                                                : balance < 0
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF6B7280),
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
