import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/main.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = MockData.transactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Transactions',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(context),
            _buildSummaryBar(context, transactions),
            const SizedBox(height: 16),
            _buildTransactionsList(context, transactions),
            const SizedBox(height: 100), // Extra space at the bottom
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            // Show add transaction dialog
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                return const AddTransactionForm();
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Icon(Icons.add, color: AppColors.background, size: 30),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildMonthTab(context, 'March', false),
          _buildMonthTab(context, 'April', true),
          _buildMonthTab(context, 'May', false),
        ],
      ),
    );
  }

  Widget _buildMonthTab(BuildContext context, String month, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    double totalExpense = 0;
    double totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      } else {
        totalIncome += transaction.amount;
      }
    }

    final totalBalance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expense
          Column(
            children: [
              Text(
                '↓ \$${totalExpense.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Income
          Column(
            children: [
              Text(
                '↑ \$${totalIncome.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.income,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Net
          Column(
            children: [
              Text(
                '= \$${totalBalance.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in transactions) {
      final dateString = DateFormat('EEEE, MMMM d').format(transaction.date);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...groupedTransactions.entries.map((entry) {
            // final isToday = entry.key.contains('April 30');
            final totalForDay = entry.value.fold<double>(
              0,
              (sum, transaction) =>
                  sum +
                  (transaction.type == 'expense'
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${totalForDay.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.value.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildTransactionItem(context, transaction),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Total cash flow: \$178',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Center(
            child: Text(
              '3 transactions',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final textTheme = Theme.of(context).textTheme;
    final isExpense = transaction.type == 'expense';
    final colorForType = isExpense ? AppColors.expense : AppColors.income;
    final prefixSymbol = isExpense ? '-' : '+';

    // Get category color - default to type color if category is not recognized
    final categoryColor = CategoryUtils.getCategoryColor(transaction.category);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Category icon with appropriate color
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CategoryUtils.getCategoryIcon(transaction.category),
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(transaction.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '$prefixSymbol\$${transaction.amount.toStringAsFixed(0)}',
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
