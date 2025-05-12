import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/features/transactions/data/models/category_model.dart';

/// This class is deprecated and will be removed in a future version.
/// Use the CategoriesBloc instead.
class CategoryData {
  static const uuid = Uuid();

  /// Get expense categories as CategoryModel objects
  static List<CategoryModel> getExpenseCategoryModels() {
    return getExpenseCategories()
        .map(
          (cat) => CategoryModel(
            id: cat['id'] as String? ?? uuid.v4(),
            name: cat['name'] as String,
            icon: cat['icon'].toString(),
            color: CategoryColors.toHex(cat['color'] as Color),
            isIncome: false,
            isDefault: cat['isDefault'] as bool? ?? false,
          ),
        )
        .toList();
  }

  /// Get income categories as CategoryModel objects
  static List<CategoryModel> getIncomeCategoryModels() {
    return getIncomeCategories()
        .map(
          (cat) => CategoryModel(
            id: cat['id'] as String? ?? uuid.v4(),
            name: cat['name'] as String,
            icon: cat['icon'].toString(),
            color: CategoryColors.toHex(cat['color'] as Color),
            isIncome: true,
            isDefault: cat['isDefault'] as bool? ?? false,
          ),
        )
        .toList();
  }

  /// Get expense categories with their data
  static List<Map<String, dynamic>> getExpenseCategories() {
    return [
      {
        'name': 'Groceries',
        'icon': Icons.shopping_basket,
        'color': CategoryColors.green,
        'isDefault': true,
      },
      // Add more categories as needed
      {
        'name': 'Other',
        'icon': Icons.more_horiz,
        'color': CategoryColors.coolGrey,
        'isDefault': true,
      },
    ];
  }

  /// Get income categories with their data
  static List<Map<String, dynamic>> getIncomeCategories() {
    return [
      {
        'name': 'Salary',
        'icon': Icons.work,
        'color': CategoryColors.green,
        'isDefault': true,
      },
      // Add more categories as needed
      {
        'name': 'Other',
        'icon': Icons.more_horiz,
        'color': CategoryColors.coolGrey,
        'isDefault': true,
      },
    ];
  }

  /// Calculate total expenses from transactions
  static double getTotalExpenses(List<dynamic> transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Calculate total income from transactions
  static double getTotalIncome(List<dynamic> transactions) {
    return transactions
        .where((t) => t.amount >= 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Stub method to maintain compatibility
  static Future<bool> seedCategoriesIntoDatabase() async {
    // This method is no longer used
    return true;
  }

  /// Stub method to maintain compatibility
  static Future<String> ensureCategoryExists(CategoryModel category) async {
    // This method is no longer used
    return category.id;
  }
}
