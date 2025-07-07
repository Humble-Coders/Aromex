import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceCalculatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for person data to avoid repeated Firestore queries
  static final Map<String, Map<String, double>> _personBalanceCache = {};
  static final Map<String, String> _personTypeCache = {};
  static final Set<String> _allPersonsCache = {};
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Clear cache when needed (call this when person data changes)
  static void clearCache() {
    _personBalanceCache.clear();
    _personTypeCache.clear();
    _allPersonsCache.clear();
    _cacheTimestamp = null;
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheTimeout;
  }

  /// Calculate final balances for a specific entry
  Future<Map<String, Map<String, double>>> calculateFinalBalances(
    Map<String, dynamic> entry,
    List<Map<String, dynamic>> allEntries,
  ) async {
    print('🔵 STARTING BALANCE CALCULATION');
    print('Entry: $entry');

    Map<String, Map<String, double>> balances = {};

    // Get persons involved in this transaction
    final person1 = entry['person1'] as String;
    final person2 = entry['person2'] as String;

    print('🔵 Person1: $person1, Person2: $person2');

    // Initialize balances for all persons who have transactions
    Set<String> allPersons = {};

    // First, collect all persons from all entries up to current timestamp
    final entryTimestamp = entry['timestamp'] as DateTime;

    for (var e in allEntries) {
      final timestamp = e['timestamp'] as DateTime;
      if (timestamp.isAfter(entryTimestamp)) continue;

      final p1 = e['person1'] as String;
      final p2 = e['person2'] as String;

      if (p1 != 'Myself') allPersons.add(p1);
      if (p2 != 'Myself') allPersons.add(p2);
    }

    // Initialize balances for all persons
    for (var person in allPersons) {
      balances[person] = {'INR': 0, 'USD': 0, 'AED': 0};
      print('🔵 Initialized balance for $person: ${balances[person]}');

      // Fetch existing balance from person's account if available
      await _fetchPersonExistingBalance(person, balances[person]!);
      print(
        '🔵 After fetching existing balance for $person: ${balances[person]}',
      );
    }

    // Sort entries by timestamp in chronological order (oldest first) - OPTIMIZED
    List<Map<String, dynamic>> sortedEntries = _getSortedEntries(allEntries);

    // Process all transactions chronologically
    for (var e in sortedEntries) {
      final timestamp = e['timestamp'] as DateTime;

      // Include transactions that are before OR at the same time as current entry
      if (timestamp.isAfter(entryTimestamp)) {
        continue;
      }

      await _processTransaction(e, balances);
    }

    // Apply commission if exists in current entry
    _applyCommission(entry, balances);

    print('🔵 FINAL BALANCES:');
    balances.forEach((person, balance) {
      print('🔵 $person: $balance');
    });

    return balances;
  }

  /// Calculate balance report for all entries
  /// This processes ALL transactions in the system
  /// NOW USES EXACT SAME LOGIC AS calculateFinalBalances
  Future<Map<String, Map<String, double>>> calculateBalanceReport(
    List<Map<String, dynamic>> allEntries,
  ) async {
    print('🔵 STARTING BALANCE REPORT CALCULATION');

    Map<String, Map<String, double>> balances = {};

    // Initialize balances for all persons who have transactions
    Set<String> allPersons = {};
    Set<String> allPersonsInDatabase = await _getAllPersonsFromDatabase();

    // Combine both sets to get all persons
    allPersons.addAll(allPersonsInDatabase);
    // Collect all persons from all entries
    for (var e in allEntries) {
      final p1 = e['person1'] as String;
      final p2 = e['person2'] as String;

      if (p1 != 'Myself') allPersons.add(p1);
      if (p2 != 'Myself') allPersons.add(p2);
    }

    // OPTIMIZED: Batch fetch all person balances
    await _batchFetchPersonBalances(allPersons.toList());

    // Initialize balances for all persons
    for (var person in allPersons) {
      balances[person] = {'INR': 0, 'USD': 0, 'AED': 0};
      print('🔵 Initialized balance for $person: ${balances[person]}');

      // Fetch existing balance from person's account if available
      await _fetchPersonExistingBalance(person, balances[person]!);
      print(
        '🔵 After fetching existing balance for $person: ${balances[person]}',
      );
    }

    // Sort entries by timestamp in chronological order (oldest first) - OPTIMIZED
    List<Map<String, dynamic>> sortedEntries = _getSortedEntries(allEntries);

    // Process all transactions chronologically using the SAME method as calculateFinalBalances
    for (var e in sortedEntries) {
      await _processTransaction(e, balances);
    }

    print('🔵 FINAL BALANCES:');
    balances.forEach((person, balance) {
      print('🔵 $person: $balance');
    });

    // Remove persons with zero balances in all currencies (optional)
    balances.removeWhere((person, balance) {
      return balance.values.every((val) => val == 0);
    });

    return balances;
  }

  /// OPTIMIZED: Get sorted entries (cached if possible)
  List<Map<String, dynamic>> _getSortedEntries(
    List<Map<String, dynamic>> allEntries,
  ) {
    List<Map<String, dynamic>> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) {
      DateTime aTime = a['timestamp'] as DateTime;
      DateTime bTime = b['timestamp'] as DateTime;
      return aTime.compareTo(bTime);
    });
    return sortedEntries;
  }

  /// OPTIMIZED: Batch fetch person balances to reduce Firestore calls
  Future<void> _batchFetchPersonBalances(List<String> personNames) async {
    if (_isCacheValid()) {
      print('🔵 Using cached person data');
      return;
    }

    print(
      '🔵 Batch fetching person balances for ${personNames.length} persons',
    );

    try {
      // Fetch all collections in parallel
      final collections = ['Customers', 'Suppliers', 'Middlemen', 'Person'];

      List<Future<QuerySnapshot>> futures =
          collections.map((collection) {
            return _firestore.collection(collection).get();
          }).toList();

      List<QuerySnapshot> snapshots = await Future.wait(futures);

      // Process all snapshots
      for (int i = 0; i < snapshots.length; i++) {
        String collectionName = collections[i];
        QuerySnapshot snapshot = snapshots[i];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('name')) {
            String personName = data['name'] as String;
            if (personName != 'Myself') {
              // Cache person type
              _personTypeCache[personName] = _getPersonTypeFromCollection(
                collectionName,
              );
              _allPersonsCache.add(personName);

              // Cache person balance
              Map<String, double> balance = {'INR': 0, 'USD': 0, 'AED': 0};

              if (data.containsKey('balance')) {
                final existingBalance = data['balance'];
                if (existingBalance != null) {
                  if (existingBalance is Map) {
                    existingBalance.forEach((key, value) {
                      String currency = key.toString();
                      double amount = (value as num).toDouble();
                      balance[currency] = (balance[currency] ?? 0) + amount;
                    });
                  } else if (existingBalance is num) {
                    double amount = existingBalance.toDouble();
                    balance['USD'] = (balance['USD'] ?? 0) + amount;
                  }
                }
              }

              _personBalanceCache[personName] = balance;
            }
          }
        }
      }

      _cacheTimestamp = DateTime.now();
      print('🔵 Cached ${_personBalanceCache.length} person balances');
    } catch (e) {
      print('🔴 Error in batch fetching person balances: $e');
    }
  }

  String _getPersonTypeFromCollection(String collectionName) {
    switch (collectionName) {
      case 'Customers':
        return 'Customer';
      case 'Suppliers':
        return 'Supplier';
      case 'Middlemen':
        return 'Middleman';
      default:
        return 'Person';
    }
  }

  Future<void> _processTransaction(
    Map<String, dynamic> e,
    Map<String, Map<String, double>> balances,
  ) async {
    final p1 = e['person1'] as String;
    final p2 = e['person2'] as String;
    final dir = e['direction'] as String;
    final amt = (e['amount'] as num).toDouble();
    final convAmt = (e['convertedAmount'] as num).toDouble();
    final fromCur = e['fromCurrency'] as String;
    final toCur = e['toCurrency'] as String;
    final isCurrEx = e['isCurrencyExchange'] as bool;

    print('🔷 Processing transaction: $p1 $dir $p2, Amount: $amt $fromCur');

    // Case 1: Transaction involves Myself
    if (p1 == 'Myself' || p2 == 'Myself') {
      String otherPerson = p1 == 'Myself' ? p2 : p1;
      if (otherPerson == 'Myself') return;

      // Only calculate for persons in balances
      if (!balances.containsKey(otherPerson)) return;

      // Balance calculation logic:
      // Positive balance = They owe me (I gave them money or they took from me)
      // Negative balance = I owe them (They gave me money or I took from them)

      if (dir == 'give_to') {
        // Person1 gave money to Person2
        if (p1 == 'Myself') {
          // I gave money to otherPerson -> They owe me (POSITIVE)
          balances[otherPerson]![fromCur] =
              (balances[otherPerson]![fromCur] ?? 0) + amt;

          if (isCurrEx) {
            balances[otherPerson]![toCur] =
                (balances[otherPerson]![toCur] ?? 0) - convAmt;
          }
        } else {
          // otherPerson gave money to me -> I owe them (NEGATIVE)
          balances[otherPerson]![fromCur] =
              (balances[otherPerson]![fromCur] ?? 0) - amt;

          if (isCurrEx) {
            balances[otherPerson]![toCur] =
                (balances[otherPerson]![toCur] ?? 0) + convAmt;
          }
        }
      } else if (dir == 'take_from') {
        // Person1 took money from Person2
        if (p1 == 'Myself') {
          // I took money from otherPerson -> I owe them (NEGATIVE)
          balances[otherPerson]![fromCur] =
              (balances[otherPerson]![fromCur] ?? 0) - amt;

          if (isCurrEx) {
            balances[otherPerson]![toCur] =
                (balances[otherPerson]![toCur] ?? 0) + convAmt;
          }
        } else {
          // otherPerson took money from me -> They owe me (POSITIVE)
          balances[otherPerson]![fromCur] =
              (balances[otherPerson]![fromCur] ?? 0) + amt;

          if (isCurrEx) {
            balances[otherPerson]![toCur] =
                (balances[otherPerson]![toCur] ?? 0) - convAmt;
          }
        }
      }
    }
    // Case 2: Transaction between two other people (not involving Myself)
    else {
      // Both persons must be in our tracking list
      if (!balances.containsKey(p1) || !balances.containsKey(p2)) return;

      print('🔶 Processing third-party transaction between $p1 and $p2');

      // FIXED LOGIC FOR CURRENCY EXCHANGE:
      // When P1 gives money to P2 in currency exchange:
      // - P1's debt in fromCurrency should be reduced by the full amount
      // - P2's debt in toCurrency should increase by the converted amount
      // This ensures complete settlement of the original debt

      if (dir == 'give_to') {
        // Person1 gave money to Person2
        if (isCurrEx) {
          // Currency exchange: P1 gives fromCurrency, P2 receives equivalent in toCurrency
          // P1's debt in fromCurrency is completely settled
          balances[p1]![fromCur] = (balances[p1]![fromCur] ?? 0) - amt;
          // P2 now owes the converted amount in toCurrency
          balances[p2]![toCur] = (balances[p2]![toCur] ?? 0) + convAmt;

          print(
            '🔸 Currency Exchange: $p1 gave $amt $fromCur, $p2 owes $convAmt $toCur',
          );
        } else {
          // Regular transaction: both in same currency
          balances[p1]![fromCur] = (balances[p1]![fromCur] ?? 0) - amt;
          balances[p2]![fromCur] = (balances[p2]![fromCur] ?? 0) + amt;
        }
      } else if (dir == 'take_from') {
        // Person1 took money from Person2
        if (isCurrEx) {
          // Currency exchange: P1 takes fromCurrency, P2 gives equivalent in toCurrency
          // P1's debt in fromCurrency increases
          balances[p1]![fromCur] = (balances[p1]![fromCur] ?? 0) + amt;
          // P2's debt in toCurrency decreases (they gave equivalent)
          balances[p2]![toCur] = (balances[p2]![toCur] ?? 0) - convAmt;

          print(
            '🔸 Currency Exchange: $p1 took $amt $fromCur, $p2 gave equivalent $convAmt $toCur',
          );
        } else {
          // Regular transaction: both in same currency
          balances[p1]![fromCur] = (balances[p1]![fromCur] ?? 0) + amt;
          balances[p2]![fromCur] = (balances[p2]![fromCur] ?? 0) - amt;
        }
      }
    }

    // Apply commission for this transaction
    _applyCommission(e, balances);
  }

  /// Apply commission to the appropriate person
  void _applyCommission(
    Map<String, dynamic> entry,
    Map<String, Map<String, double>> balances,
  ) {
    final commissionPerson = entry['commissionPerson'];
    final commission = (entry['commission'] as num?)?.toDouble() ?? 0;
    final toCurrency = entry['toCurrency'] ?? 'USD';

    if (commissionPerson != null &&
        commission > 0 &&
        commissionPerson != 'Myself' &&
        balances.containsKey(commissionPerson)) {
      print(
        '🔸 Applying commission of $commission $toCurrency to $commissionPerson',
      );
      balances[commissionPerson]![toCurrency] =
          (balances[commissionPerson]![toCurrency] ?? 0) + commission;
    }
  }

  /// OPTIMIZED: Fetch existing balance from cache first, then Firestore if needed
  Future<void> _fetchPersonExistingBalance(
    String personName,
    Map<String, double> balance,
  ) async {
    // Check cache first
    if (_personBalanceCache.containsKey(personName)) {
      final cachedBalance = _personBalanceCache[personName]!;
      cachedBalance.forEach((currency, amount) {
        balance[currency] = (balance[currency] ?? 0) + amount;
      });
      return;
    }

    // Fallback to original logic if not in cache
    try {
      String? personType = await _getPersonType(personName);
      String collection = _getCollectionName(personType);

      final querySnapshot =
          await _firestore
              .collection(collection)
              .where('name', isEqualTo: personName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();

        if (data.containsKey('balance')) {
          final existingBalance = data['balance'];

          if (existingBalance != null) {
            if (existingBalance is Map) {
              existingBalance.forEach((key, value) {
                String currency = key.toString();
                double amount = (value as num).toDouble();
                balance[currency] = (balance[currency] ?? 0) + amount;
              });
            } else if (existingBalance is num) {
              double amount = existingBalance.toDouble();
              balance['USD'] = (balance['USD'] ?? 0) + amount;
            }
          }
        }

        // Cache the result
        Map<String, double> cacheBalance = {'INR': 0, 'USD': 0, 'AED': 0};
        balance.forEach((key, value) {
          cacheBalance[key] = value;
        });
        _personBalanceCache[personName] = cacheBalance;
      }
    } catch (e) {
      print('🔴 Error fetching existing balance for $personName: $e');
    }
  }

  /// OPTIMIZED: Get person type from cache first
  Future<String?> _getPersonType(String personName) async {
    // Check cache first
    if (_personTypeCache.containsKey(personName)) {
      return _personTypeCache[personName];
    }

    // Fallback to original logic
    final collections = ['Customers', 'Suppliers', 'Middlemen', 'Person'];

    for (String collection in collections) {
      final querySnapshot =
          await _firestore
              .collection(collection)
              .where('name', isEqualTo: personName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        String personType;
        switch (collection) {
          case 'Customers':
            personType = 'Customer';
            break;
          case 'Suppliers':
            personType = 'Supplier';
            break;
          case 'Middlemen':
            personType = 'Middleman';
            break;
          default:
            personType = 'Person';
        }

        // Cache the result
        _personTypeCache[personName] = personType;
        return personType;
      }
    }

    const defaultType = 'Person';
    _personTypeCache[personName] = defaultType;
    return defaultType;
  }

  /// Get collection name from person type
  String _getCollectionName(String? personType) {
    switch (personType) {
      case 'Customer':
        return 'Customers';
      case 'Supplier':
        return 'Suppliers';
      case 'Middleman':
        return 'Middlemen';
      default:
        return 'Person';
    }
  }

  /// OPTIMIZED: Get all persons from cache first
  Future<Set<String>> _getAllPersonsFromDatabase() async {
    if (_isCacheValid() && _allPersonsCache.isNotEmpty) {
      print('🔵 Using cached persons data: ${_allPersonsCache.length} persons');
      return _allPersonsCache;
    }

    Set<String> allPersons = {};

    try {
      // Check all collections for persons
      final collections = ['Customers', 'Suppliers', 'Middlemen', 'Person'];

      // Fetch all collections in parallel
      List<Future<QuerySnapshot>> futures =
          collections.map((collection) {
            print('🔵 Fetching persons from $collection collection');
            return _firestore.collection(collection).get();
          }).toList();

      List<QuerySnapshot> snapshots = await Future.wait(futures);

      for (int i = 0; i < snapshots.length; i++) {
        String collectionName = collections[i];
        QuerySnapshot snapshot = snapshots[i];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('name')) {
            String personName = data['name'] as String;
            if (personName != 'Myself') {
              allPersons.add(personName);
              // Cache person type while we're at it
              _personTypeCache[personName] = _getPersonTypeFromCollection(
                collectionName,
              );
            }
          }
        }
      }

      // Update cache
      _allPersonsCache.clear();
      _allPersonsCache.addAll(allPersons);
      _cacheTimestamp = DateTime.now();

      print('🔵 Found ${allPersons.length} persons in database: $allPersons');
    } catch (e) {
      print('🔴 Error fetching persons from database: $e');
    }

    return allPersons;
  }

  /// Calculate expected profit for a currency exchange transaction
  static double calculateExpectedProfit(
    Map<String, dynamic> entry,
    Map<String, double> marketRates,
  ) {
    final isCurrencyEntry = entry['isCurrencyExchange'] ?? false;
    if (!isCurrencyEntry) return 0;

    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final fromCurrency = entry['fromCurrency'] ?? '';
    final toCurrency = entry['toCurrency'] ?? '';
    final exchangeRate = (entry['exchangeRate'] as num?)?.toDouble() ?? 0;
    final direction = entry['direction'] ?? 'give_to';
    final person1 = entry['person1'] ?? '';
    final person2 = entry['person2'] ?? '';

    if (exchangeRate <= 0) return 0;

    // Get market rate
    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    final marketRate = marketRates[key] ?? 0;
    if (marketRate <= 0) return 0;

    double expectedProfit = 0;

    // When I'm involved in the transaction
    if (person1 == 'Myself' || person2 == 'Myself') {
      // Calculate profit based on the rate difference
      // Positive profit = I'm getting a better rate than market
      // Negative profit = I'm getting a worse rate than market

      if ((person1 == 'Myself' && direction == 'give_to') ||
          (person2 == 'Myself' && direction == 'take_from')) {
        // I'm giving fromCurrency and getting toCurrency
        // Better rate for me = lower exchange rate (I give less to get more)
        expectedProfit = (marketRate - exchangeRate) * amount;
      } else {
        // I'm getting fromCurrency and giving toCurrency
        // Better rate for me = higher exchange rate (I get more for giving less)
        expectedProfit = (exchangeRate - marketRate) * amount;
      }
    } else {
      // Transaction between two other people
      // Profit from facilitating the exchange
      expectedProfit = (exchangeRate - marketRate) * amount;
    }

    return expectedProfit;
  }
}
