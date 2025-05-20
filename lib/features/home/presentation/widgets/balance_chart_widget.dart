import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class BalanceChartWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final int daysToShow;

  const BalanceChartWidget({
    super.key,
    required this.transactions,
    this.daysToShow = 30,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    try {
      // Filter transactions for the last X days
      final DateTime today = DateTime.now();
      final DateTime startDate = today.subtract(Duration(days: daysToShow));
      final filteredTransactions =
          transactions
              .where(
                (t) =>
                    t.date.isAfter(startDate) ||
                    t.date.isAtSameMomentAs(startDate),
              )
              .toList();

      // Group transactions by date
      final Map<DateTime, List<Transaction>> groupedTransactions = {};
      for (var transaction in filteredTransactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        if (!groupedTransactions.containsKey(date)) {
          groupedTransactions[date] = [];
        }
        groupedTransactions[date]!.add(transaction);
      }

      // Generate a list of all dates in the range
      final List<DateTime> dateRange = List.generate(daysToShow + 1, (index) {
        return DateTime(startDate.year, startDate.month, startDate.day + index);
      });

      // Calculate cumulative balance
      double cumulativeBalance = 0;
      final List<FlSpot> balanceSpots = [];

      for (int i = 0; i < dateRange.length; i++) {
        final date = dateRange[i];
        final transactions = groupedTransactions[date] ?? [];

        double dailyBalance = transactions.fold(
          0.0,
          (sum, transaction) => sum + transaction.amount,
        );

        cumulativeBalance += dailyBalance;
        balanceSpots.add(FlSpot(i.toDouble(), cumulativeBalance));
      }

      // Special handling for cases where the first transaction is an expense
      if (balanceSpots.isNotEmpty && balanceSpots.length > 1) {
        // If first non-zero balance is negative, add an extra point with same value to prevent spike
        int firstNonZeroIndex = balanceSpots.indexWhere((spot) => spot.y != 0);
        if (firstNonZeroIndex > 0 && balanceSpots[firstNonZeroIndex].y < 0) {
          // Replace the point just before the drop with the same negative value
          balanceSpots[firstNonZeroIndex - 1] = FlSpot(
            balanceSpots[firstNonZeroIndex - 1].x,
            balanceSpots[firstNonZeroIndex].y,
          );
        }
      }

      // Find minimum and maximum values for scaling
      double minY =
          balanceSpots.isEmpty
              ? -100
              : balanceSpots
                  .map((spot) => spot.y)
                  .reduce((a, b) => a < b ? a : b);
      double maxY =
          balanceSpots.isEmpty
              ? 100
              : balanceSpots
                  .map((spot) => spot.y)
                  .reduce((a, b) => a > b ? a : b);

      // Add padding to minY and maxY
      minY = minY * 1.1; // Add 10% padding below
      maxY = maxY * 1.1; // Add 10% padding above

      // Ensure zero is always visible in the chart
      if (minY > 0) minY = 0;
      if (maxY < 0) maxY = 0;

      // Ensure we have a non-zero range for the grid
      if (maxY == minY) {
        maxY = minY + 100;
      }

      // Calculate a safe interval that won't be zero
      final double gridInterval = (maxY - minY) / 5;
      final double safeInterval = gridInterval <= 0 ? 20 : gridInterval;

      // Format dates for x-axis
      List<String> dateLabels =
          dateRange.map((date) => DateFormat('d').format(date)).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('home_balance_trend'),
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date range and current balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('home_last_30_days_activity'),
                      style: textTheme.titleMedium?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(cumulativeBalance),
                      style: textTheme.titleLarge?.copyWith(
                        color:
                            cumulativeBalance >= 0
                                ? AppColors.income
                                : AppColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart
                SizedBox(
                  height: 220,
                  child:
                      transactions.isEmpty
                          ? Center(
                            child: Text(
                              context.tr('home_no_transactions_to_show'),
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                          )
                          : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: safeInterval,
                                verticalInterval: 7,
                                getDrawingHorizontalLine: (value) {
                                  // Highlight the zero line
                                  if (value == 0) {
                                    return FlLine(
                                      color:
                                          isDarkMode
                                              ? Colors.white24
                                              : Colors.black26,
                                      strokeWidth: 2,
                                      dashArray: [5, 5],
                                    );
                                  }
                                  return FlLine(
                                    color:
                                        isDarkMode
                                            ? Colors.white10
                                            : Colors.black12,
                                    strokeWidth: 1,
                                  );
                                },
                                getDrawingVerticalLine: (value) {
                                  return FlLine(
                                    color:
                                        isDarkMode
                                            ? Colors.white10
                                            : Colors.black12,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 7,
                                    getTitlesWidget: (value, meta) {
                                      // Show only weekly labels
                                      if (value.toInt() % 7 != 0 &&
                                          value.toInt() !=
                                              dateRange.length - 1) {
                                        return const SizedBox();
                                      }

                                      final int index = value.toInt();
                                      if (index >= 0 &&
                                          index < dateLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            dateLabels[index],
                                            style: TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: (maxY - minY) / 5,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        _formatCompactCurrency(value),
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: dateRange.length.toDouble() - 1,
                              minY: minY,
                              maxY: maxY,
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBorderRadius: BorderRadius.circular(8),
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  getTooltipItems: (touchedSpots) {
                                    if (touchedSpots.isEmpty) return [];
                                    final spot = touchedSpots.first;
                                    final int index = spot.x.toInt();
                                    final DateTime date = dateRange[index];
                                    return [
                                      LineTooltipItem(
                                        '${DateFormat.yMMMd().format(date)}\n${Formatters.formatCurrency(spot.y)}',
                                        TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: balanceSpots,
                                  isCurved: true,
                                  curveSmoothness: 0.2,
                                  preventCurveOverShooting: true,
                                  color: AppColors.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary.withOpacity(0.2),
                                    cutOffY: 0,
                                    applyCutOffY: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.2),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      // If there's any error during chart calculation or rendering,
      // display a fallback message
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('home_balance_trend'),
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Could not display chart. Please try again later.",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  // Helper method for compact currency formatting
  String _formatCompactCurrency(double value) {
    // Handle negative values
    bool isNegative = value < 0;
    double absValue = value.abs();
    String prefix = isNegative ? '-\$' : '\$';

    if (absValue == 0) return '\$0';

    if (absValue < 1000) {
      return '$prefix${absValue.toInt()}';
    } else if (absValue < 1000000) {
      return '$prefix${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      return '$prefix${(absValue / 1000000).toStringAsFixed(1)}M';
    }
  }
}
