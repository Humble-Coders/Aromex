import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/balance_calculator_service.dart';

class BalanceReportTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> allEntries;
  final List<Map<String, String>> allPeople;
  final BalanceCalculatorService balanceCalculator;
  final Function(String)? onPersonTap; // Optional callback for person tap

  const BalanceReportTabWidget({
    super.key,
    required this.allEntries,
    required this.allPeople,
    required this.balanceCalculator,
    this.onPersonTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use FutureBuilder to handle the asynchronous balance calculation
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: balanceCalculator.calculateBalanceReport(allEntries),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final personBalances = snapshot.data ?? {};

        if (personBalances.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme),
              const SizedBox(height: 24),
              _buildBalanceTable(colorScheme, personBalances),
              const SizedBox(height: 20),
              _buildExportButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.assessment, color: colorScheme.primary, size: 24),
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
              'Net balance with Myself • Tap on person to view details',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceTable(
    ColorScheme colorScheme,
    Map<String, Map<String, double>> personBalances,
  ) {
    return Container(
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
          _buildTableHeader(colorScheme),
          ...personBalances.entries.map((entry) {
            return _buildTableRow(entry.key, entry.value);
          }).toList(),
          _buildSummaryRow(colorScheme, personBalances),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
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
    );
  }

  Widget _buildTableRow(String personName, Map<String, double> balances) {
    // Find the primary currency with non-zero balance
    String? primaryCurrency;
    double primaryBalance = 0;

    // Priority order: check currencies in order of importance
    final currencyOrder = ['USD', 'INR', 'AED'];

    for (String currency in currencyOrder) {
      final balance = balances[currency] ?? 0;
      if (balance.abs() > 0.01) {
        // Using 0.01 to handle floating point precision
        primaryCurrency = currency;
        primaryBalance = balance;
        break; // Take the first non-zero balance
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handlePersonTap(personName, balances),
        borderRadius: BorderRadius.circular(0),
        hoverColor: Colors.grey.shade50,
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
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
                          color: _getPersonColor(personName).withOpacity(0.2),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    personName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ],
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
              ...['INR', 'USD', 'AED'].map((currency) {
                // Show balance only in the cell of the primary currency
                if (primaryCurrency == currency &&
                    primaryBalance.abs() > 0.01) {
                  final isPositive = primaryBalance > 0;
                  final isNegative = primaryBalance < 0;

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
                          right: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            NumberFormat(
                              '#,##0.00',
                            ).format(primaryBalance.abs()),
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
                } else {
                  // Show "Settled" with 0.00 for other currencies
                  return Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '0.00',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Settled',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    ColorScheme colorScheme,
    Map<String, Map<String, double>> personBalances,
  ) {
    // Calculate totals for each currency
    Map<String, double> totals = {'INR': 0, 'USD': 0, 'AED': 0};

    for (var personBalance in personBalances.values) {
      for (var currency in totals.keys) {
        totals[currency] =
            (totals[currency] ?? 0) + (personBalance[currency] ?? 0);
      }
    }

    return Container(
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
            final total = totals[currency] ?? 0;
            final hasBalance = total.abs() > 0.01;

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
                        hasBalance
                            ? (total > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700)
                            : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Implement export functionality
        },
        icon: const Icon(Icons.download),
        label: const Text('Export to Excel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Handle person tap - you can customize this based on your needs
  void _handlePersonTap(String personName, Map<String, double> balances) {
    // Option 1: Use provided callback
    if (onPersonTap != null) {
      onPersonTap!(personName);
      return;
    }

    // Option 2: Show a bottom sheet with person details
    _showPersonDetailsBottomSheet(personName, balances);
  }

  void _showPersonDetailsBottomSheet(
    String personName,
    Map<String, double> balances,
  ) {
    // This method would show a bottom sheet with person details
    // You can implement this based on your app's design
    print('Person tapped: $personName');
    print('Balances: $balances');

    // Example implementation:
    /*
    showModalBottomSheet(
      context: context,
      builder: (context) => PersonDetailsBottomSheet(
        personName: personName,
        balances: balances,
        allEntries: allEntries,
      ),
    );
    */
  }

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

  String _getPersonType(String personName) {
    final person = allPeople.firstWhere(
      (p) => p['name'] == personName,
      orElse: () => {'type': 'Person'},
    );
    return person['type'] ?? 'Person';
  }
}
