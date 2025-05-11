import 'package:flutter/material.dart';

/// Static data class for category information
class CategoryData {
  /// Get expense categories with their data
  static List<Map<String, dynamic>> getExpenseCategories() {
    return [
      {
        'name': 'Groceries',
        'value': 35.0,
        'color': const Color(0xFF66BB6A),
        'icon': Icons.shopping_basket,
      },
      {
        'name': 'Dining',
        'value': 25.0,
        'color': const Color(0xFFFFA726),
        'icon': Icons.restaurant,
      },
      {
        'name': 'Transport',
        'value': 20.0,
        'color': const Color(0xFF42A5F5),
        'icon': Icons.directions_car,
      },
      {
        'name': 'Shopping',
        'value': 15.0,
        'color': const Color(0xFFEC407A),
        'icon': Icons.shopping_bag,
      },
      {
        'name': 'Entertainment',
        'value': 5.0,
        'color': const Color(0xFFAB47BC),
        'icon': Icons.movie,
      },
    ];
  }

  /// Get income categories with their data
  static List<Map<String, dynamic>> getIncomeCategories() {
    return [
      {
        'name': 'Salary',
        'value': 70.0,
        'color': const Color(0xFF42A5F5),
        'icon': Icons.work,
      },
      {
        'name': 'Investments',
        'value': 20.0,
        'color': const Color(0xFFFFD54F),
        'icon': Icons.trending_up,
      },
      {
        'name': 'Freelance',
        'value': 10.0,
        'color': const Color(0xFF7E57C2),
        'icon': Icons.computer,
      },
    ];
  }

  /// Calculate total expenses from transactions
  static double getTotalExpenses(List<dynamic> transactions) {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calculate total income from transactions
  static double getTotalIncome(List<dynamic> transactions) {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
