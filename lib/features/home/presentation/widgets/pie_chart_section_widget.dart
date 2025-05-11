import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_data.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/home/presentation/widgets/category_pie_chart.dart';

class PieChartSectionWidget extends StatefulWidget {
  const PieChartSectionWidget({super.key});

  @override
  State<PieChartSectionWidget> createState() => _PieChartSectionWidgetState();
}

class _PieChartSectionWidgetState extends State<PieChartSectionWidget> {
  // Index for pie chart pages (0 = expenses, 1 = incomes)
  int _pieChartPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Get category data
    final expenseCategories = CategoryData.getExpenseCategories();
    final incomeCategories = CategoryData.getIncomeCategories();

    // Calculate totals based on mock transactions
    final totalExpenses = CategoryData.getTotalExpenses(MockData.transactions);
    final totalIncome = CategoryData.getTotalIncome(MockData.transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Analysis',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(
            top: 0,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          height: 400,
          child: PageView(
            onPageChanged: (index) {
              setState(() {
                _pieChartPageIndex = index;
              });
            },
            children: [
              // Expense pie chart
              CategoryPieChart(
                isExpense: true,
                totalAmount: totalExpenses,
                categories: expenseCategories,
              ),
              // Income pie chart
              CategoryPieChart(
                isExpense: false,
                totalAmount: totalIncome,
                categories: incomeCategories,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _pieChartPageIndex == 0
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _pieChartPageIndex == 1
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
