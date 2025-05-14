import 'package:flutter/material.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/themes/category_colors.dart';

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
    return CategoryColorHelper.getColorForCategory(categoryName);
  }

  // Get category color hex from category name
  static String getCategoryColorHex(String categoryName) {
    return CategoryColorHelper.getHexColorForCategory(categoryName);
  }

  // Convert hex string to color
  static Color hexToColor(String hexString) {
    return CategoryColors.fromHex(hexString);
  }

  // Convert color to hex string
  static String colorToHex(Color color) {
    return CategoryColors.toHex(color);
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
