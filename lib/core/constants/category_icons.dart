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
    'salary',
    'scholarship',
    'insurance',
    'family',
    'stock',
    'commission',
    'allowance',
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
  // Map of category names to their respective color names - using exact mapping provided
  static final Map<String, String> categoryToColorNameMap = {
    // Expense categories
    'bills': 'blue',
    'debt': 'green',
    'dining': 'coolGrey',
    'donate': 'teal',
    'edu': 'darkBlue',
    'education': 'red',
    'electricity': 'gold',
    'entertainment': 'blue',
    'gifts': 'plum',
    'groceries': 'orange',
    'group': 'darkBlue',
    'healthcare': 'red',
    'housing': 'green',
    'insurance': 'teal',
    'investment': 'gold',
    'job': 'coolGrey',
    'loans': 'orange',
    'pets': 'gold',
    'rent': 'blue',
    'saving': 'plum',
    'settlement': 'gold',
    'shopping': 'purple',
    'tax': 'blue',
    'technology': 'indigo',
    'transport': 'teal',
    'travel': 'blue',

    // Income categories
    'salary': 'blue',
    'scholarship': 'orange',
    'insurance': 'green',
    'family': 'plum',
    'stock': 'gold',
    'commission': 'red',
    'allowance': 'teal',
  };

  // Map of category names to their respective colors
  static final Map<String, Color> categoryColorMap = _buildColorMap();

  // Build color map from the color name mapping
  static Map<String, Color> _buildColorMap() {
    final Map<String, Color> colorMap = {};

    categoryToColorNameMap.forEach((category, colorName) {
      switch (colorName) {
        case 'blue':
          colorMap[category] = CategoryColors.blue;
          break;
        case 'green':
          colorMap[category] = CategoryColors.green;
          break;
        case 'coolGrey':
          colorMap[category] = CategoryColors.coolGrey;
          break;
        case 'teal':
          colorMap[category] = CategoryColors.teal;
          break;
        case 'darkBlue':
          colorMap[category] = CategoryColors.darkBlue;
          break;
        case 'red':
          colorMap[category] = CategoryColors.red;
          break;
        case 'gold':
          colorMap[category] = CategoryColors.gold;
          break;
        case 'orange':
          colorMap[category] = CategoryColors.orange;
          break;
        case 'plum':
          colorMap[category] = CategoryColors.plum;
          break;
        case 'purple':
          colorMap[category] = CategoryColors.purple;
          break;
        case 'indigo':
          colorMap[category] = CategoryColors.indigo;
          break;
        default:
          colorMap[category] = CategoryColors.coolGrey;
      }
    });

    return colorMap;
  }

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
