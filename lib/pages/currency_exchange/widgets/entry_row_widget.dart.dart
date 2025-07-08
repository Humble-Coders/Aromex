import 'package:aromex/pages/currency_exchange/perosndetailscreen.dart';
import 'package:aromex/pages/currency_exchange/widgets/delete_confirmation_dialog.dart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/balance_calculator_service.dart';
import '../../../services/market_price.dart';

class EntryRowWidget extends StatefulWidget {
  final Map<String, dynamic> entry;
  final List<Map<String, String>> allPeople;
  final List<Map<String, dynamic>> allEntries;
  final Function(String) onDelete;
  final BalanceCalculatorService balanceCalculator;
  final Map<String, Map<String, double>>? preCalculatedBalances; // Add this

  const EntryRowWidget({
    super.key,
    required this.entry,
    required this.allPeople,
    required this.allEntries,
    required this.onDelete,
    required this.balanceCalculator,
    this.preCalculatedBalances, // Add this
  });

  @override
  State<EntryRowWidget> createState() => _EntryRowWidgetState();
}

class _EntryRowWidgetState extends State<EntryRowWidget> {
  Map<String, Map<String, double>>? _cachedBalances;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // Use pre-calculated balances if available, otherwise calculate
    if (widget.preCalculatedBalances != null) {
      _cachedBalances = widget.preCalculatedBalances;
    } else {
      _calculateBalances();
    }
  }

  @override
  void didUpdateWidget(EntryRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Use pre-calculated balances if available
    if (widget.preCalculatedBalances != null) {
      _cachedBalances = widget.preCalculatedBalances;
      return;
    }

    // Only recalculate if the entry or entries list has changed
    if (oldWidget.entry['id'] != widget.entry['id'] ||
        oldWidget.allEntries.length != widget.allEntries.length) {
      _cachedBalances = null;
      _calculateBalances();
    }
  }

  Future<void> _calculateBalances() async {
    if (_isCalculating || _cachedBalances != null) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final balances = await widget.balanceCalculator.calculateFinalBalances(
        widget.entry,
        widget.allEntries,
      );

      if (mounted) {
        setState(() {
          _cachedBalances = balances;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
      print('🔴 Error calculating balances: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildTableRow(context);
  }

  Widget _buildTableRow(BuildContext context) {
    final entry = widget.entry;
    final allEntries = widget.allEntries;
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

    // Calculate expected profit
    double expectedProfit = calculateExpectedProfit(entry);

    // Determine what I gave and got
    double gave = 0;
    double got = 0;
    String gaveCurrency = '';
    String gotCurrency = '';

    if (person1 == 'Myself') {
      if (direction == 'give_to') {
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
      } else {
        got = amount.toDouble();
        gotCurrency = fromCurrency;
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
      // For third-party transactions, show what was exchanged
      if (direction == 'give_to') {
        gave = amount.toDouble();
        gaveCurrency = fromCurrency;
      } else {
        got = amount.toDouble();
        gotCurrency = fromCurrency;
      }
    }

    // Show header only for first entry or when date changes
    bool showHeader =
        entry == allEntries.first || _isDifferentDate(entry, allEntries);

    return Column(
      children: [
        // Header row
        if (showHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                // DATE & TIME
                const SizedBox(
                  width:
                      136, // Increased to match data row (120 + 16 for padding)
                  child: Text(
                    'DATE & TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // ACCOUNT FLOW
                const SizedBox(
                  width:
                      220, // Increased to match data row (200 + 17 for divider)
                  child: Text(
                    'ACCOUNT FLOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // CONVERSION
                const SizedBox(
                  width:
                      200, // Increased to match data row (120 + 17 for divider)
                  child: Text(
                    'CONVERSION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // TRANSACTION DETAILS
                const SizedBox(
                  width:
                      217, // Increased to match data row (200 + 17 for divider)
                  child: Text(
                    'TRANSACTION DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // METRICS
                const SizedBox(
                  width:
                      137, // Increased to match data row (120 + 17 for divider)
                  child: Text(
                    'METRICS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // ACCOUNT BALANCES
                const Expanded(
                  child: Text(
                    'ACCOUNT BALANCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Delete button space
                const SizedBox(
                  width: 57,
                ), // Increased to match data row (40 + 17 for divider)
              ],
            ),
          ),

        // Data row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATE & TIME (with notes below if exists)
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(timestamp),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      // Notes below date & time if exists
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // ACCOUNT FLOW
                SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      Flexible(
                        child:
                            person1 == 'Myself'
                                ? _buildPersonBadge(person1)
                                : InkWell(
                                  onTap:
                                      () => _navigateToPersonDetails(
                                        context,
                                        person1,
                                      ),
                                  child: _buildPersonBadge(person1),
                                ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF6B7280),
                          size: 16,
                        ),
                      ),
                      Flexible(
                        child:
                            person2 == 'Myself'
                                ? _buildPersonBadge(person2)
                                : InkWell(
                                  onTap:
                                      () => _navigateToPersonDetails(
                                        context,
                                        person2,
                                      ),
                                  child: _buildPersonBadge(person2),
                                ),
                      ),
                    ],
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // CONVERSION
                SizedBox(
                  width: 120,
                  child:
                      isCurrencyEntry
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$fromCurrency → $toCurrency',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rate: ${exchangeRate.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // TRANSACTION DETAILS (with vertical divider)
                SizedBox(
                  width: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // GAVE section
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GAVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    gave > 0
                                        ? '${_getCurrencySymbol(gaveCurrency)}${NumberFormat('#,##0.00').format(gave)}'
                                        : '-',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          gave > 0
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Vertical divider
                          Container(width: 1, color: Colors.grey.shade200),
                          // GOT section
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'GOT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    got > 0
                                        ? '${_getCurrencySymbol(gotCurrency)}${NumberFormat('#,##0.00').format(got)}'
                                        : '-',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          got > 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // METRICS
                // Replace the METRICS section in your _buildTableRow method with this:

                // METRICS
                SizedBox(
                  width: 120,
                  child:
                      isCurrencyEntry
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // RATE
                              const Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                exchangeRate.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // PROFIT
                              const Text(
                                'PROFIT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getCurrencySymbol(toCurrency)}${expectedProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      expectedProfit > 0
                                          ? const Color(0xFF10B981)
                                          : expectedProfit < 0
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // ACCOUNT BALANCES
                Expanded(
                  child:
                      _isCalculating
                          ? const Center(
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : _cachedBalances != null
                          ? _buildBalanceSection(isCurrencyEntry)
                          : const SizedBox(),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.grey.shade200,
                ),

                // Delete Button
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(bool isCurrencyEntry) {
    final entry = widget.entry;
    final person1 = entry['person1'];
    final person2 = entry['person2'];

    // Get all unique people from the balances
    final peopleWithBalances =
        _cachedBalances!.entries
            .where((e) => e.key == person1 || e.key == person2)
            .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          peopleWithBalances.map((e) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildPersonBalance(e.key, e.value, isCurrencyEntry),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPersonBadge(String person) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            person == 'Myself'
                ? const Color(0xFF3B82F6)
                : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        person,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: person == 'Myself' ? Colors.white : const Color(0xFF1F2937),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPersonBalance(
    String person,
    Map<String, double> balances,
    bool isCurrencyEntry,
  ) {
    return InkWell(
      onTap: () => _navigateToPersonDetails(context, person),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Always show all three currencies with proper alignment
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceItem('USD', balances['USD'] ?? 0, isCurrencyEntry),
              const SizedBox(height: 4),
              _buildBalanceItem('INR', balances['INR'] ?? 0, isCurrencyEntry),
              const SizedBox(height: 4),
              _buildBalanceItem('AED', balances['AED'] ?? 0, isCurrencyEntry),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String currency,
    double balance,
    bool isCurrencyEntry,
  ) {
    // For non-currency entries, only show USD balance, others as hyphens
    bool showBalance = isCurrencyEntry || currency == 'USD';

    if (!showBalance) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 35,
            child: Text(
              currency,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Flexible(
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      );
    }

    final isPositive = balance > 0;
    final isNegative = balance < 0;
    final color =
        isPositive
            ? const Color(0xFF10B981)
            : isNegative
            ? const Color(0xFFEF4444)
            : const Color(0xFF6B7280);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 35,
          child: Text(
            currency,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            '${_getCurrencySymbol(currency)}${NumberFormat('#,##0.00').format(balance.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'AED':
        return 'AED ';
      default:
        return '';
    }
  }

  bool _isDifferentDate(
    Map<String, dynamic> currentEntry,
    List<Map<String, dynamic>> allEntries,
  ) {
    final currentIndex = allEntries.indexOf(currentEntry);
    if (currentIndex == 0) return true;

    final previousEntry = allEntries[currentIndex - 1];
    final currentDate = (currentEntry['timestamp'] as DateTime);
    final previousDate = (previousEntry['timestamp'] as DateTime);

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
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
          (context) => DeleteConfirmationDialog(
            onConfirm: () => widget.onDelete(widget.entry['id']),
          ),
    );
  }

  double calculateExpectedProfit(Map entry) {
    final isCurrencyEntry = entry['isCurrencyExchange'] ?? false;
    if (!isCurrencyEntry) return 0;

    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final convertedAmount = (entry['convertedAmount'] as num?)?.toDouble() ?? 0;
    final fromCurrency = entry['fromCurrency'] ?? '';
    final toCurrency = entry['toCurrency'] ?? '';
    final exchangeRate = (entry['exchangeRate'] as num?)?.toDouble() ?? 0;
    final direction = entry['direction'] ?? 'give_to';
    final person1 = entry['person1'] ?? '';
    final person2 = entry['person2'] ?? '';

    if (exchangeRate <= 0) return 0;

    double? marketRate = MarketPriceService.getMarketRateSync(
      fromCurrency,
      toCurrency,
    );

    if (marketRate == null || marketRate <= 0) {
      double? reverseMarketRate = MarketPriceService.getMarketRateSync(
        toCurrency,
        fromCurrency,
      );
      if (reverseMarketRate != null && reverseMarketRate > 0) {
        marketRate = 1 / reverseMarketRate;
      } else {
        return 0;
      }
    }

    // Calculate amounts in 'to' currency
    double marketEquivalentInToCurrency = amount * marketRate;
    double actualAmountInToCurrency =
        convertedAmount > 0 ? convertedAmount : (amount * exchangeRate);

    double expectedProfit = 0;

    if (person1 == 'Myself' || person2 == 'Myself') {
      if (person1 == 'Myself' && direction == 'give_to') {
        // I'm giving fromCurrency, receiving toCurrency
        // Profit = what I actually got - what I should have got at market rate
        expectedProfit =
            actualAmountInToCurrency - marketEquivalentInToCurrency;
      } else if (person1 == 'Myself' && direction == 'take_from') {
        // I'm taking fromCurrency, giving toCurrency
        // Profit = what I should have given at market rate - what I actually gave
        expectedProfit =
            marketEquivalentInToCurrency - actualAmountInToCurrency;
      } else if (person2 == 'Myself' && direction == 'give_to') {
        // Other person is giving to me, so I'm receiving fromCurrency
        // This means I'm effectively giving toCurrency equivalent
        // Profit = what I should have given - what I actually gave
        expectedProfit =
            marketEquivalentInToCurrency - actualAmountInToCurrency;
      } else if (person2 == 'Myself' && direction == 'take_from') {
        // Other person is taking from me, so I'm giving fromCurrency
        // This means I'm effectively receiving toCurrency equivalent
        // Profit = what I actually got - what I should have got
        expectedProfit =
            actualAmountInToCurrency - marketEquivalentInToCurrency;
      }
    } else {
      // Neither person is 'Myself' - general calculation
      expectedProfit = actualAmountInToCurrency - marketEquivalentInToCurrency;
    }

    return expectedProfit;
  }

  Color _getPersonColor(String personName) {
    if (personName == 'Myself') return const Color(0xFF1D4ED8);

    final colors = [
      const Color(0xFF7C3AED),
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.pink.shade700,
      Colors.indigo.shade700,
    ];
    return colors[personName.hashCode % colors.length];
  }
}
