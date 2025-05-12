import 'package:flutter/material.dart';
import 'package:monie/core/constants/transaction_categories.dart';

/// Utility class for working with transaction categories
class CategoryUtils {
  // Get all categories with their icons and colors
  static List<Map<String, dynamic>> get categories {
    return TransactionCategories.getAllCategories();
  }

  // Get expense categories
  static List<Map<String, dynamic>> getExpenseCategories() {
    return TransactionCategories.expenseCategories;
  }

  // Get income categories
  static List<Map<String, dynamic>> getIncomeCategories() {
    return TransactionCategories.incomeCategories;
  }

  // Get icon for a category name
  static IconData getCategoryIcon(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'icon': Icons.help_outline},
    );
    return category['icon'] as IconData;
  }

  // Get color for a category name
  static Color getCategoryColor(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'color': '#9E9E9E'},
    );

    if (category['color'] is Color) {
      return category['color'] as Color;
    } else if (category['color'] is String) {
      return hexToColor(category['color'] as String);
    }

    return Colors.grey;
  }

  // Convert hex string to color
  static Color hexToColor(String hexString) {
    return TransactionCategories.hexToColor(hexString);
  }

  // Convert color to hex string
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  // Build a category icon widget
  static Widget buildCategoryIcon(String categoryName, {double size = 24}) {
    return Icon(
      getCategoryIcon(categoryName),
      color: getCategoryColor(categoryName),
      size: size,
    );
  }

  // Build a category icon with specific color
  static Widget buildCategoryIconWithColor(
    String? categoryName,
    String? colorHex, {
    double size = 24,
  }) {
    if (categoryName == null) {
      return Icon(Icons.more_horiz, color: Colors.grey, size: size);
    }

    Color color = Colors.grey;
    if (colorHex != null) {
      try {
        color = hexToColor(colorHex);
      } catch (e) {
        color = getCategoryColor(categoryName);
      }
    } else {
      color = getCategoryColor(categoryName);
    }

    return Icon(getCategoryIcon(categoryName), color: color, size: size);
  }

  // Get a list of category names with their hex color values - useful for exporting or displaying
  static List<Map<String, String>> getCategoryColorsMap() {
    return categories.map((category) {
      String colorValue;
      if (category['color'] is Color) {
        colorValue = colorToHex(category['color'] as Color);
      } else {
        colorValue = category['color'] as String;
      }

      return {'name': category['name'] as String, 'color': colorValue};
    }).toList();
  }
}
