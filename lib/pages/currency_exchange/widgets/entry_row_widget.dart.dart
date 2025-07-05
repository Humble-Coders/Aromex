import 'package:aromex/pages/currency_exchange/perosndetailscreen.dart';
import 'package:aromex/pages/currency_exchange/widgets/delete_confirmation_dialog.dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/balance_calculator_service.dart';
import '../../../services/market_price.dart';

class EntryRowWidget extends StatelessWidget {
  final Map<String, dynamic> entry;
  final List<Map<String, String>> allPeople;
  final List<Map<String, dynamic>> allEntries; // ADD THIS
  final Function(String) onDelete;
  final BalanceCalculatorService balanceCalculator;

  const EntryRowWidget({
    super.key,
    required this.entry,
    required this.allPeople,
    required this.allEntries, // ADD THIS
    required this.onDelete,
    required this.balanceCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildTabularEntryRow(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Error loading entry row')),
          );
        }
        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  Future<Widget> _buildTabularEntryRow(BuildContext context) async {
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

    // Calculate expected profit
    double expectedProfit = 0;
    String expectedProfitText = '';
    double marketRate = 0;
    double yourRate = 0;

    if (isCurrencyEntry && exchangeRate > 0) {
      marketRate = getMarketRate(fromCurrency, toCurrency) ?? 0;
      yourRate = exchangeRate.toDouble();

      if (marketRate > 0) {
        double rateDifference = yourRate - marketRate;
        expectedProfit = amount.toDouble() * rateDifference;

        if (expectedProfit.abs() > 0.01) {
          expectedProfitText =
              '${expectedProfit > 0 ? '+' : ''}${NumberFormat('#,##0.00').format(expectedProfit)}';
        }
      }
    }

    // Calculate final balance including commission - FIXED: Pass allEntries
    Map<String, Map<String, double>> finalBalances = await balanceCalculator
        .calculateFinalBalances(entry, allEntries); // FIXED HERE

    // Determine what I gave and got
    double gave = 0;
    double got = 0;
    String gaveCurrency = '';
    String gotCurrency = '';

    if (person1 == 'Myself') {
      if (direction == 'give_to') {
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
        if (isCurrencyEntry) {
          got = convertedAmount.toDouble();
          gotCurrency = toCurrency;
        }
      } else {
        got = amount.toDouble();
        gotCurrency = fromCurrency;
        if (isCurrencyEntry) {
          gave = convertedAmount.toDouble();
          gaveCurrency = toCurrency;
        }
      }
    } else if (person2 == 'Myself') {
      if (direction == 'give_to') {
        got = amount.toDouble();
        gotCurrency = fromCurrency;
      } else {
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
      }
    } else {
      if (direction == 'give_to') {
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
        if (isCurrencyEntry) {
          got = convertedAmount.toDouble();
          gotCurrency = toCurrency;
        }
      } else {
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
          if (isCurrencyEntry)
            _buildCurrencyExchangeHeader(fromCurrency, toCurrency),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDateTimeColumn(timestamp),
                    _buildPersonsColumn(context, person1, person2, direction),
                    const SizedBox(width: 10),
                    _buildGaveColumn(gave, gaveCurrency),
                    const SizedBox(width: 8),
                    _buildGotColumn(got, gotCurrency),
                    const SizedBox(width: 8),
                    if (isCurrencyEntry) ...[
                      _buildExchangeRateColumn(
                        fromCurrency,
                        toCurrency,
                        exchangeRate,
                        marketRate,
                      ),
                      const SizedBox(width: 8),
                      _buildExpectedProfitColumn(
                        expectedProfit,
                        expectedProfitText,
                        toCurrency,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (commission > 0 && commissionPerson != null) ...[
                      _buildCommissionColumn(commission, commissionPerson),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: 2,
                      child: _buildPersonBalancesColumn(
                        person1,
                        person2,
                        finalBalances,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildDeleteButton(context),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildNotesSection(notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyExchangeHeader(String fromCurrency, String toCurrency) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }

  Widget _buildDateTimeColumn(DateTime timestamp) {
    return SizedBox(
      width: 65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM').format(timestamp),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            DateFormat('HH:mm').format(timestamp),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonsColumn(
    BuildContext context,
    String person1,
    String person2,
    String direction,
  ) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToPersonDetails(context, person1),
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
            direction == 'give_to' ? Icons.arrow_forward : Icons.arrow_back,
            color: direction == 'give_to' ? Colors.green : Colors.red,
            size: 16,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToPersonDetails(context, person2),
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
    );
  }

  Widget _buildGaveColumn(double gave, String gaveCurrency) {
    return _buildAmountColumn(
      'GAVE',
      gave,
      gaveCurrency,
      gave > 0 ? Colors.red : Colors.grey,
    );
  }

  Widget _buildGotColumn(double got, String gotCurrency) {
    return _buildAmountColumn(
      'GOT',
      got,
      gotCurrency,
      got > 0 ? Colors.green : Colors.grey,
    );
  }

  Widget _buildAmountColumn(
    String label,
    double amount,
    String currency,
    Color color,
  ) {
    return SizedBox(
      width: 85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: amount > 0 ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: amount > 0 ? color.withOpacity(0.3) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: amount > 0 ? color : Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount > 0 ? NumberFormat('#,##0').format(amount) : '0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: amount > 0 ? color : Colors.grey.shade600,
              ),
            ),
            Text(
              currency.isNotEmpty ? currency : '-',
              style: TextStyle(
                fontSize: 9,
                color:
                    amount > 0 ? color.withOpacity(0.8) : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateColumn(
    String fromCurrency,
    String toCurrency,
    num exchangeRate,
    double marketRate,
  ) {
    return SizedBox(
      width: 100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200, width: 1),
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
              style: TextStyle(fontSize: 8, color: Colors.blue.shade600),
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
                style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedProfitColumn(
    double expectedProfit,
    String expectedProfitText,
    String currency,
  ) {
    return SizedBox(
      width: 100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
              expectedProfitText.isNotEmpty ? expectedProfitText : '0.00',
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
              currency.isNotEmpty ? currency : '-',
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
    );
  }

  Widget _buildCommissionColumn(num commission, String commissionPerson) {
    return SizedBox(
      width: 85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200, width: 1),
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
              style: TextStyle(fontSize: 8, color: Colors.orange.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonBalancesColumn(
    String person1,
    String person2,
    Map<String, Map<String, double>> finalBalances,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSON BALANCES (USD)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ...finalBalances.entries
              .where((e) => e.key == person1 || e.key == person2)
              .take(3)
              .map((e) {
                final person = e.key;
                final balances = e.value;
                final usdBalance = balances['USD'] ?? 0;

                String displayName =
                    person.length > 12
                        ? '${person.substring(0, 12)}...'
                        : person;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPersonIcon(person),
                        size: 14,
                        color: _getPersonColor(person),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getPersonColor(person),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                usdBalance > 0
                                    ? Colors.green.withOpacity(0.15)
                                    : usdBalance < 0
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
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
                              fontSize: 9,
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
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: 30,
      child: IconButton(
        onPressed: () => _showDeleteConfirmation(context),
        icon: Icon(Icons.close, color: Colors.red.shade400, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPersonDetails(BuildContext context, String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personName: personName),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) =>
              DeleteConfirmationDialog(onConfirm: () => onDelete(entry['id'])),
    );
  }

  double? getMarketRate(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    return MarketPriceService.marketRates[key];
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
}
