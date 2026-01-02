// lib/utils/formatters.dart
import 'package:intl/intl.dart';

String formatIndianCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  return formatter.format(amount / 100); // Convert paise to rupees
}