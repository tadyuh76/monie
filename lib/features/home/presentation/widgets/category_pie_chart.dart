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

  const CategoryPieChart({
    super.key,
    required this.isExpense,
    required this.totalAmount,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    // Colors for the indicator triangle
    final indicatorColor =
        isExpense
            ? const Color(0xFFEF5350) // Red for expense
            : const Color(0xFF66BB6A); // Green for income

    // Title text
    final titleText = isExpense ? 'Expenses' : 'Income';

    // Color for the total amount
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

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
                  categories.map((category) {
                    return PieChartSectionData(
                      color: category['color'],
                      value: category['value'],
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
              style: const TextStyle(
                color: Colors.white,
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
        ...List.generate(categories.length, (index) {
          // Calculate the middle angle of each pie section in radians
          double totalValue = categories.fold(
            0.0,
            (sum, item) => sum + item['value'],
          );

          // Calculate the starting and ending angles for each category
          double startAngle = 270.0; // Start from the top
          for (int i = 0; i < index; i++) {
            startAngle += (categories[i]['value'] / totalValue) * 360.0;
          }

          // Calculate the middle angle of this section
          double middleAngle =
              startAngle + (categories[index]['value'] / totalValue) * 180.0;

          // Convert to radians
          double middleAngleRadians = middleAngle * (3.14159 / 180);

          // Position at the edge of the chart with some padding
          final radius = 110;
          final x = radius * cos(middleAngleRadians);
          final y = radius * sin(middleAngleRadians);

          return Positioned(
            left: 170 + x - 16, // Center + offset - half icon size (16)
            top: 170 + y - 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categories[index]['color'],
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                categories[index]['icon'],
                // Special case for yellow category (typically investments)
                color:
                    categories[index]['color'] == const Color(0xFFFFD54F)
                        ? Colors.black87
                        : Colors.white,
                size: 16,
              ),
            ),
          );
        }),

        // Legend at the bottom
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: categories[index]['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${categories[index]['name']} (${categories[index]['value'].toInt()}%)',
                        style: const TextStyle(
                          color: Colors.white70,
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
