import 'package:flutter/material.dart';
import 'package:monie/core/themes/category_colors.dart';

/// This class is responsible for mapping category names to their respective icons
class CategoryIcons {
  // Get the icon path for a given category
  static String getIconPath(String categoryName) {
    final String normalizedName = categoryName.toLowerCase().trim();

    // Check if it's an income or expense category
    if (incomeCategories.contains(normalizedName)) {
      return 'assets/icons/income/$normalizedName.svg';
    } else {
      return 'assets/icons/expense/$normalizedName.svg';
    }
  }

  // Get the color for a given category
  static Color getColor(String categoryName) {
    final String normalizedName = categoryName.toLowerCase().trim();
    return CategoryColorHelper.getColorForCategory(normalizedName);
  }

  // List of income categories - exactly as specified
  static const List<String> incomeCategories = [
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

    // Income categories
    'salary': CategoryColors.blue,
    'scholarship': CategoryColors.orange,
    'insurance_payout': CategoryColors.green,
    'family_support': CategoryColors.plum,
    'stock': CategoryColors.gold,
    'commission': CategoryColors.red,
    'allowance': CategoryColors.teal,
  };

  // Get the color for a specific category
  static Color getColorForCategory(String categoryName) {
    final String normalizedName = categoryName.toLowerCase().trim();
    return categoryColorMap[normalizedName] ?? CategoryColors.coolGrey;
  }

  // Get the color in hex format for a specific category
  static String getHexColorForCategory(String categoryName) {
    final Color color = getColorForCategory(categoryName);
    return CategoryColors.toHex(color);
  }
}
