import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.amount >= 0;
    final formatter = NumberFormat.currency(symbol: '\$');
    final formattedAmount = formatter.format(transaction.amount.abs());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: _buildCategoryIcon(),
        title: Text(
          transaction.title.isEmpty
              ? transaction.categoryName ?? 'Transaction'
              : transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (transaction.description.isNotEmpty)
              Text(
                transaction.description,
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().format(transaction.date),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isIncome ? formattedAmount : '- $formattedAmount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder:
                    (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                    ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    // Get the category details from TransactionCategories
    IconData iconData = Icons.circle;
    Color categoryColor;

    if (transaction.amount >= 0) {
      categoryColor = AppColors.income;
    } else {
      categoryColor = AppColors.expense;
    }

    // Try to find the category in our categories list
    if (transaction.categoryName != null) {
      // Get all categories
      final allCategories = TransactionCategories.getAllCategories();

      // Try to find a matching category
      final categoryMatch = allCategories.firstWhere(
        (category) => category['name'] == transaction.categoryName,
        orElse: () => {'icon': Icons.circle, 'color': '#9E9E9E'},
      );

      iconData = categoryMatch['icon'] as IconData;

      // Use the color from transaction if available, otherwise from the category system
      if (transaction.categoryColor != null) {
        categoryColor = TransactionCategories.hexToColor(
          transaction.categoryColor!,
        );
      } else if (categoryMatch['color'] != null) {
        categoryColor = TransactionCategories.hexToColor(
          categoryMatch['color'] as String,
        );
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: .2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: categoryColor, size: 20),
    );
  }
}
