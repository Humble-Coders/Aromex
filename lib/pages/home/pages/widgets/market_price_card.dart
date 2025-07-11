// Direct Market Price Widget with proper refresh
import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/pages/home/pages/widgets/update_market_price.dart';
import 'package:aromex/services/market_price.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MarketRateBalanceCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final Map<String, double> prices; // USD, INR, AED prices
  final String updatedAt;
  final bool isLoading;

  const MarketRateBalanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.prices,
    required this.updatedAt,
    required this.isLoading,
  });

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondary,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        isLoading
                            ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display all three currencies
                                for (var entry in prices.entries)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '${getCurrencySymbol(entry.key)}${entry.value.toStringAsFixed(2)}',
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'Nunito',
                                        fontVariations: [
                                          const FontVariation('wght', 700),
                                        ],
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                Text(
                                  'Last updated at $updatedAt',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                        const SizedBox(height: 65),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.secondaryContainer.withAlpha(13),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: icon,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketPriceWidget extends StatefulWidget {
  final Map<BalanceType, Balance> balances;
  final bool isLoading;
  final double expenseRecord;
  final String expenseUpdatedAt;

  const MarketPriceWidget({
    super.key,
    required this.balances,
    required this.isLoading,
    required this.expenseRecord,
    required this.expenseUpdatedAt,
  });

  @override
  State<MarketPriceWidget> createState() => _MarketPriceWidgetState();
}

class _MarketPriceWidgetState extends State<MarketPriceWidget> {
  Map<String, double> prices = {'USD': 1.0, 'INR': 83.50, 'AED': 3.67};
  String updatedAt = 'Never';
  bool isMarketLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() {
      isMarketLoading = true;
    });

    try {
      final data = await MarketPriceService.getCurrentMarketPrices();
      if (data != null && mounted) {
        setState(() {
          prices = {
            'USD': data['USD']?.toDouble() ?? 1.0,
            'INR': data['INR']?.toDouble() ?? 83.50,
            'AED': data['AED']?.toDouble() ?? 3.67,
          };

          final timestamp = data['updatedAt'];
          if (timestamp != null) {
            updatedAt = _formatTimestamp(timestamp);
          }
        });
      }
    } catch (e) {
      print('Error loading prices: $e');
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

  @override
  Widget build(BuildContext context) {
    return MarketRateBalanceCard(
      icon: SvgPicture.asset(
        'assets/icons/expense_record.svg',
        width: 40,
        height: 40,
      ),
      title: 'Market Rates',
      prices: prices,
      updatedAt: updatedAt,
      isLoading: isMarketLoading,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.125,
                  vertical: MediaQuery.of(context).size.height * 0.125,
                ),
                child: UpdateMarketPriceCard(
                  title: 'Market Rates',
                  updatedAt: updatedAt,
                  icon: SvgPicture.asset(
                    'assets/icons/expense_record.svg',
                    width: 40,
                    height: 40,
                  ),
                  balance: widget.balances[BalanceType.expenseRecord]!,
                  currentPrices: {
                    Currency.USD: prices['USD']!,
                    Currency.INR: prices['INR']!,
                    Currency.AED: prices['AED']!,
                  },
                ),
              ),
            );
          },
        ).then((result) {
          if (result == true) {
            // Refresh prices after successful update
            _loadPrices();
          }
        });
      },
    );
  }
}

// Usage in your existing code:
// Replace your Expanded widget with:
/*
Expanded(
  child: MarketPriceWidget(
    balances: balances,
    isLoading: isLoading,
    expenseRecord: expenseRecord,
    expenseUpdatedAt: expenseUpdatedAt,
  ),
),
*/
