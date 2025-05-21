import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/core/localization/app_localizations.dart';

class AccountSummaryWidget extends StatelessWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;

  const AccountSummaryWidget({
    super.key,
    required this.accounts,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate total balance
    final double totalBalance = accounts.fold(
      0,
      (previousValue, account) => previousValue + (account.balance),
    );

    // Calculate income and expense
    final double totalIncome = transactions
        .where((t) => t.amount > 0)
        .fold(0, (sum, t) => sum + t.amount);

    // For expenses, we want to display the absolute value
    final double totalExpense = transactions
        .where((t) => t.amount < 0)
        .fold(0, (sum, t) => sum + t.amount.abs());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
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
      child: Row(
        children: [
          // Balance column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_balance'),
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalBalance),
                  style: TextStyle(
                    color:
                        totalBalance >= 0
                            ? isDarkMode
                                ? Colors.white
                                : Colors.black87
                            : AppColors.expense,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Income column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_income'),
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalIncome),
                  style: const TextStyle(
                    color: AppColors.income,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Expense column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_expense'),
                  style: TextStyle(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalExpense),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
