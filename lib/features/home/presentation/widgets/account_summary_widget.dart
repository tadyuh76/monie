import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/home/domain/entities/account.dart';
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
    // Calculate total balance
    final double totalBalance = accounts.fold(
      0,
      (previousValue, account) => previousValue + account.balance,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalBalance),
                  style: TextStyle(
                    color: totalBalance >= 0 ? Colors.white : AppColors.expense,
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
