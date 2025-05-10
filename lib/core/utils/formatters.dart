import 'package:intl/intl.dart';

/// Utility class for formatting values (currency, numbers, etc.) consistently across the app
class Formatters {
  /// Format a double value as currency (e.g., $123, $45.67)
  /// Removes decimal places if the value is a whole number
  static String formatCurrency(double value, {String currency = '\$'}) {
    // Use absolute value for formatting, add the negative sign later if needed
    final absValue = value.abs();

    // Format with or without decimals based on whether it's a whole number
    final String formatted =
        absValue == absValue.truncateToDouble()
            ? absValue.toInt().toString()
            : absValue.toStringAsFixed(2);

    // Add the currency symbol and handle negative values
    return value < 0 ? '-$currency$formatted' : '$currency$formatted';
  }

  /// Format a date in a friendly way (e.g., "Apr 15")
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format a date with month and year (e.g., "April 2023")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Format a date with day of week (e.g., "Monday, April 15")
  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }
}
