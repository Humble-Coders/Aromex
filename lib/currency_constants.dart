class CurrencyConstants {
  static const List<String> currencies = ['INR', 'USD', 'AED'];

  static const Map<String, Map<String, double>> exchangeRates = {
    'INR': {'USD': 0.012, 'AED': 0.044},
    'USD': {'INR': 83.0, 'AED': 3.67},
    'AED': {'INR': 22.6, 'USD': 0.27},
  };
}
