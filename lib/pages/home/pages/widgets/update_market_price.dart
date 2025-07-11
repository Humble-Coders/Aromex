// Updated UpdateMarketPriceCard with normalized prices (USD = 1 base)
import 'package:aromex/models/balance_generic.dart';
import 'package:aromex/services/market_price.dart';
import 'package:aromex/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

enum Currency { USD, INR, AED }

class UpdateMarketPriceCard extends StatefulWidget {
  const UpdateMarketPriceCard({
    super.key,
    required this.title,
    required this.currentPrices,
    required this.updatedAt,
    required this.icon,
    required this.balance,
  });

  final String title;
  final Map<Currency, double> currentPrices;
  final String updatedAt;
  final Widget icon;
  final Balance balance;

  @override
  State<UpdateMarketPriceCard> createState() => _UpdateMarketPriceCardState();
}

class _UpdateMarketPriceCardState extends State<UpdateMarketPriceCard> {
  late final Map<Currency, TextEditingController> priceControllers;
  late final TextEditingController notesController;

  Map<Currency, String?> priceErrors = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current prices
    // Ensure USD is always 1.00 for easy comparison
    final normalizedPrices = _normalizePrices(widget.currentPrices);

    priceControllers = {
      for (var currency in Currency.values)
        currency: TextEditingController(
          text:
              normalizedPrices[currency]?.toStringAsFixed(2) ??
              (currency == Currency.USD ? '1.00' : '0.00'),
        ),
    };

    notesController = TextEditingController(text: widget.balance.note ?? '');
  }

  // Normalize prices so USD = 1.00
  Map<Currency, double> _normalizePrices(Map<Currency, double> prices) {
    final usdRate = prices[Currency.USD] ?? 1.0;

    if (usdRate == 0) return prices; // Avoid division by zero

    return {
      Currency.USD: 1.0, // Always set USD to 1
      Currency.INR: (prices[Currency.INR] ?? 83.50) / usdRate,
      Currency.AED: (prices[Currency.AED] ?? 3.67) / usdRate,
    };
  }

  // Convert normalized prices back to actual rates
  Map<Currency, double> _denormalizePrices(
    Map<Currency, double> normalizedPrices,
  ) {
    // If user changes USD from 1, use it as the new base
    final usdBase = normalizedPrices[Currency.USD] ?? 1.0;

    return {
      Currency.USD: usdBase,
      Currency.INR: (normalizedPrices[Currency.INR] ?? 83.50) * usdBase,
      Currency.AED: (normalizedPrices[Currency.AED] ?? 3.67) * usdBase,
    };
  }

  @override
  void dispose() {
    for (var controller in priceControllers.values) {
      controller.dispose();
    }
    notesController.dispose();
    super.dispose();
  }

  String getCurrencySymbol(Currency currency) {
    switch (currency) {
      case Currency.USD:
        return '\$';
      case Currency.INR:
        return '₹';
      case Currency.AED:
        return 'د.إ';
    }
  }

  String getCurrencyName(Currency currency) {
    switch (currency) {
      case Currency.USD:
        return 'US Dollar (Base)';
      case Currency.INR:
        return 'Indian Rupee';
      case Currency.AED:
        return 'UAE Dirham';
    }
  }

  String getCurrencyHint(Currency currency) {
    switch (currency) {
      case Currency.USD:
        return '1 USD = ? USD (typically 1.00)';
      case Currency.INR:
        return '1 USD = ? INR (e.g., 83.50)';
      case Currency.AED:
        return '1 USD = ? AED (e.g., 3.67)';
    }
  }

  bool validate() {
    bool isValid = true;
    Map<Currency, String?> errors = {};

    for (var currency in Currency.values) {
      final text = priceControllers[currency]!.text.trim();
      if (text.isEmpty) {
        errors[currency] = "This field is required";
        isValid = false;
      } else {
        final parsedValue = double.tryParse(text);
        if (parsedValue == null || parsedValue <= 0) {
          errors[currency] = "Please enter a valid positive amount";
          isValid = false;
        }
      }
    }

    setState(() {
      priceErrors = errors;
    });

    return isValid;
  }

  Future<void> _updatePrices() async {
    if (!validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Parse normalized values from controllers
      Map<Currency, double> normalizedPrices = {};
      for (var currency in Currency.values) {
        final priceText = priceControllers[currency]!.text.trim();
        final parsedPrice = double.parse(priceText);
        normalizedPrices[currency] = parsedPrice;
      }

      // Convert back to actual exchange rates
      final actualPrices = _denormalizePrices(normalizedPrices);

      final note =
          notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim();

      // Update market prices with actual rates
      await MarketPriceService.updateMarketPrices(
        usdPrice: actualPrices[Currency.USD]!,
        inrPrice: actualPrices[Currency.INR]!,
        aedPrice: actualPrices[Currency.AED]!,
        note: note,
      );

      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Market prices updated successfully!"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update market prices: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
          if (isLoading)
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
                            'Update Exchange Rates',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Exchange Rates:',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Show normalized current prices (USD = 1 base)
                              for (var currency in Currency.values)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '1 USD = ${getCurrencySymbol(currency)}${_normalizePrices(widget.currentPrices)[currency]?.toStringAsFixed(2) ?? '0.00'}',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Last updated at ${widget.updatedAt}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondary,
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
                      child: widget.icon,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter rates based on 1 USD. Example: If 1 USD = 83.50 INR, enter 83.50 for INR.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Price input fields
                Text(
                  'Enter New Exchange Rates',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                for (var currency in Currency.values) ...[
                  CustomTextField(
                    title: getCurrencyName(currency),
                    textController: priceControllers[currency]!,
                    description: getCurrencyHint(currency),
                    isMandatory: true,
                    error: priceErrors[currency],
                    onChanged: (value) {
                      setState(() {
                        priceErrors[currency] = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                CustomTextField(
                  title: "Notes",
                  textController: notesController,
                  description: "Enter any notes about the rate update",
                  isMandatory: false,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed:
                          isLoading
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
                        "Cancel",
                        style: TextStyle(color: colorScheme.onSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _updatePrices,
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
