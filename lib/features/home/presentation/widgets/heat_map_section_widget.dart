import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';

class HeatMapSectionWidget extends StatelessWidget {
  const HeatMapSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        // Calculate heat map data from real transactions
        final heatMapData = _calculateHeatMapData(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('home_cash_flow_activity'),
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
                  // Header with date range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('home_last_180_days'),
                        style: textTheme.titleMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? AppColors.surface : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMM d').format(heatMapData.startDate),
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                            Text(
                              ' - ',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d').format(heatMapData.endDate),
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Heat map grid
                  SizedBox(
                    height: 140,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      reverse: true, // Latest dates on the right
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildHeatMapColumns(heatMapData, isDarkMode),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Simple legend without "Less/More" text
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // No activity
                        _buildLegendCell(
                          isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                          isDarkMode,
                        ),
                        const SizedBox(width: 2),
                        // Low positive
                        _buildLegendCell(
                          AppColors.income.withValues(alpha: 0.3),
                          isDarkMode,
                        ),
                        const SizedBox(width: 2),
                        // Medium positive
                        _buildLegendCell(
                          AppColors.income.withValues(alpha: 0.6),
                          isDarkMode,
                        ),
                        const SizedBox(width: 2),
                        // High positive
                        _buildLegendCell(
                          AppColors.income.withValues(alpha: 0.9),
                          isDarkMode,
                        ),
                        const SizedBox(width: 8),
                        // Low negative
                        _buildLegendCell(
                          AppColors.expense.withValues(alpha: 0.3),
                          isDarkMode,
                        ),
                        const SizedBox(width: 2),
                        // Medium negative
                        _buildLegendCell(
                          AppColors.expense.withValues(alpha: 0.6),
                          isDarkMode,
                        ),
                        const SizedBox(width: 2),
                        // High negative
                        _buildLegendCell(
                          AppColors.expense.withValues(alpha: 0.9),
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  HeatMapData _calculateHeatMapData(TransactionState state) {
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(
      const Duration(days: 179),
    ); // 180 days total

    // Initialize daily balance changes map
    final Map<DateTime, double> dailyBalanceChanges = {};

    if (state is TransactionsLoaded) {
      // Group transactions by date and calculate daily balance changes
      for (final transaction in state.transactions) {
        // Convert to local date only (ignore time and timezone)
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        // Create normalized start and end dates for comparison
        final normalizedStartDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final normalizedToday = DateTime(today.year, today.month, today.day);

        // Check if date is within range (inclusive)
        if ((date.isAfter(normalizedStartDate) ||
                date.isAtSameMomentAs(normalizedStartDate)) &&
            (date.isBefore(normalizedToday) ||
                date.isAtSameMomentAs(normalizedToday))) {
          final previousAmount = dailyBalanceChanges[date] ?? 0;
          dailyBalanceChanges[date] = previousAmount + transaction.amount;
        }
      }
    }

    // Create exactly 180 cells
    final List<HeatMapCell> cells = [];
    for (int i = 0; i < 180; i++) {
      final date = startDate.add(Duration(days: i));
      // Normalize to date only (no time component)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final balanceChange = dailyBalanceChanges[normalizedDate] ?? 0.0;
      cells.add(
        HeatMapCell(date: normalizedDate, balanceChange: balanceChange),
      );
    }

    return HeatMapData(startDate: startDate, endDate: today, cells: cells);
  }

  List<Widget> _buildHeatMapColumns(HeatMapData data, bool isDarkMode) {
    final List<Widget> columns = [];
    final DateTime firstDate = data.startDate;

    // Calculate the starting weekday (0 = Monday, 6 = Sunday)
    final int startWeekday = firstDate.weekday - 1;

    // Calculate number of weeks needed
    final int totalWeeks = ((180 + startWeekday) / 7).ceil();

    int cellIndex = 0;

    for (int week = 0; week < totalWeeks; week++) {
      final List<Widget> weekCells = [];

      // Add month label for first week of each month
      String? monthLabel;
      if (week == 0 || (week > 0 && cellIndex < data.cells.length)) {
        final currentDate =
            cellIndex < data.cells.length
                ? data.cells[cellIndex].date
                : data.endDate;
        final prevWeekDate =
            week > 0 && cellIndex >= 7 ? data.cells[cellIndex - 7].date : null;

        if (week == 0 ||
            (prevWeekDate != null && currentDate.month != prevWeekDate.month)) {
          monthLabel = DateFormat('MMM').format(currentDate);
        }
      }

      // Build 7 cells for each weekday
      for (int weekday = 0; weekday < 7; weekday++) {
        Widget cell;

        if (week == 0 && weekday < startWeekday) {
          // Empty cell before the first date
          cell = Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.all(1),
          );
        } else if (cellIndex >= data.cells.length) {
          // Empty cell after the last date
          cell = Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.all(1),
          );
        } else {
          // Actual data cell
          final cellData = data.cells[cellIndex];
          cell = _buildHeatMapCell(cellData, isDarkMode);
          cellIndex++;
        }

        weekCells.add(cell);
      }

      columns.add(
        Container(
          width: 16, // Fixed width for all columns
          margin: const EdgeInsets.symmetric(
            horizontal: 1,
          ), // Consistent spacing
          child: Column(
            children: [
              // Month label with fixed height
              SizedBox(
                height: 12,
                child:
                    monthLabel != null
                        ? Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        )
                        : null,
              ),
              // Week cells
              ...weekCells,
            ],
          ),
        ),
      );
    }

    return columns;
  }

  Widget _buildHeatMapCell(HeatMapCell cellData, bool isDarkMode) {
    final Color cellColor = _getCellColor(cellData.balanceChange, isDarkMode);
    final DateTime today = DateTime.now();
    final bool isToday =
        cellData.date.year == today.year &&
        cellData.date.month == today.month &&
        cellData.date.day == today.day;

    return Tooltip(
      message: _buildTooltipMessage(cellData),
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(2),
          border:
              isToday
                  ? Border.all(
                    color: isDarkMode ? Colors.white : Colors.black,
                    width: 1.5,
                  )
                  : null,
        ),
      ),
    );
  }

  Color _getCellColor(double balanceChange, bool isDarkMode) {
    if (balanceChange == 0) {
      // No activity
      return isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    }

    final double absChange = balanceChange.abs();
    final bool isPositive = balanceChange > 0;

    // Define intensity levels based on amount
    double intensity;
    if (absChange < 50) {
      intensity = 0.3; // Low
    } else if (absChange < 200) {
      intensity = 0.6; // Medium
    } else {
      intensity = 0.9; // High
    }

    return isPositive
        ? AppColors.income.withValues(alpha: intensity)
        : AppColors.expense.withValues(alpha: intensity);
  }

  String _buildTooltipMessage(HeatMapCell cellData) {
    final String dateStr = DateFormat('MMM d, yyyy').format(cellData.date);

    if (cellData.balanceChange == 0) {
      return '$dateStr\nNo transactions';
    }

    final bool isPositive = cellData.balanceChange > 0;
    final String changeStr = Formatters.formatCurrency(
      cellData.balanceChange.abs(),
    );

    return '$dateStr\n${isPositive ? "Net Income" : "Net Expense"}: ${isPositive ? "+" : "-"}$changeStr';
  }

  Widget _buildLegendCell(Color color, bool isDarkMode) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class HeatMapData {
  final DateTime startDate;
  final DateTime endDate;
  final List<HeatMapCell> cells;

  HeatMapData({
    required this.startDate,
    required this.endDate,
    required this.cells,
  });
}

class HeatMapCell {
  final DateTime date;
  final double balanceChange;

  HeatMapCell({required this.date, required this.balanceChange});
}
