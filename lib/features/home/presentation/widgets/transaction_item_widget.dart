import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionItemWidget extends StatelessWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isExpense = transaction.type == 'expense';
    final colorForType = isExpense ? AppColors.expense : AppColors.income;

    // Get the appropriate icon
    IconData icon;
    if (transaction.title == 'Groceries') {
      icon = Icons.shopping_basket;
    } else if (transaction.title == 'thhy') {
      icon = Icons.work;
    } else {
      icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
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
              color: colorForType.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorForType, size: 22),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            isExpense
                ? '-${Formatters.formatCurrency(transaction.amount)}'
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
