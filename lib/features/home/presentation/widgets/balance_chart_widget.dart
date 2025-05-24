import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class BalanceChartWidget extends StatefulWidget {
  final List<Transaction> transactions;
  final int daysToShow;

  const BalanceChartWidget({
    super.key,
    required this.transactions,
    this.daysToShow = 30,
  });

  @override
  State<BalanceChartWidget> createState() => _BalanceChartWidgetState();
}

class _BalanceChartWidgetState extends State<BalanceChartWidget> {
  static const int _visibleDays = 12; // Show 12 days at a time
  double _scrollOffset = 0.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    try {
      // Filter transactions for the last X days
      final DateTime today = DateTime.now();
      final DateTime startDate = today.subtract(
        Duration(days: widget.daysToShow),
      );
      final filteredTransactions =
          widget.transactions
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
      final List<DateTime> dateRange = List.generate(widget.daysToShow + 1, (
        index,
      ) {
        return DateTime(startDate.year, startDate.month, startDate.day + index);
      });

      // Calculate cumulative balance and optimize data points
      double cumulativeBalance = 0;
      final List<FlSpot> allBalanceSpots = [];
      final List<DateTime> allDates = [];

      for (int i = 0; i < dateRange.length; i++) {
        final date = dateRange[i];
        final transactions = groupedTransactions[date] ?? [];

        double dailyBalance = transactions.fold(
          0.0,
          (sum, transaction) => sum + transaction.amount,
        );

        cumulativeBalance += dailyBalance;

        // Only add points when balance changes or at key intervals
        if (allBalanceSpots.isEmpty ||
            allBalanceSpots.last.y != cumulativeBalance ||
            i == dateRange.length - 1 ||
            i % 3 == 0) {
          // Add point every 3 days to maintain chart shape
          allBalanceSpots.add(
            FlSpot(allBalanceSpots.length.toDouble(), cumulativeBalance),
          );
          allDates.add(date);
        }
      }

      // Calculate visible range
      final int maxStartIndex = (allBalanceSpots.length - _visibleDays).clamp(
        0,
        allBalanceSpots.length,
      );
      final int startIndex = (_scrollOffset * maxStartIndex / 100)
          .round()
          .clamp(0, maxStartIndex);
      final int endIndex = (startIndex + _visibleDays).clamp(
        _visibleDays,
        allBalanceSpots.length,
      );

      // Get visible data points
      final List<FlSpot> visibleSpots = [];
      final List<DateTime> visibleDates = [];

      for (
        int i = startIndex;
        i < endIndex && i < allBalanceSpots.length;
        i++
      ) {
        visibleSpots.add(
          FlSpot((i - startIndex).toDouble(), allBalanceSpots[i].y),
        );
        if (i < allDates.length) {
          visibleDates.add(allDates[i]);
        }
      }

      // Find minimum and maximum values for scaling
      double minY =
          visibleSpots.isEmpty
              ? -100
              : visibleSpots
                  .map((spot) => spot.y)
                  .reduce((a, b) => a < b ? a : b);
      double maxY =
          visibleSpots.isEmpty
              ? 100
              : visibleSpots
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
          visibleDates.map((date) => DateFormat('MMM d').format(date)).toList();

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
                          color: Colors.black.withValues(alpha: 0.05),
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
                const SizedBox(height: 16),

                // Scroll indicator
                if (allBalanceSpots.length > _visibleDays) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.swipe_left,
                        size: 16,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Swipe to see more data',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${startIndex + 1}-$endIndex of ${allBalanceSpots.length} points',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Chart with horizontal scroll
                SizedBox(
                  height: 220,
                  child:
                      widget.transactions.isEmpty
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
                          : GestureDetector(
                            onPanUpdate: (details) {
                              if (allBalanceSpots.length > _visibleDays) {
                                setState(() {
                                  _scrollOffset = (_scrollOffset -
                                          details.delta.dx * 2)
                                      .clamp(0.0, 100.0);
                                });
                              }
                            },
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: safeInterval,
                                  verticalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    // Highlight the zero line with a more prominent style
                                    if (value == 0) {
                                      return FlLine(
                                        color:
                                            isDarkMode
                                                ? Colors.white.withValues(
                                                  alpha: 0.3,
                                                )
                                                : Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                        strokeWidth: 1.5,
                                        dashArray: [8, 4],
                                      );
                                    }
                                    // Make other grid lines more subtle
                                    return FlLine(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                      strokeWidth: 0.8,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                      strokeWidth: 0.8,
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
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final int index = value.toInt();
                                        if (index >= 0 &&
                                            index < dateLabels.length) {
                                          // Show every 2nd or 3rd label to avoid crowding
                                          if (index % 2 == 0 ||
                                              index == dateLabels.length - 1) {
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
                                maxX: (visibleSpots.length - 1).toDouble(),
                                minY: minY,
                                maxY: maxY,
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBorderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    getTooltipItems: (touchedSpots) {
                                      if (touchedSpots.isEmpty) return [];
                                      final spot = touchedSpots.first;
                                      final int index = spot.x.toInt();
                                      if (index >= 0 &&
                                          index < visibleDates.length) {
                                        final DateTime date =
                                            visibleDates[index];
                                        final bool isPositive = spot.y >= 0;
                                        return [
                                          LineTooltipItem(
                                            '${DateFormat.yMMMd().format(date)}\n',
                                            TextStyle(
                                              color:
                                                  isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: Formatters.formatCurrency(
                                                  spot.y,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      isPositive
                                                          ? AppColors.income
                                                          : AppColors.expense,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ];
                                      }
                                      return [];
                                    },
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: visibleSpots,
                                    isCurved: true,
                                    curveSmoothness: 0.3,
                                    preventCurveOverShooting: true,
                                    color:
                                        cumulativeBalance >= 0
                                            ? AppColors.primary
                                            : AppColors.expense,
                                    barWidth: 3.5,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (
                                        spot,
                                        percent,
                                        barData,
                                        index,
                                      ) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor:
                                              cumulativeBalance >= 0
                                                  ? AppColors.primary
                                                  : AppColors.expense,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      cutOffY: 0,
                                      applyCutOffY: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors:
                                            cumulativeBalance >= 0
                                                ? [
                                                  AppColors.primary.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  AppColors.primary.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                  AppColors.primary.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  AppColors.primary.withValues(
                                                    alpha: 0.05,
                                                  ),
                                                  Colors.transparent,
                                                ]
                                                : [
                                                  AppColors.expense.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  AppColors.expense.withValues(
                                                    alpha: 0.25,
                                                  ),
                                                  AppColors.expense.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  AppColors.expense.withValues(
                                                    alpha: 0.05,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                                      ),
                                    ),
                                    aboveBarData: BarAreaData(
                                      show: cumulativeBalance < 0,
                                      cutOffY: 0,
                                      applyCutOffY: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.expense.withValues(
                                            alpha: 0.4,
                                          ),
                                          AppColors.expense.withValues(
                                            alpha: 0.25,
                                          ),
                                          AppColors.expense.withValues(
                                            alpha: 0.1,
                                          ),
                                          AppColors.expense.withValues(
                                            alpha: 0.05,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                          color: Colors.black.withValues(alpha: 0.05),
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
