import 'package:flutter/material.dart';
import 'package:monie/core/themes/category_colors.dart';

/// This class is responsible for mapping category names to their respective icons
class CategoryIcons {
  // Get the icon path for a given category
  static String getIconPath(String categoryName) {
    // Convert display name to SVG name format
    final String svgName = convertToSvgName(categoryName);

    // Check if it's an income or expense category
    if (incomeCategories.contains(svgName)) {
      return 'assets/icons/income/$svgName.svg';
    } else {
      return 'assets/icons/expense/$svgName.svg';
    }
  }

  // Helper method to convert display name to SVG name
  static String convertToSvgName(String displayName) {
    // First check if the name is already in the correct format
    final String normalized = displayName.toLowerCase().trim();

    if (incomeCategories.contains(normalized) ||
        expenseCategories.contains(normalized)) {
      return normalized;
    }

    // If not found in our categories, convert it to snake_case
    return normalized
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
  }

  // Get the color for a given category
  static Color getColor(String categoryName) {
    final String svgName = convertToSvgName(categoryName);
    return CategoryColorHelper.getColorForCategory(svgName);
  }

  // List of income categories - exactly as specified
  static const List<String> incomeCategories = [
    'account_adjustment',
    'allowance',
    'commission',
    'family_support',
    'insurance_payout',
    'salary',
    'scholarship',
    'stock',
  ];

  // List of expense categories - exactly as specified
  static const List<String> expenseCategories = [
    'account_adjustment',
    'bills',
    'debt',
    'dining',
    'donate',
    'edu',
    'education',
    'electricity',
    'entertainment',
    'gifts',
    'groceries',
    'group',
    'healthcare',
    'housing',
    'insurance',
    'investment',
    'job',
    'loans',
    'pets',
    'rent',
    'saving',
    'settlement',
    'shopping',
    'tax',
    'technology',
    'transport',
    'travel',
  ];
}

/// Helper class for getting colors for specific categories
class CategoryColorHelper {
  // Map of category names to their respective colors
  static final Map<String, Color> categoryColorMap = {
    // Expense categories
    'account_adjustment':
        CategoryColors.red, // This will be for expense (withdrawal)
    'bills': CategoryColors.blue,
    'debt': CategoryColors.green,
    'dining': CategoryColors.coolGrey,
    'donate': CategoryColors.teal,
    'edu': CategoryColors.darkBlue,
    'education': CategoryColors.red,
    'electricity': CategoryColors.gold,
    'entertainment': CategoryColors.blue,
    'gifts': CategoryColors.plum,
    'groceries': CategoryColors.orange,
    'group': CategoryColors.darkBlue,
    'healthcare': CategoryColors.red,
    'housing': CategoryColors.green,
    'insurance': CategoryColors.teal,
    'investment': CategoryColors.gold,
    'job': CategoryColors.coolGrey,
    'loans': CategoryColors.orange,
    'pets': CategoryColors.gold,
    'rent': CategoryColors.blue,
    'saving': CategoryColors.plum,
    'settlement': CategoryColors.gold,
    'shopping': CategoryColors.purple,
    'tax': CategoryColors.blue,
    'technology': CategoryColors.indigo,
    'transport': CategoryColors.teal,
    'travel': CategoryColors.blue,

    // Income categories (removing duplicate account_adjustment)
    'salary': CategoryColors.blue,
    'scholarship': CategoryColors.orange,
    'insurance_payout': CategoryColors.green,
    'family_support': CategoryColors.plum,
    'stock': CategoryColors.gold,
    'commission': CategoryColors.red,
    'allowance': CategoryColors.teal,
  };

  // Get the color for a specific category
  static Color getColorForCategory(String categoryName, {bool? isIncome}) {
    final String normalizedName = categoryName.toLowerCase().trim();

    // Special handling for account_adjustment based on transaction type
    if (normalizedName == 'account_adjustment' && isIncome == true) {
      return CategoryColors.green; // Deposit (income)
    }

    return categoryColorMap[normalizedName] ?? CategoryColors.coolGrey;
  }

  // Get the color in hex format for a specific category
  static String getHexColorForCategory(String categoryName, {bool? isIncome}) {
    final Color color = getColorForCategory(categoryName, isIncome: isIncome);
    return CategoryColors.toHex(color);
  }
}
