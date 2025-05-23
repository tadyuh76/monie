import 'package:flutter/material.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/core/utils/string_utils.dart';

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

  // Convert category display name to SVG name
  // Example: 'Account Adjustment' -> 'account_adjustment'
  static String getCategorySvgName(String displayName) {
    // First check if the name is already in the correct format
    if (CategoryIcons.incomeCategories.contains(
          displayName.toLowerCase().trim(),
        ) ||
        CategoryIcons.expenseCategories.contains(
          displayName.toLowerCase().trim(),
        )) {
      return displayName.toLowerCase().trim();
    }

    // Check if it's a display name in our categories
    final category = categories.firstWhere(
      (c) =>
          c['name'].toString().toLowerCase() ==
          displayName.toLowerCase().trim(),
      orElse: () => {'svgName': null},
    );

    if (category['svgName'] != null) {
      return category['svgName'] as String;
    }

    // If not found in our categories, convert it to snake_case
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .trim()
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
  }

  // Get icon for a category name
  static IconData getCategoryIcon(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName || c['svgName'] == categoryName,
      orElse: () => {'icon': Icons.help_outline},
    );
    return category['icon'] as IconData;
  }

  // Get color for a category name or svgName
  static Color getCategoryColor(String categoryIdentifier, {bool? isIncome}) {
    // Convert to SVG name format first
    String svgName = getCategorySvgName(categoryIdentifier);

    // Try to find directly in category color helper
    Color? color = CategoryColorHelper.getColorForCategory(
      svgName,
      isIncome: isIncome,
    );

    // If we got the default color, try finding the svgName through TransactionCategories
    if (color == CategoryColors.coolGrey) {
      svgName = TransactionCategories.getSvgNameForCategory(categoryIdentifier);
      color = CategoryColorHelper.getColorForCategory(
        svgName,
        isIncome: isIncome,
      );
    }

    return color;
  }

  // Get category color hex from category name
  static String getCategoryColorHex(String categoryName, {bool? isIncome}) {
    // Convert to SVG name format first
    String svgName = getCategorySvgName(categoryName);

    // Try with the SVG name
    String result = CategoryColorHelper.getHexColorForCategory(
      svgName,
      isIncome: isIncome,
    );

    // If we got the default color, try finding the svgName through TransactionCategories
    if (result == CategoryColors.toHex(CategoryColors.coolGrey)) {
      svgName = TransactionCategories.getSvgNameForCategory(categoryName);
      result = CategoryColorHelper.getHexColorForCategory(
        svgName,
        isIncome: isIncome,
      );
    }

    return result;
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

  // Format category name for display - handles both display names and svg names
  static String formatCategoryName(String categoryIdentifier) {
    // First check if it's a svgName in our categories
    final category = categories.firstWhere(
      (c) => c['svgName'] == categoryIdentifier,
      orElse: () => {'name': null, 'svgName': categoryIdentifier},
    );

    if (category['name'] != null) {
      return category['name'] as String;
    }

    // If it's not found, format as title case from the identifier
    return StringUtils.snakeToTitleCase(categoryIdentifier);
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
