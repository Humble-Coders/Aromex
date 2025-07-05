import 'package:cloud_firestore/cloud_firestore.dart';

class MarketPriceService {
  // Global variable to store market rates
  static Map<String, double> marketRates = {};

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

  // Load market rates from database
  static Future<void> loadMarketRates() async {
    try {
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
      }

      // Calculate all currency pairs and store in global variable
      marketRates = {
        'INR_USD': usd / inr, // How many USD for 1 INR
        'USD_INR': inr / usd, // How many INR for 1 USD
        'INR_AED': aed / inr, // How many AED for 1 INR
        'AED_INR': inr / aed, // How many INR for 1 AED
        'USD_AED': aed / usd, // How many AED for 1 USD
        'AED_USD': usd / aed, // How many USD for 1 AED
      };

      print(marketRates);
      // Output: {'INR_USD': 0.012, 'USD_INR': 83.0, 'INR_AED': 0.044, 'AED_INR': 22.6, 'USD_AED': 3.67, 'AED_USD': 0.27}
    } catch (e) {
      print('Error getting market rates: $e');
      // Set default rates on error
      marketRates = {
        'INR_USD': 0.012,
        'USD_INR': 83.0,
        'INR_AED': 0.044,
        'AED_INR': 22.6,
        'USD_AED': 3.67,
        'AED_USD': 0.27,
      };
    }
  }

  // Get specific market rate
  static double? getMarketRate(String fromCurrency, String toCurrency) {
    final key = '${fromCurrency.toUpperCase()}_${toCurrency.toUpperCase()}';
    return marketRates[key];
  }
}
