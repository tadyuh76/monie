import 'package:flutter/material.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:intl/intl.dart';

class MonthlySummaryWidget extends StatefulWidget {
  final List<Transaction> transactions;

  const MonthlySummaryWidget({super.key, required this.transactions});

  @override
  State<MonthlySummaryWidget> createState() => _MonthlySummaryWidgetState();
}

class _MonthlySummaryWidgetState extends State<MonthlySummaryWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Get current month transactions
    final now = DateTime.now();
    final currentMonthTransactions =
        widget.transactions.where((transaction) {
          return transaction.date.month == now.month &&
              transaction.date.year == now.year;
        }).toList();

    // Calculate totals
    final totalExpense = _calculateTotalExpense(currentMonthTransactions);
    final totalIncome = _calculateTotalIncome(currentMonthTransactions);

    // Format currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDarkMode
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('monthly_summary_title'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surface : Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDarkMode ? Colors.white70 : Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: context.tr('monthly_summary_expenses')),
                Tab(text: context.tr('monthly_summary_income')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Expenses Tab
                _buildSummaryContent(
                  context,
                  amount: totalExpense,
                  formattedAmount: currencyFormatter.format(totalExpense),
                  icon: Icons.arrow_downward,
                  iconColor: AppColors.expense,
                  title: context.tr('monthly_summary_expenses'),
                  transactions:
                      currentMonthTransactions
                          .where((t) => t.amount < 0)
                          .toList(),
                ),

                // Income Tab
                _buildSummaryContent(
                  context,
                  amount: totalIncome,
                  formattedAmount: currencyFormatter.format(totalIncome),
                  icon: Icons.arrow_upward,
                  iconColor: AppColors.income,
                  title: context.tr('monthly_summary_income'),
                  transactions:
                      currentMonthTransactions
                          .where((t) => t.amount > 0)
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(
    BuildContext context, {
    required double amount,
    required String formattedAmount,
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Transaction> transactions,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 28)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedAmount,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child:
              transactions.isEmpty
                  ? Center(
                    child: Text(
                      context.tr('monthly_summary_no_data'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black38,
                      ),
                    ),
                  )
                  : _buildTopCategories(context, transactions),
        ),
      ],
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    // Group by category and sum amounts
    final Map<String, double> categoryTotals = {};
    for (final transaction in transactions) {
      final category = transaction.categoryName ?? context.tr('uncategorized');
      final amount = transaction.amount.abs();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    // Sort by amount
    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3
    final topCategories = sortedCategories.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('monthly_summary_top_categories'),
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child:
              topCategories.isEmpty
                  ? Center(
                    child: Text(
                      context.tr('monthly_summary_no_data'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black38,
                      ),
                    ),
                  )
                  : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topCategories.length,
                    itemBuilder: (context, index) {
                      final category = topCategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                category.key,
                                style: textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyFormatter.format(category.value),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  double _calculateTotalExpense(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.amount < 0)
        .fold(0, (sum, transaction) => sum + transaction.amount.abs());
  }

  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.amount > 0)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }
}
