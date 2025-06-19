import 'package:intl/intl.dart';

bool validateEmail(String email) {
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}

bool validatePhone(String phone) {
  final RegExp phoneRegex = RegExp(r'^\d{10}$');
  return phoneRegex.hasMatch(phone);
}

bool validateName(String name) {
  return name.isNotEmpty;
}

final currencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: "\$ ",
  decimalDigits: 2,
);

String formatCurrency(
  double amount, {
  int decimals = 2,
  bool showTrail = false,
}) {
  return "${currencyFormat.format(amount).replaceAll('.00', '').replaceAll('.0', '')}${showTrail ? '/-' : ''}";
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}