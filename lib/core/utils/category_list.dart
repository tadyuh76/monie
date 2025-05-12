import 'package:flutter/material.dart';

/// This file provides a reference of all available categories with their colors
/// Use this as a guide when working with categories in your app

class CategoryList {
  /// Food category - Orange
  static const String foodName = 'Food';
  static const Color foodColor = Colors.orange;
  static const String foodHex = '#FF9800';

  /// Transport category - Blue
  static const String transportName = 'Transport';
  static const Color transportColor = Colors.blue;
  static const String transportHex = '#2196F3';

  /// Shopping category - Purple
  static const String shoppingName = 'Shopping';
  static const Color shoppingColor = Colors.purple;
  static const String shoppingHex = '#9C27B0';

  /// Bills category - Red
  static const String billsName = 'Bills';
  static const Color billsColor = Colors.red;
  static const String billsHex = '#F44336';

  /// Entertainment category - Pink
  static const String entertainmentName = 'Entertainment';
  static const Color entertainmentColor = Colors.pink;
  static const String entertainmentHex = '#E91E63';

  /// Health category - Green
  static const String healthName = 'Health';
  static const Color healthColor = Colors.green;
  static const String healthHex = '#4CAF50';

  /// Education category - Amber
  static const String educationName = 'Education';
  static const Color educationColor = Colors.amber;
  static const String educationHex = '#FFC107';

  /// Groceries category - Teal
  static const String groceriesName = 'Groceries';
  static const Color groceriesColor = Colors.teal;
  static const String groceriesHex = '#009688';

  /// Rent category - Brown
  static const String rentName = 'Rent';
  static const Color rentColor = Colors.brown;
  static const String rentHex = '#795548';

  /// Salary category - Green
  static const String salaryName = 'Salary';
  static const Color salaryColor = Colors.green;
  static const String salaryHex = '#4CAF50';

  /// Investment category - Blue
  static const String investmentName = 'Investment';
  static const Color investmentColor = Colors.blue;
  static const String investmentHex = '#2196F3';

  /// Gift category - Deep Purple
  static const String giftName = 'Gift';
  static const Color giftColor = Colors.deepPurple;
  static const String giftHex = '#673AB7';

  /// Other category - Grey
  static const String otherName = 'Other';
  static const Color otherColor = Colors.grey;
  static const String otherHex = '#9E9E9E';

  /// Returns a list of all categories with their names and hex colors
  static List<Map<String, String>> getAllCategoriesWithColors() {
    return [
      {'name': foodName, 'color': foodHex, 'type': 'expense'},
      {'name': transportName, 'color': transportHex, 'type': 'expense'},
      {'name': shoppingName, 'color': shoppingHex, 'type': 'expense'},
      {'name': billsName, 'color': billsHex, 'type': 'expense'},
      {'name': entertainmentName, 'color': entertainmentHex, 'type': 'expense'},
      {'name': healthName, 'color': healthHex, 'type': 'expense'},
      {'name': educationName, 'color': educationHex, 'type': 'expense'},
      {'name': groceriesName, 'color': groceriesHex, 'type': 'expense'},
      {'name': rentName, 'color': rentHex, 'type': 'expense'},
      {'name': salaryName, 'color': salaryHex, 'type': 'income'},
      {'name': investmentName, 'color': investmentHex, 'type': 'income'},
      {'name': giftName, 'color': giftHex, 'type': 'income'},
      {'name': otherName, 'color': otherHex, 'type': 'both'},
    ];
  }

  /// Returns expense categories only
  static List<Map<String, String>> getExpenseCategories() {
    return getAllCategoriesWithColors()
        .where((cat) => cat['type'] == 'expense' || cat['type'] == 'both')
        .toList();
  }

  /// Returns income categories only
  static List<Map<String, String>> getIncomeCategories() {
    return getAllCategoriesWithColors()
        .where((cat) => cat['type'] == 'income' || cat['type'] == 'both')
        .toList();
  }
}
