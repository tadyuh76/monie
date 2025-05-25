import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';

class CategoryBreakdownWidget extends StatefulWidget {
  const CategoryBreakdownWidget({super.key});

  @override
  State<CategoryBreakdownWidget> createState() =>
      _CategoryBreakdownWidgetState();
}

class _CategoryBreakdownWidgetState extends State<CategoryBreakdownWidget>
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

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is TransactionError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                context.tr('home_transaction_error'),
                style: TextStyle(
                  color: isDarkMode ? Colors.red[300] : Colors.red,
                ),
              ),
            ),
          );
        } else if (state is TransactionsLoaded) {
          if (state.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  context.tr('home_no_transactions'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // Get current month transactions
          final now = DateTime.now();
          final currentMonthTransactions =
              state.transactions
                  .where(
                    (t) => t.date.month == now.month && t.date.year == now.year,
                  )
                  .toList();

          if (currentMonthTransactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  context.tr('no_transactions_this_month'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  context.tr('category_breakdown'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: isDarkMode ? Colors.white : Colors.black87,
                      unselectedLabelColor:
                          isDarkMode ? Colors.white60 : Colors.black45,
                      indicatorColor: AppColors.primary,
                      dividerColor: Colors.white10,
                      tabs: [
                        Tab(text: context.tr('expense')),
                        Tab(text: context.tr('income')),
                      ],
                    ),
                    SizedBox(
                      height: 380,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Expense tab
                          _buildPieChart(
                            context: context,
                            transactions:
                                currentMonthTransactions
                                    .where((t) => t.amount < 0)
                                    .toList(),
                            isExpense: true,
                            isDarkMode: isDarkMode,
                          ),

                          // Income tab
                          _buildPieChart(
                            context: context,
                            transactions:
                                currentMonthTransactions
                                    .where((t) => t.amount > 0)
                                    .toList(),
                            isExpense: false,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildPieChart({
    required BuildContext context,
    required List<Transaction> transactions,
    required bool isExpense,
    required bool isDarkMode,
  }) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            isExpense
                ? context.tr('no_expenses_this_month')
                : context.tr('no_income_this_month'),
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Group transactions by category
    final Map<String, double> categoryTotals = {};
    final Map<String, Color> categoryColors = {};

    for (var transaction in transactions) {
      final categoryName =
          transaction.categoryName ?? context.tr('uncategorized');
      final amount = transaction.amount.abs();

      if (!categoryTotals.containsKey(categoryName)) {
        categoryTotals[categoryName] = 0;

        // Assign color based on transaction color or default
        if (transaction.color != null) {
          try {
            final colorValue = int.parse(
              transaction.color!.replaceAll('#', '0xFF'),
            );
            categoryColors[categoryName] = Color(colorValue);
          } catch (e) {
            categoryColors[categoryName] =
                isExpense ? AppColors.expense : AppColors.income;
          }
        } else {
          categoryColors[categoryName] =
              isExpense ? AppColors.expense : AppColors.income;
        }
      }

      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + amount;
    }

    // Calculate total amount
    final totalAmount = categoryTotals.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );

    // Sort categories by amount (descending)
    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare data for the pie chart
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    // Define a list of colors for categories without specific colors
    final defaultColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.deepOrange,
    ];

    int colorIndex = 0;

    for (var entry in sortedCategories) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalAmount) * 100;

      // Get or assign color
      final color =
          categoryColors[category] ??
          defaultColors[colorIndex % defaultColors.length];
      colorIndex++;

      // Add pie section
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '',
          radius: 100,
          showTitle: false,
        ),
      );

      // Add legend item
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatCurrency(amount),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legendItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
