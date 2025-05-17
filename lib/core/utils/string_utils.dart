/// Utility class for string operations
class StringUtils {
  /// Converts a snake_case string to a properly formatted title case string
  /// Example: "insurance_payout" becomes "Insurance Payout"
  static String snakeToTitleCase(String text) {
    if (text.isEmpty) return '';

    // Split by underscore
    final words = text.split('_');

    // Capitalize each word and join with space
    return words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Formats any string to title case (capitalize first letter of each word)
  static String toTitleCase(String text) {
    if (text.isEmpty) return '';

    // Split by space
    final words = text.split(' ');

    // Capitalize each word and join with space
    return words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
