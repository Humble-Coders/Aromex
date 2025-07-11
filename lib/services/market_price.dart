import 'package:cloud_firestore/cloud_firestore.dart';

class MarketPriceService {
  // Global variable to store market rates
  static Map<String, double> marketRates = {};
  static bool _isInitialized = false;

  // Your existing functions...
  static Future<void> updateMarketPrices({
    required double usdPrice,
    required double inrPrice,
    required double aedPrice,
    String? note,
  }) async {
    final marketPriceDoc = FirebaseFirestore.instance
        .collection('market_prices')
        .doc('latest');

    await marketPriceDoc.set({
      'USD': usdPrice,
      'INR': inrPrice,
      'AED': aedPrice,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Reload market rates after updating
    await loadMarketRates();
  }

  static Future<Map<String, dynamic>?> getCurrentMarketPrices() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('market_prices')
              .doc('latest')
              .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting market prices: $e');
      return null;
    }
  }

  // Load market rates from database with better error handling
  static Future<bool> loadMarketRates() async {
    try {
      print('🟡 Loading market rates from database...');
      final doc =
          await FirebaseFirestore.instance
              .collection('market_prices')
              .doc('latest')
              .get();

      // Default values if no data
      double usd = 1.0;
      double inr = 83.0;
      double aed = 3.67;

      if (doc.exists) {
        final data = doc.data()!;
        usd = data['USD']?.toDouble() ?? 1.0;
        inr = data['INR']?.toDouble() ?? 83.0;
        aed = data['AED']?.toDouble() ?? 3.67;

        print('🟡 Raw data from database:');
        print('🟡 USD: $usd, INR: $inr, AED: $aed');
      } else {
        print('🟡 No market prices document found, using defaults');
      }

      // Calculate and store market rates
      _calculateMarketRates(usd, inr, aed);

      print('🟢 Market rates loaded successfully');
      return true;
    } catch (e) {
      print('🔴 Error getting market rates: $e');
      // Set default rates on error
      _setDefaultMarketRates();
      print('🔴 Using default market rates due to error');
      return false;
    }
  }

  // Separate method to calculate market rates
  static void _calculateMarketRates(double usd, double inr, double aed) {
    // Clear existing rates
    marketRates.clear();

    // CORRECT CALCULATION: These are exchange rates relative to USD
    marketRates = {
      // USD to other currencies
      'USD_INR': inr / usd, // 1 USD = X INR
      'USD_AED': aed / usd, // 1 USD = X AED
      // Other currencies to USD
      'INR_USD': usd / inr, // 1 INR = X USD
      'AED_USD': usd / aed, // 1 AED = X USD
      // Cross rates (INR to AED and vice versa)
      'INR_AED': aed / inr, // 1 INR = X AED
      'AED_INR': inr / aed, // 1 AED = X INR
    };

    print('🟡 Calculated market rates:');
    marketRates.forEach((key, value) {
      print('🟡 $key: $value');
    });
    print('🟡 Total rates loaded: ${marketRates.length}');
  }

  // Set default market rates
  static void _setDefaultMarketRates() {
    marketRates = {
      'USD_INR': 83.0, // 1 USD = 83 INR
      'INR_USD': 0.012, // 1 INR = 0.012 USD
      'USD_AED': 3.67, // 1 USD = 3.67 AED
      'AED_USD': 0.27, // 1 AED = 0.27 USD
      'INR_AED': 0.044, // 1 INR = 0.044 AED
      'AED_INR': 22.6, // 1 AED = 22.6 INR
    };
  }

  // Get specific market rate with auto-initialization
  static Future<double?> getMarketRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    // Auto-initialize if not done yet
    if (!_isInitialized || marketRates.isEmpty) {
      print('🟡 Auto-initializing market rates...');
      await initialize();
    }

    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    final rate = marketRates[key];

    print('🟡 Getting market rate for $fromCurrency → $toCurrency');
    print('🟡 Key: $key, Rate: $rate');
    print('🟡 Available rates: ${marketRates.keys.toList()}');

    if (rate == null) {
      print('🔴 Market rate not found for $key');
    }

    return rate;
  }

  // Synchronous version for when you're sure rates are loaded
  static double? getMarketRateSync(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    loadMarketRates();
    final rate = marketRates[key];

    print('🟡 Getting market rate (sync) for $fromCurrency → $toCurrency');
    print('🟡 Key: $key, Rate: $rate');

    if (rate == null) {
      print('🔴 Market rate not found for $key');
      print('🔴 Available rates: ${marketRates.keys.toList()}');
    }

    return rate;
  }

  // Initialize market rates when app starts
  static Future<bool> initialize() async {
    print('🟡 Initializing MarketPriceService...');
    final success = await loadMarketRates();
    _isInitialized = true;

    if (success) {
      print('🟢 MarketPriceService initialized successfully');
    } else {
      print('🟡 MarketPriceService initialized with default rates');
    }

    return success;
  }

  // Helper method to validate rates
  static bool validateRates() {
    final isValid =
        marketRates.isNotEmpty && marketRates.values.every((rate) => rate > 0);

    print('🟡 Validating rates: $isValid');
    print('🟡 Rates count: ${marketRates.length}');

    return isValid;
  }

  // Check if service is initialized
  static bool get isInitialized => _isInitialized && marketRates.isNotEmpty;

  // Force reload rates
  static Future<bool> reloadRates() async {
    print('🟡 Force reloading market rates...');
    marketRates.clear();
    return await loadMarketRates();
  }

  // Get all available currency pairs
  static List<String> getAvailablePairs() {
    return marketRates.keys.toList();
  }
}
