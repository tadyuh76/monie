import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/home/presentation/widgets/chart_painters.dart';

class CategoryPieChart extends StatelessWidget {
  final bool isExpense;
  final double totalAmount;
  final List<Map<String, dynamic>> categories;
  final bool isDarkMode;

  const CategoryPieChart({
    super.key,
    required this.isExpense,
    required this.totalAmount,
    required this.categories,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out categories with null values and ensure we have valid data
    final validCategories =
        categories
            .where((category) => (category['value'] ?? 0.0) > 0.0)
            .toList();

    // Total value for percentage calculations
    final double totalValue =
        validCategories.isEmpty
            ? 0.0
            : validCategories.fold(
              0.0,
              (sum, item) => sum + (item['value'] ?? 0.0),
            );

    // Colors for the indicator triangle
    final indicatorColor =
        isExpense
            ? const Color(0xFFEF5350) // Red for expense
            : const Color(0xFF66BB6A); // Green for income

    // Title text
    final titleText = isExpense ? 'Expenses' : 'Income';

    // Color for the total amount
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

    // Handle empty data case
    if (validCategories.isEmpty || totalValue <= 0) {
      return SizedBox(
        width: 280,
        height: 280,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense ? Icons.money_off : Icons.account_balance_wallet,
              color: isDarkMode ? Colors.white54 : Colors.black45,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No $titleText data available',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(totalAmount),
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: PieChart(
            PieChartData(
              startDegreeOffset: 270, // Start from the top
              sectionsSpace: 3, // Slightly more space between sections
              centerSpaceRadius: 60,
              sections:
                  validCategories.map((category) {
                    return PieChartSectionData(
                      color: category['color'],
                      value: category['value'] ?? 0.0,
                      title: '',
                      radius: 90,
                      showTitle: false,
                    );
                  }).toList(),
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        ),

        // Title and amount in the center
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(totalAmount),
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),

        // Category icons positioned around the pie chart
        ...List.generate(validCategories.length, (index) {
          // Calculate the starting angle for each category
          double startAngle = 270.0; // Start from the top
          for (int i = 0; i < index; i++) {
            startAngle += (validCategories[i]['value'] / totalValue) * 360.0;
          }

          // Calculate the middle angle of this section
          double middleAngle =
              startAngle +
              (validCategories[index]['value'] / totalValue) * 180.0;

          // Convert to radians
          double middleAngleRadians = middleAngle * (pi / 180);

          // Position at the edge of the chart with some padding
          final radius = 110;
          final x = radius * cos(middleAngleRadians);
          final y = radius * sin(middleAngleRadians);

          return Positioned(
            left: 140 + x, // Center + offset
            top: 140 + y,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: validCategories[index]['color'],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? AppColors.cardDark : Colors.white,
                  width: 2
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                validCategories[index]['icon'],
                color: Colors.white,
                size: 16,
              ),
            ),
          );
        }),

        // Legend at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 36,
            color: (isDarkMode 
                ? AppColors.background 
                : Colors.grey[100]!).withValues(alpha: 0.7),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: validCategories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemBuilder: (context, index) {
                // Calculate percentage of this category
                double percentage =
                    (validCategories[index]['value'] / totalValue) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: validCategories[index]['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${validCategories[index]['name']} (${percentage.round()}%)',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Triangle indicator at the top right
        Positioned(
          top: 24,
          right: 12,
          child: CustomPaint(
            painter: TrianglePainter(indicatorColor),
            size: const Size(16, 10),
          ),
        ),
      ],
    );
  }
}
