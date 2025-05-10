import 'package:flutter/material.dart';

class CategoryUtils {
  static final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
    {'name': 'Bills', 'icon': Icons.receipt_long, 'color': Colors.red},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.pink},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': Colors.green},
    {'name': 'Education', 'icon': Icons.school, 'color': Colors.amber},
    {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Colors.teal},
    {'name': 'Rent', 'icon': Icons.home, 'color': Colors.brown},
    {'name': 'Salary', 'icon': Icons.work, 'color': Colors.green},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': Colors.blue},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  static IconData getCategoryIcon(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'icon': Icons.more_horiz},
    );
    return category['icon'];
  }

  static Color getCategoryColor(String categoryName) {
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'color': Colors.grey},
    );
    return category['color'];
  }

  static Widget buildCategoryIcon(String categoryName, {double size = 24}) {
    return Icon(
      getCategoryIcon(categoryName),
      color: getCategoryColor(categoryName),
      size: size,
    );
  }
}
