import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class SummarySectionWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const SummarySectionWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    double totalExpense = 0;
    double totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      } else if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(totalExpense),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactions.where((t) => t.type == 'expense').length} transactions',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(totalIncome),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.income,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactions.where((t) => t.type == 'income').length} transaction',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
