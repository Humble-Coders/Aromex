import 'package:aromex/pages/home/main.dart';
import 'package:aromex/pages/home/pages/add_journel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalReportPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(Pages)? onPageChange;
  const JournalReportPage({super.key, this.onBack, this.onPageChange});

  @override
  State<JournalReportPage> createState() => _JournalReportPageState();
}

class _JournalReportPageState extends State<JournalReportPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> filteredJournals = [];

  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  // Separate search controllers for each tab
  final TextEditingController _journalsSearchController =
      TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();
  final TextEditingController _masterSearchController = TextEditingController();

  // Separate filters for each tab
  String _journalsSearchQuery = '';
  String _historySearchQuery = '';
  String _masterSearchQuery = '';

  // History tab filters
  String? _selectedDirection;
  String? _selectedTransactionType;

  // All Journals tab filters
  String? _allJournalsDirection;
  String? _allJournalsTransactionType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalsSearchController.dispose();
    _historySearchController.dispose();
    _masterSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get all journal documents
      final journalsSnapshot = await _firestore.collection('journals').get();

      List<Map<String, dynamic>> allTransactions = [];
      List<Map<String, dynamic>> allJournals = [];

      // Loop through each journal and get its entries
      for (var journalDoc in journalsSnapshot.docs) {
        final journalData = journalDoc.data();
        final entriesSnapshot =
            await journalDoc.reference
                .collection('entries')
                .orderBy('timestamp', descending: true)
                .get();

        // Create journal entry with its transactions
        final journalTransactions =
            entriesSnapshot.docs.map((entryDoc) {
              final entryData = entryDoc.data();
              return {
                'id': entryDoc.id,
                'journalId': journalDoc.id,
                'title': journalData['title'] ?? 'No Title',
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

        // Add journal with its transactions
        allJournals.add({
          'id': journalDoc.id,
          'title': journalData['title'] ?? 'No Title',
          'createdAt':
              (journalData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          'transactions': journalTransactions,
        });
        // After getting all journals, filter out entity-specific ones:
        allJournals =
            allJournals.where((journal) {
              String title = journal['title'] ?? '';
              // Exclude auto-generated entity journals
              return !title.contains('_Transactions') &&
                  !title.startsWith('Customer_') &&
                  !title.startsWith('Supplier_') &&
                  !title.startsWith('Middleman_') &&
                  !title.startsWith('Person_');
            }).toList();

        allTransactions.addAll(journalTransactions);
      }

      // Sort transactions by timestamp
      allTransactions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Sort journals by creation date
      allJournals.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      await _cleanupOldTransactions();

      setState(() {
        _transactions = allTransactions;
        filteredJournals = allJournals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load transactions: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading transactions: $e');
    }
  }

  // Use EXACTLY same _calculateTotals from JournalEntryPage
  Map<String, double> _getJournalTotals(
    List<Map<String, dynamic>> transactions,
  ) {
    return _calculateTotals(transactions); // Use the main method
  }

  // Use EXACTLY same _calculatePersonTotals from JournalEntryPage
  Map<String, Map<String, double>> _getJournalPersonTotals(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, double> personTotals = _calculatePersonTotals(
      transactions,
    ); // Use the main method
    return {'personTotals': personTotals};
  }
  // FIXED: Exactly same calculation as Journal Entry
  // 1. Update _getJournalTotals method
  // Map<String, double> _getJournalTotals(List<Map<String, dynamic>> transactions) {
  //   double credit = 0;
  //   double debit = 0;

  //   for (var transaction in transactions) {
  //     final amount = (transaction['amount'] as num).toDouble();
  //     final p1 = transaction['p1'] as String;
  //     final p2 = transaction['p2'] as String;
  //     final direction = transaction['direction'];

  //     // Same logic as Journal Entry Page
  //     if (p1 == 'I') {
  //       if (direction == 'to') {
  //         debit += amount;  // I give money
  //       } else if (direction == 'from') {
  //         credit += amount; // I receive money
  //       }
  //     } else if (p2 == 'I') {
  //       if (direction == 'to') {
  //         credit += amount; // Someone gives to I
  //       } else if (direction == 'from') {
  //         debit += amount;  // Someone receives from I
  //       }
  //     } else {
  //       // Facilitated transactions
  //       if (direction == 'to') {
  //         credit += amount; // I effectively received
  //       } else if (direction == 'from') {
  //         debit += amount;  // I effectively gave
  //       }
  //     }
  //   }

  //   return {'credit': credit, 'debit': debit};
  // }

  // FIXED: Exactly same person calculation as Journal Entry
  // Map<String, Map<String, double>> _getJournalPersonTotals(
  //   List<Map<String, dynamic>> transactions,
  // ) {
  //   Map<String, double> personTotals = {};

  //   for (var transaction in transactions) {
  //     final amount = (transaction['amount'] as num).toDouble();
  //     final p1 = transaction['p1'] as String;
  //     final p2 = transaction['p2'] as String;

  //     // FIXED: Exactly same logic as Journal Entry
  //     if (transaction['direction'] == 'to') {
  //       // p1 gives to p2, so p1 has negative balance, p2 has positive
  //       personTotals[p1] = (personTotals[p1] ?? 0) - amount;
  //       personTotals[p2] = (personTotals[p2] ?? 0) + amount;
  //     } else if (transaction['direction'] == 'from') {
  //       // p1 receives from p2, so p1 has positive balance, p2 has negative
  //       personTotals[p1] = (personTotals[p1] ?? 0) + amount;
  //       personTotals[p2] = (personTotals[p2] ?? 0) - amount;
  //     }
  //   }

  //   return {'personTotals': personTotals};
  // }

  Future<void> _cleanupOldTransactions() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final journalsSnapshot = await _firestore.collection('journals').get();

      for (var journalDoc in journalsSnapshot.docs) {
        final oldEntriesSnapshot =
            await journalDoc.reference
                .collection('entries')
                .where(
                  'timestamp',
                  isLessThan: Timestamp.fromDate(thirtyDaysAgo),
                )
                .get();

        final batch = _firestore.batch();
        int deleteCount = 0;

        for (var entryDoc in oldEntriesSnapshot.docs) {
          final entryData = entryDoc.data();
          final amount = entryData['amount'] ?? 0;

          if (amount == 0 || amount == null) {
            batch.delete(entryDoc.reference);
            deleteCount++;

            if (deleteCount >= 450) {
              await batch.commit();
              deleteCount = 0;
            }
          }
        }

        if (deleteCount > 0) {
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old transactions: $e');
    }
  }

  // FIXED: Same calculation as Journal Entry
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

  // FIXED: Same person calculation as Journal Entry
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

  // FIXED: Better filtered journals getter
  List<Map<String, dynamic>> get _filteredJournals {
    return filteredJournals.where((journal) {
      final transactions =
          journal['transactions'] as List<Map<String, dynamic>>? ?? [];

      // Apply filters to transactions within the journal
      final filteredTransactions =
          transactions.where((transaction) {
            // Search filter
            if (_journalsSearchQuery.isNotEmpty) {
              final searchLower = _journalsSearchQuery.toLowerCase();
              bool matchesSearch = false;

              // Check journal title
              if (journal['title']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) {
                matchesSearch = true;
              }

              // Check transaction person names
              if (transaction['p1']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) {
                matchesSearch = true;
              }

              if (transaction['p2']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) {
                matchesSearch = true;
              }

              if (!matchesSearch) {
                return false;
              }
            }

            // Direction filter
            if (_allJournalsDirection != null &&
                transaction['direction'] != _allJournalsDirection) {
              return false;
            }

            // Transaction type filter
            if (_allJournalsTransactionType != null &&
                transaction['transactionType'] != _allJournalsTransactionType) {
              return false;
            }

            return true;
          }).toList();

      // Only show journal if it has matching transactions OR if no filters are applied
      if (_journalsSearchQuery.isNotEmpty ||
          _allJournalsDirection != null ||
          _allJournalsTransactionType != null) {
        return filteredTransactions.isNotEmpty;
      }

      return true;
    }).toList();
  }

  // FIXED: Journal totals calculation
  Map<String, double> get _journalTotals {
    double credit = 0;
    double debit = 0;

    for (var journal in _filteredJournals) {
      final transactions =
          journal['transactions'] as List<Map<String, dynamic>>? ?? [];
      final journalTotals = _getJournalTotals(transactions);

      credit += journalTotals['credit'] ?? 0;
      debit += journalTotals['debit'] ?? 0;
    }

    return {'credit': credit, 'debit': debit};
  }

  // Filtered transactions for History tab
  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Search filter (title, person names)
      if (_historySearchQuery.isNotEmpty) {
        final searchLower = _historySearchQuery.toLowerCase();
        if (!(transaction['p1']?.toString().toLowerCase().contains(
                  searchLower,
                ) ??
                false) &&
            !(transaction['p2']?.toString().toLowerCase().contains(
                  searchLower,
                ) ??
                false) &&
            !(transaction['title']?.toString().toLowerCase().contains(
                  searchLower,
                ) ??
                false)) {
          return false;
        }
      }

      // Direction filter
      if (_selectedDirection != null &&
          transaction['direction'] != _selectedDirection) {
        return false;
      }

      // Transaction type filter
      if (_selectedTransactionType != null &&
          transaction['transactionType'] != _selectedTransactionType) {
        return false;
      }

      return true;
    }).toList();
  }

  // Master table data with search filter - FIXED
  Map<String, double> get _masterTablePersonTotals {
    Map<String, double> personTotals = _calculatePersonTotals(_transactions);

    // Filter to show only I-related balances
    final iCentricBalances = Map<String, double>.from(personTotals)
      ..removeWhere((person, balance) => person == 'I' || balance == 0);

    // Filter by search query if any
    if (_masterSearchQuery.isNotEmpty) {
      final searchLower = _masterSearchQuery.toLowerCase();
      iCentricBalances.removeWhere(
        (person, balance) => !person.toLowerCase().contains(searchLower),
      );
    }

    return iCentricBalances;
  }

  // Navigate to edit journal page with journal title
  void _editJournal(String journalId, String journalTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => JournalEntryPage(
              initialJournalTitle: journalTitle,
              onBack: () => Navigator.pop(context),
              onPageChange: widget.onPageChange,
            ),
      ),
    ).then((_) {
      _loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => JournalEntryPage(
                          onBack: () => Navigator.pop(context),
                          onPageChange: widget.onPageChange,
                        ),
                  ),
                ).then((_) => _loadTransactions()),
            child: const Text(
              'New Entry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Tabs Section
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'ALL JOURNALS'),
                Tab(text: 'HISTORY'),
                Tab(text: 'MASTER TABLE'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildAllJournalsTab(),
                _buildHistoryTab(),
                _buildMasterTableTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAllJournalsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
        ? Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        )
        : Column(
          children: [
            // Filters Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _journalsSearchController,
                      decoration: const InputDecoration(
                        hintText: 'SEARCH JOURNALS',
                        hintStyle: TextStyle(fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _journalsSearchQuery = value;
                        });
                        //   debugFilters();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row with Filters and Totals
                  Row(
                    children: [
                      // Left side - Filters
                      Expanded(
                        child: Column(
                          children: [
                            // Direction Filter
                            DropdownButtonFormField<String>(
                              value: _allJournalsDirection,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'DIRECTIONS',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Directions'),
                                ),
                                DropdownMenuItem(
                                  value: 'to',
                                  child: Text('To'),
                                ),
                                DropdownMenuItem(
                                  value: 'from',
                                  child: Text('From'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _allJournalsDirection = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Transaction Type Filter
                            DropdownButtonFormField<String>(
                              value: _allJournalsTransactionType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'GIVES/RECEIVES',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Types'),
                                ),
                                DropdownMenuItem(
                                  value: 'gives',
                                  child: Text('Gives'),
                                ),
                                DropdownMenuItem(
                                  value: 'takes',
                                  child: Text('Receives'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _allJournalsTransactionType = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Right side - Credit/Debit Totals
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'CREDIT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${NumberFormat('#,##0').format(_journalTotals['credit'] ?? 0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'DEBIT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${NumberFormat('#,##0').format(_journalTotals['debit'] ?? 0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Journal List
            Expanded(
              child:
                  _filteredJournals.isEmpty
                      ? const Center(
                        child: Text(
                          'No journals found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredJournals.length,
                        itemBuilder: (context, index) {
                          final journal = _filteredJournals[index];
                          return buildJournalCard(journal);
                        },
                      ),
            ),
          ],
        );
  }

  Widget buildJournalCard(Map<String, dynamic> journal) {
    final transactions = journal['transactions'] as List<Map<String, dynamic>>;
    final journalTotals = _getJournalTotals(transactions);
    final personTotals = _getJournalPersonTotals(transactions);
    final persons = personTotals['personTotals'] as Map<String, double>;
    final colorScheme = Theme.of(context).colorScheme;
    // Filter to show only I-related balances
    final iRelatedPersons = Map<String, double>.from(persons)
      ..removeWhere((person, balance) => person == 'I' || balance == 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                journal['title'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    'CREDIT',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${NumberFormat('#,##0').format(journalTotals['credit']!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    'DEBIT',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${NumberFormat('#,##0').format(journalTotals['debit']!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Edit Button
            IconButton(
              onPressed: () {
                _editJournal(journal['id'], journal['title']);
              },
              icon: Icon(Icons.edit, size: 20, color: Colors.blue[600]),
              tooltip: 'Edit Journal',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        children: [
          if (iRelatedPersons.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Table Header - EXACT SAME STYLE AS MASTER TABLE
                  Container(
                    height: 45, // Slightly smaller for card context
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
                        // Person Name Column
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
                                  color: Colors.grey[600]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'PERSON NAME',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12, // Slightly smaller for card
                                  color: Color(0xFF374151),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Credit Column
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
                                  color: Colors.grey[600]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'CREDIT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF059669),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Debit Column
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: const Center(
                              child: Text(
                                'DEBIT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Body - DYNAMIC SIZE WITH SAME EXCEL STYLE
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        iRelatedPersons.entries.toList().asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final personEntry = entry.value;
                          final person = personEntry.key;
                          final balance = personEntry.value;
                          final credit = balance > 0 ? balance : 0.0;
                          final debit = balance < 0 ? balance.abs() : 0.0;
                          final isEvenRow = index % 2 == 0;

                          return Container(
                            height: 40, // Slightly smaller for card context
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
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
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
                                        person,
                                        style: const TextStyle(
                                          fontSize: 12,
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
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
                                        credit > 0
                                            ? '\$${NumberFormat('#,##,##0').format(credit)}'
                                            : '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              credit > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                          color:
                                              credit > 0
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
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Center(
                                      child: Text(
                                        debit > 0
                                            ? '\$${NumberFormat('#,##,##0').format(debit)}'
                                            : '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              debit > 0
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                          color:
                                              debit > 0
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

  // FIXED: Transaction totals for History tab
  Map<String, double> get _transactionTotals {
    double credit = 0;
    double debit = 0;

    for (var transaction in _filteredTransactions) {
      final amount = (transaction['amount'] as num).toDouble();

      // FIXED: Same logic as Journal Entry
      if (transaction['direction'] == 'from') {
        credit += amount;
      } else if (transaction['direction'] == 'to') {
        debit += amount;
      }
    }

    return {'credit': credit, 'debit': debit};
  }

  Widget _buildHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search and Filter section
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _historySearchController,
                  decoration: InputDecoration(
                    hintText: 'SEARCH TRANSACTIONS',
                    hintStyle: const TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _historySearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Filters and Totals Row
              Row(
                children: [
                  // Left side - Filters
                  Expanded(
                    child: Column(
                      children: [
                        // Direction Filter
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surfaceVariant,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDirection,
                              hint: Text(
                                'DIRECTIONS',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: colorScheme.surface,
                              elevation: 8,
                              borderRadius: BorderRadius.circular(8),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Directions'),
                                ),
                                DropdownMenuItem(
                                  value: 'to',
                                  child: Text('To'),
                                ),
                                DropdownMenuItem(
                                  value: 'from',
                                  child: Text('From'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDirection = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Transaction Type Filter
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surfaceVariant,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTransactionType,
                              hint: Text(
                                'GIVES/RECEIVES',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: colorScheme.surface,
                              elevation: 8,
                              borderRadius: BorderRadius.circular(8),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Types'),
                                ),
                                DropdownMenuItem(
                                  value: 'gives',
                                  child: Text('Gives'),
                                ),
                                DropdownMenuItem(
                                  value: 'takes',
                                  child: Text('Receives'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedTransactionType = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right side - Credit/Debit Totals
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.green.shade50,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'CREDIT',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '\$${NumberFormat('#,##0').format(_transactionTotals['credit']!)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red.shade50,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'DEBIT',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '\$${NumberFormat('#,##0').format(_transactionTotals['debit']!)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Excel-style Table
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTransactions.isEmpty
                  ? Center(
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
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total count header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Total Transactions: ${_filteredTransactions.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      // Excel-style Table
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 1.5,
                              ),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Table Header
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.grey[50]!,
                                        Colors.grey[100]!,
                                      ],
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
                                      // Journal Column
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
                                              'JOURNAL',
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
                                      // Money Receiver Column
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
                                              'RECEIVER',
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
                                      // Money Giver Column
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
                                              'GIVER',
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

                                // Table Body
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                      _filteredTransactions.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final transaction = entry.value;
                                        final isEvenRow = index % 2 == 0;

                                        // Determine receiver and giver based on direction
                                        String receiver = '';
                                        String giver = '';

                                        if (transaction['direction'] == 'to') {
                                          // P1 gives to P2
                                          giver = transaction['p1'] ?? '';
                                          receiver = transaction['p2'] ?? '';
                                        } else if (transaction['direction'] ==
                                            'from') {
                                          // P1 receives from P2
                                          receiver = transaction['p1'] ?? '';
                                          giver = transaction['p2'] ?? '';
                                        }

                                        return Container(
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color:
                                                isEvenRow
                                                    ? Colors.white
                                                    : Colors.grey[25],
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
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color:
                                                            Colors.grey[500]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      DateFormat(
                                                        'dd/MM/yyyy',
                                                      ).format(
                                                        transaction['timestamp'],
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF374151,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Journal
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color:
                                                            Colors.grey[500]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      transaction['title'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF374151,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Receiver
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color:
                                                            Colors.grey[500]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      receiver,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF059669,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Giver
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color:
                                                            Colors.grey[500]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      giver,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFFDC2626,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Amount
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  child: Center(
                                                    child: Text(
                                                      '\$${NumberFormat('#,##,##0').format(transaction['amount'])}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
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
        ),
      ],
    );
  }

  // FIXED: Master Table Tab - SAME STRUCTURE AS JOURNAL ENTRY
  Widget _buildMasterTableTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search section - SAME STYLE AS JOURNAL ENTRY
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _masterSearchController,
              decoration: InputDecoration(
                hintText: 'SEARCH PERSONS',
                hintStyle: const TextStyle(fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _masterSearchQuery = value;
                });
              },
            ),
          ),
        ),

        // Master Table - DYNAMIC SIZE EXCEL DESIGN
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 1.5,
                        ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Table Header - EXCEL STYLE
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
                                // Person Name Column
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
                                        'PERSON NAME',
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
                                // Credit Column
                                Expanded(
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
                                        'CREDIT',
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
                                // Debit Column
                                Expanded(
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
                                        'DEBIT',
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
                                // Balance Column
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'BALANCE',
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
                          // Table Body - DYNAMIC SIZE BASED ON ENTRIES
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                (() {
                                  // Calculate person balances using same logic as Journal Entry
                                  // Calculate person balances using same logic as Journal Entry
                                  final personBalances = _calculatePersonTotals(
                                    _transactions,
                                  );

                                  // Filter to show only I-related balances (exclude 'I' and zero balances)
                                  final iCentricBalances =
                                      Map<String, double>.from(personBalances)
                                        ..removeWhere(
                                          (person, balance) =>
                                              person == 'I' || balance == 0,
                                        );

                                  // Get all unique persons and filter by search
                                  var allPersons =
                                      iCentricBalances.keys.toList();

                                  if (_masterSearchQuery.isNotEmpty) {
                                    final searchLower =
                                        _masterSearchQuery.toLowerCase();
                                    allPersons =
                                        allPersons
                                            .where(
                                              (person) => person
                                                  .toLowerCase()
                                                  .contains(searchLower),
                                            )
                                            .toList();
                                  }

                                  allPersons.sort();

                                  // Return empty list widget if no persons found
                                  if (allPersons.isEmpty) {
                                    return [
                                      Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[500]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'No persons found',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ];
                                  }

                                  return allPersons.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final person = entry.value;
                                    final balance =
                                        iCentricBalances[person] ?? 0;

                                    final credit = balance > 0 ? balance : 0.0;
                                    final debit =
                                        balance < 0 ? balance.abs() : 0.0;
                                    final isEvenRow = index % 2 == 0;

                                    return Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color:
                                            isEvenRow
                                                ? Colors.white
                                                : Colors.grey[25],
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  person,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF374151),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Credit
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  credit > 0
                                                      ? '\$${NumberFormat('#,##,##0').format(credit)}'
                                                      : '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        credit > 0
                                                            ? FontWeight.w500
                                                            : FontWeight.w400,
                                                    color:
                                                        credit > 0
                                                            ? const Color(
                                                              0xFF059669,
                                                            )
                                                            : Colors
                                                                .transparent,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  debit > 0
                                                      ? '\$${NumberFormat('#,##,##0').format(debit)}'
                                                      : '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        debit > 0
                                                            ? FontWeight.w500
                                                            : FontWeight.w400,
                                                    color:
                                                        debit > 0
                                                            ? const Color(
                                                              0xFFDC2626,
                                                            )
                                                            : Colors
                                                                .transparent,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              child: Center(
                                                child: Text(
                                                  '\$${NumberFormat('#,##,##0').format(balance.abs())}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        balance > 0
                                                            ? const Color(
                                                              0xFF059669,
                                                            )
                                                            : balance < 0
                                                            ? const Color(
                                                              0xFFDC2626,
                                                            )
                                                            : const Color(
                                                              0xFF6B7280,
                                                            ),
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
                                  }).toList();
                                })(),
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = transaction['direction'] == 'from';
    final amount = (transaction['amount'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction['p1']} ${transaction['direction']} ${transaction['p2']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(transaction['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,##0').format(amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCredit ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isCredit ? 'CR' : 'DR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
