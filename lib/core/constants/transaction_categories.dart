import 'package:flutter/material.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/utils/string_utils.dart';

/// This class provides comprehensive lists of income and expense categories with their color codes
class TransactionCategories {
  // ==================== INCOME CATEGORIES ====================
  static final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Account Adjustment', 'svgName': 'account_adjustment'},
    {'name': 'Salary', 'svgName': 'salary'},
    {'name': 'Scholarship', 'svgName': 'scholarship'},
    {'name': 'Insurance Payout', 'svgName': 'insurance_payout'},
    {'name': 'Family Support', 'svgName': 'family_support'},
    {'name': 'Stock', 'svgName': 'stock'},
    {'name': 'Commission', 'svgName': 'commission'},
    {'name': 'Allowance', 'svgName': 'allowance'},
  ];

  // ==================== EXPENSE CATEGORIES ====================
  static final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Account Adjustment', 'svgName': 'account_adjustment'},
    {'name': 'Bills', 'svgName': 'bills'},
    {'name': 'Debt', 'svgName': 'debt'},
    {'name': 'Dining', 'svgName': 'dining'},
    {'name': 'Donate', 'svgName': 'donate'},
    {'name': 'Edu', 'svgName': 'edu'},
    {'name': 'Education', 'svgName': 'education'},
    {'name': 'Electricity', 'svgName': 'electricity'},
    {'name': 'Entertainment', 'svgName': 'entertainment'},
    {'name': 'Gifts', 'svgName': 'gifts'},
    {'name': 'Groceries', 'svgName': 'groceries'},
    {'name': 'Group', 'svgName': 'group'},
    {'name': 'Healthcare', 'svgName': 'healthcare'},
    {'name': 'Housing', 'svgName': 'housing'},
    {'name': 'Insurance', 'svgName': 'insurance'},
    {'name': 'Investment', 'svgName': 'investment'},
    {'name': 'Job', 'svgName': 'job'},
    {'name': 'Loans', 'svgName': 'loans'},
    {'name': 'Pets', 'svgName': 'pets'},
    {'name': 'Rent', 'svgName': 'rent'},
    {'name': 'Saving', 'svgName': 'saving'},
    {'name': 'Settlement', 'svgName': 'settlement'},
    {'name': 'Shopping', 'svgName': 'shopping'},
    {'name': 'Tax', 'svgName': 'tax'},
    {'name': 'Technology', 'svgName': 'technology'},
    {'name': 'Transport', 'svgName': 'transport'},
    {'name': 'Travel', 'svgName': 'travel'},
  ];

  // Get all categories combined
  static List<Map<String, dynamic>> getAllCategories() {
    final List<Map<String, dynamic>> allCategories = [];

    // Add income categories with colors from CategoryColorHelper
    for (final category in incomeCategories) {
      final svgName = category['svgName'] as String;
      final colorHex = CategoryColorHelper.getHexColorForCategory(
        svgName.toLowerCase(),
        isIncome: true,
      );
      allCategories.add({...category, 'color': colorHex, 'isIncome': true});
    }

    // Add expense categories with colors from CategoryColorHelper
    for (final category in expenseCategories) {
      final svgName = category['svgName'] as String;
      final colorHex = CategoryColorHelper.getHexColorForCategory(
        svgName.toLowerCase(),
        isIncome: false,
      );
      allCategories.add({...category, 'color': colorHex, 'isIncome': false});
    }

    return allCategories;
  }

  // Get a category by name
  static Map<String, dynamic>? getCategoryByName(String name) {
    final allCategories = getAllCategories();
    try {
      return allCategories.firstWhere(
        (category) =>
            category['name'].toString().toLowerCase() ==
            name.toLowerCase().trim(),
      );
    } catch (e) {
      // Try to match by svgName if display name not found
      try {
        return allCategories.firstWhere(
          (category) =>
              (category['svgName'] as String).toLowerCase() ==
              name.toLowerCase().trim(),
        );
      } catch (e) {
        return null;
      }
    }
  }

  // Get a category color by name
  static String getCategoryColorByName(String name) {
    final category = getCategoryByName(name);
    return category?['color'] ?? '#607D8B'; // Default to coolGrey if not found
  }

  // Get SVG name for a category
  static String getSvgNameForCategory(String name) {
    // Normalize name to lowercase for proper matching
    final normalizedName = name.toLowerCase().trim();

    // First try to find category by name (case insensitive)
    for (final category in getAllCategories()) {
      if (category['name'].toString().toLowerCase() == normalizedName) {
        return category['svgName'] as String;
      }
    }

    // If no direct match found, check if name is a svgName itself
    for (final category in getAllCategories()) {
      if ((category['svgName'] as String).toLowerCase() == normalizedName) {
        return category['svgName'] as String;
      }
    }

    // If no match found, return default
    return 'shopping';
  }

  // Convert hex color string to Color object
  static Color hexToColor(String hexString) {
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }

  // Get the icon path from CategoryIcons based on category name
  static String getCategoryIconPath(String name) {
    return CategoryIcons.getIconPath(name);
  }

  // Get display name from svgName
  static String getDisplayNameFromSvgName(String svgName) {
    // First try to find category by svgName
    for (final category in getAllCategories()) {
      if ((category['svgName'] as String).toLowerCase() ==
          svgName.toLowerCase().trim()) {
        return category['name'] as String;
      }
    }

    // If not found, format the svgName to a readable format
    return StringUtils.snakeToTitleCase(svgName);
  }
}
