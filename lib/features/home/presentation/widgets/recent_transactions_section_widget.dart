import 'package:flutter/material.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/home/presentation/widgets/transaction_item_widget.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class RecentTransactionsSectionWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onViewAllPressed;

  const RecentTransactionsSectionWidget({
    super.key,
    required this.transactions,
    required this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            context.tr('home_recent_transactions'),
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Transaction items grouped by date
        ...groupedTransactions.entries.map((entry) {
          final totalForDay = entry.value.fold<double>(
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
                    entry.key,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalForDay),
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...entry.value.map((transaction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TransactionItemWidget(transaction: transaction),
                );
              }),
              if (entry != groupedTransactions.entries.last)
                const SizedBox(height: 16),
            ],
          );
        }),

        const SizedBox(height: 20),

        // View all button
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                    context.tr('home_see_all') + ' ' + context.tr('home_transactions'),
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
