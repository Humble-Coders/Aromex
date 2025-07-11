// 1. Modified MarketPriceSection to work as a dialog content
import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/pages/home/pages/widgets/update_market_price.dart';
import 'package:aromex/services/market_price.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MarketPriceSection extends StatefulWidget {
  final Map<BalanceType, Balance> balances;
  final bool isLoading;
  final double expenseRecord;
  final String expenseUpdatedAt;

  const MarketPriceSection({
    super.key,
    required this.balances,
    required this.isLoading,
    required this.expenseRecord,
    required this.expenseUpdatedAt,
  });

  @override
  State<MarketPriceSection> createState() => _MarketPriceSectionState();
}

class _MarketPriceSectionState extends State<MarketPriceSection> {
  Map<String, double> currentPrices = {'USD': 1.0, 'INR': 83.50, 'AED': 3.67};
  String marketUpdatedAt = 'Never';
  bool isMarketLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMarketPrices();
  }

  Future<void> _loadMarketPrices() async {
    setState(() {
      isMarketLoading = true;
    });

    try {
      final prices = await MarketPriceService.getCurrentMarketPrices();
      if (prices != null && mounted) {
        setState(() {
          currentPrices = {
            'USD': prices['USD']?.toDouble() ?? 1.0,
            'INR': prices['INR']?.toDouble() ?? 83.50,
            'AED': prices['AED']?.toDouble() ?? 3.67,
          };

          final timestamp = prices['updatedAt'];
          if (timestamp != null) {
            marketUpdatedAt = _formatTimestamp(timestamp);
          }
        });
      }
    } catch (e) {
      print('Error loading market prices: $e');
    } finally {
      if (mounted) {
        setState(() {
          isMarketLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Recently';
    } catch (e) {
      return 'Recently';
    }
  }

  String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'INR':
        return '₹';
      case 'AED':
        return 'د.إ';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary.withAlpha(170), width: 1.0),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            right: -10,
            bottom: -10,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                'assets/images/wave.png',
                fit: BoxFit.fill,
                height: 120,
                width: double.infinity,
              ),
            ),
          ),
          if (isMarketLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Market Rates',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isMarketLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Exchange Rates:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Display all currency rates
                                for (var entry in currentPrices.entries)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${getCurrencySymbol(entry.key)}${entry.value.toStringAsFixed(2)}',
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  'Last updated: $marketUpdatedAt',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSecondary.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.secondaryContainer.withAlpha(13),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/icons/expense_record.svg',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Update button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed:
                          isMarketLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        "Close",
                        style: TextStyle(color: colorScheme.onSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed:
                          isMarketLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.125,
                                          vertical:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.125,
                                        ),
                                        child: UpdateMarketPriceCard(
                                          title: 'Market Rates',
                                          updatedAt: marketUpdatedAt,
                                          icon: SvgPicture.asset(
                                            'assets/icons/expense_record.svg',
                                            width: 40,
                                            height: 40,
                                          ),
                                          balance:
                                              widget.balances[BalanceType
                                                  .expenseRecord]!,
                                          currentPrices: {
                                            Currency.USD: currentPrices['USD']!,
                                            Currency.INR: currentPrices['INR']!,
                                            Currency.AED: currentPrices['AED']!,
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ).then((result) {
                                  if (result == true) {
                                    _loadMarketPrices();
                                  }
                                });
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        backgroundColor: colorScheme.primary,
                      ),
                      child: Text(
                        "Update Rates",
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
