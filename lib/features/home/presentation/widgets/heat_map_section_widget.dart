import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';

class HeatMapSectionWidget extends StatelessWidget {
  const HeatMapSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Create a list of the last 180 days (ending today)
    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(180, (index) {
      return today.subtract(Duration(days: 179 - index));
    });

    // Generate mock transaction data for the days
    final Map<DateTime, double> dailyCashFlow = {};
    final Random random = Random(42); // Seed for consistent random numbers

    // Create patterns for the mock data
    for (final day in days) {
      // Skip some days (no transactions)
      if (random.nextDouble() > 0.7) {
        continue;
      }

      // Generate cash flow (-100 to +100)
      final double cashFlow = (random.nextDouble() * 200) - 100;
      dailyCashFlow[day] = cashFlow;
    }

    // Add some specific patterns
    // Weekend pattern - more expenses
    for (final day in days) {
      if (day.weekday >= 6 &&
          !dailyCashFlow.containsKey(day) &&
          random.nextDouble() > 0.3) {
        dailyCashFlow[day] = -(random.nextDouble() * 60 + 20); // -20 to -80
      }
    }

    // Beginning of month - income
    for (final day in days) {
      if (day.day <= 3 &&
          !dailyCashFlow.containsKey(day) &&
          random.nextDouble() > 0.4) {
        dailyCashFlow[day] = random.nextDouble() * 80 + 40; // +40 to +120
      }
    }

    // Create specific data points
    dailyCashFlow[today.subtract(const Duration(days: 1))] = -65;
    dailyCashFlow[today] = 50;
    dailyCashFlow[today.subtract(const Duration(days: 7))] = 120;
    dailyCashFlow[today.subtract(const Duration(days: 15))] = -85;

    // Group by weekday to organize into columns (0 = Monday, 6 = Sunday)
    final List<List<MapEntry<DateTime, double?>>> columns = [];

    // Calculate how many weeks to display (180 days ÷ 7 ≈ 25.7 weeks)
    final int weeksCount = (days.length / 7).ceil();

    // Create columns grouped by weekday
    for (int week = 0; week < weeksCount; week++) {
      final List<MapEntry<DateTime, double?>> column = List.generate(7, (
        weekday,
      ) {
        final int dayIndex = week * 7 + weekday;
        if (dayIndex >= days.length) {
          return MapEntry(today, null); // Padding
        }

        final DateTime date = days[dayIndex];
        final double? cashFlow = dailyCashFlow[date];
        return MapEntry(date, cashFlow);
      });

      columns.add(column);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Flow Activity',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 180 Days',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMM d').format(days.first),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          ' - ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          DateFormat('MMM d').format(days.last),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Heatmap - horizontally scrollable
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  reverse: true, // Latest dates (today) on the right
                  child: Row(
                    children:
                        columns.map((column) {
                          return Container(
                            width: 16, // Column width
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children:
                                  column.map((entry) {
                                    final date = entry.key;
                                    final cashFlow = entry.value;

                                    // Cell color based on cash flow
                                    Color cellColor;
                                    if (cashFlow == null) {
                                      // No transaction
                                      cellColor = AppColors.textSecondary
                                          .withValues(alpha: 0.1);
                                    } else if (cashFlow > 0) {
                                      // Positive cash flow (green)
                                      final intensity = min(
                                        0.9,
                                        (cashFlow / 100),
                                      );
                                      cellColor = const Color(
                                        0xFF66BB6A,
                                      ).withValues(
                                        alpha: 0.3 + (intensity * 0.6),
                                      );
                                    } else {
                                      // Negative cash flow (red)
                                      final intensity = min(
                                        0.9,
                                        (-cashFlow / 100),
                                      );
                                      cellColor = const Color(
                                        0xFFEF5350,
                                      ).withValues(
                                        alpha: 0.3 + (intensity * 0.6),
                                      );
                                    }

                                    // Tooltip content
                                    String tooltip = Formatters.formatShortDate(
                                      date,
                                    );
                                    if (cashFlow != null) {
                                      final isPositive = cashFlow > 0;
                                      final formattedAmount =
                                          Formatters.formatCurrency(
                                            cashFlow.abs(),
                                          );
                                      tooltip +=
                                          '\n${isPositive ? "Income" : "Expense"}: ';
                                      tooltip +=
                                          isPositive
                                              ? '+$formattedAmount'
                                              : '-$formattedAmount';
                                    } else {
                                      tooltip += '\nNo transactions';
                                    }

                                    // Special background for today's cell
                                    Color backgroundColor = cellColor;
                                    if (date.year == today.year &&
                                        date.month == today.month &&
                                        date.day == today.day) {
                                      backgroundColor = Colors.white.withValues(
                                        alpha: 0.15,
                                      );
                                    }

                                    return Expanded(
                                      child: Tooltip(
                                        message: tooltip,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          child:
                                              cashFlow != null &&
                                                      cashFlow.abs() > 50
                                                  ? Center(
                                                    child: Icon(
                                                      cashFlow > 0
                                                          ? Icons.arrow_upward
                                                          : Icons
                                                              .arrow_downward,
                                                      color: Colors.white,
                                                      size: 8,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Legend
              Row(
                children: [
                  // Left column with red and blue legends
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem(
                          const Color(0xFF66BB6A).withValues(alpha: 0.7),
                          'Income > Expense',
                          textTheme,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          const Color(0xFFEF5350).withValues(alpha: 0.7),
                          'Expense > Income',
                          textTheme,
                        ),
                      ],
                    ),
                  ),
                  // Right column with no activity legend
                  Expanded(
                    child: _buildLegendItem(
                      AppColors.textSecondary.withValues(alpha: 0.1),
                      'No Activity',
                      textTheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build legend items
  Widget _buildLegendItem(Color color, String text, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontSize: 10, // Smaller font size
          ),
        ),
      ],
    );
  }
}
