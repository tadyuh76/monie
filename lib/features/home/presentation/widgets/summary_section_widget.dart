import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/core/localization/app_localizations.dart';

class SummarySectionWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const SummarySectionWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    double totalExpense = 0;
    double totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.amount < 0) {
        totalExpense += transaction.amount.abs();
      } else {
        totalIncome += transaction.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_expense'),
                  style: textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
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
                  '${transactions.where((t) => t.amount < 0).length} ${context.tr('home_transactions')}',
                  style: textTheme.bodyMedium?.copyWith(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
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
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_income'),
                  style: textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
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
                  '${transactions.where((t) => t.amount >= 0).length} ${context.tr('home_transactions')}',
                  style: textTheme.bodyMedium?.copyWith(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
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
