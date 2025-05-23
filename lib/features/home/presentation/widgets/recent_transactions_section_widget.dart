import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/core/widgets/transaction_card_widget.dart';
import 'package:monie/features/account/data/models/account_model.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class RecentTransactionsSectionWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onViewAllPressed;
  final Function(Transaction)? onTransactionTap;
  final Function(String)? onTransactionDelete;

  const RecentTransactionsSectionWidget({
    super.key,
    required this.transactions,
    required this.onViewAllPressed,
    this.onTransactionTap,
    this.onTransactionDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Sort by date (newest first) and limit to 3 transactions
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedTransactions.take(3).toList();

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in recentTransactions) {
      final dateString = Formatters.formatFullDate(transaction.date);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    // Sort the grouped dates with newest first
    final sortedDates =
        groupedTransactions.keys.toList()..sort((a, b) {
          // Since transactions are already sorted by date,
          // we can use the first transaction's date in each group for comparison
          final dateA = groupedTransactions[a]!.first.date;
          final dateB = groupedTransactions[b]!.first.date;
          return dateB.compareTo(dateA); // Newest first
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            context.tr('home_recent_transactions'),
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Transaction items grouped by date
        ...sortedDates.map((dateString) {
          final transactionsForDate = groupedTransactions[dateString]!;
          final totalForDay = transactionsForDate.fold<double>(
            0,
            (sum, transaction) =>
                sum +
                (transaction.amount < 0
                    ? -transaction.amount
                    : transaction.amount),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateString,
                    style: textTheme.bodyLarge?.copyWith(
                      color:
                          isDarkMode ? AppColors.textSecondary : Colors.black54,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalForDay),
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...transactionsForDate.map((transaction) {
                // Get account name if available
                String? accountName;
                if (transaction.accountId != null) {
                  final accountState = context.watch<AccountBloc>().state;
                  if (accountState is AccountsLoaded) {
                    final account = accountState.accounts.firstWhere(
                      (a) => a.accountId == transaction.accountId,
                      orElse:
                          () => AccountModel(
                            accountId: '',
                            userId: '',
                            name: 'Unknown Account',
                            type: 'Other',
                          ),
                    );
                    accountName = account.name;
                  }
                }

                // Get budget name if available
                String? budgetName;
                if (transaction.budgetId != null) {
                  final budgetState = context.watch<BudgetsBloc>().state;
                  if (budgetState is BudgetsLoaded) {
                    final budget = budgetState.budgets.firstWhere(
                      (b) => b.budgetId == transaction.budgetId,
                      orElse:
                          () => BudgetModel(
                            budgetId: '',
                            userId: '',
                            name: 'Unknown Budget',
                            amount: 0,
                            startDate: DateTime.now(),
                          ),
                    );
                    budgetName = budget.name;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TransactionCardWidget(
                    transaction: transaction,
                    accountName: accountName,
                    budgetName: budgetName,
                    onTap:
                        onTransactionTap != null
                            ? () => onTransactionTap!(transaction)
                            : null,
                    onDelete: onTransactionDelete,
                    // Don't display date since it's already in the section header
                    showDate: false,
                  ),
                );
              }),
              if (dateString != sortedDates.last) const SizedBox(height: 16),
            ],
          );
        }),

        const SizedBox(height: 20),

        // View all button
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surface : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: onViewAllPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${context.tr('home_see_all')} ${context.tr('home_transactions')}',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
