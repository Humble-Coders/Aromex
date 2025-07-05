import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceCalculatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    // Sort entries by timestamp in chronological order (oldest first)
    List<Map<String, dynamic>> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) {
      DateTime aTime = a['timestamp'] as DateTime;
      DateTime bTime = b['timestamp'] as DateTime;
      return aTime.compareTo(bTime);
    });

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

    // Case 1: Transaction involves Myself
    if (p1 == 'Myself' || p2 == 'Myself') {
      String otherPerson = p1 == 'Myself' ? p2 : p1;
      if (otherPerson == 'Myself') return;

      // Only calculate for persons in current entry
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
  }

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
      balances[commissionPerson]![toCurrency] =
          (balances[commissionPerson]![toCurrency] ?? 0) + commission;
    }
  }

  Future<void> _fetchPersonExistingBalance(
    String personName,
    Map<String, double> balance,
  ) async {
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
      }
    } catch (e) {
      print('🔴 Error fetching existing balance for $personName: $e');
    }
  }

  Future<String?> _getPersonType(String personName) async {
    // Logic to determine person type
    return 'Person';
  }

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

  // Method for balance report calculations
  Map<String, Map<String, double>> calculateBalanceReport(
    List<Map<String, dynamic>> allEntries,
  ) {
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
    }

    // Sort entries by timestamp in chronological order (oldest first)
    List<Map<String, dynamic>> sortedEntries = List.from(allEntries);
    sortedEntries.sort((a, b) {
      DateTime aTime = a['timestamp'] as DateTime;
      DateTime bTime = b['timestamp'] as DateTime;
      return aTime.compareTo(bTime);
    });

    // Process all entries in chronological order
    for (var e in sortedEntries) {
      _processTransactionForReport(e, personBalances);
    }

    // Remove persons with zero balances in all currencies
    personBalances.removeWhere((person, balances) {
      return balances.values.every((balance) => balance == 0);
    });

    return personBalances;
  }

  void _processTransactionForReport(
    Map<String, dynamic> e,
    Map<String, Map<String, double>> personBalances,
  ) {
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
      if (otherPerson == 'Myself') return;

      // Only calculate for persons in personBalances
      if (!personBalances.containsKey(otherPerson)) return;

      // EXACT SAME LOGIC as calculateFinalBalances
      if (dir == 'give_to') {
        if (p1 == 'Myself') {
          personBalances[otherPerson]![fromCur] =
              (personBalances[otherPerson]![fromCur] ?? 0) + amt;

          if (isCurrEx) {
            personBalances[otherPerson]![toCur] =
                (personBalances[otherPerson]![toCur] ?? 0) - convAmt;
          }
        } else {
          personBalances[otherPerson]![fromCur] =
              (personBalances[otherPerson]![fromCur] ?? 0) - amt;

          if (isCurrEx) {
            personBalances[otherPerson]![toCur] =
                (personBalances[otherPerson]![toCur] ?? 0) + convAmt;
          }
        }
      } else if (dir == 'take_from') {
        if (p1 == 'Myself') {
          personBalances[otherPerson]![fromCur] =
              (personBalances[otherPerson]![fromCur] ?? 0) - amt;

          if (isCurrEx) {
            personBalances[otherPerson]![toCur] =
                (personBalances[otherPerson]![toCur] ?? 0) + convAmt;
          }
        } else {
          personBalances[otherPerson]![fromCur] =
              (personBalances[otherPerson]![fromCur] ?? 0) + amt;

          if (isCurrEx) {
            personBalances[otherPerson]![toCur] =
                (personBalances[otherPerson]![toCur] ?? 0) - convAmt;
          }
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
}
