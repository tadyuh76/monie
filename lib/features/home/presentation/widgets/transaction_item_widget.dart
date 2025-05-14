import 'package:flutter/material.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionItemWidget extends StatelessWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.amount < 0;
    final colorForType = isExpense ? AppColors.expense : AppColors.income;

    // Get the category details from our transaction categories system
    final categoryName = transaction.categoryName ?? 'Other';

    // Get icon from TransactionCategories system
    IconData icon = Icons.circle;
    Color categoryColor = colorForType;

    // Try to get category info from our system
    if (transaction.categoryName != null) {
      final allCategories = TransactionCategories.getAllCategories();
      final categoryMatch = allCategories.firstWhere(
        (category) => category['name'] == transaction.categoryName,
        orElse: () => {'icon': Icons.circle, 'color': '#9E9E9E'},
      );

      icon = categoryMatch['icon'] as IconData;

      // Use the color from the transaction if available, otherwise use from our system
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? .1 : .05),
            blurRadius: isDarkMode ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isEmpty ? categoryName : transaction.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppColors.textSecondary : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount
          Text(
            isExpense
                ? '-${Formatters.formatCurrency(transaction.amount.abs())}'
                : Formatters.formatCurrency(transaction.amount),
            style: textTheme.titleMedium?.copyWith(
              color: colorForType,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
