import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class SpendingForecastService {
  static const int _minDataPoints = 2; // Minimum months of data needed

  /// Generate spending forecast using logistic regression
  static SpendingForecastResult generateForecast(
    List<Transaction> transactions,
  ) {
    debugPrint(
      '🔍 SpendingForecast Debug: Starting monthly forecast generation',
    );
    debugPrint('📊 Total transactions: ${transactions.length}');

    if (transactions.isEmpty) {
      debugPrint('❌ No transactions found');
      return SpendingForecastResult.insufficient();
    }

    // Filter and prepare expense data (negative amounts are expenses)
    final expenses =
        transactions
            .where((t) => t.amount < 0)
            .map(
              (t) => t.copyWith(amount: t.amount.abs()),
            ) // Convert to positive
            .toList();

    debugPrint('💸 Expense transactions found: ${expenses.length}');

    if (expenses.length < _minDataPoints) {
      debugPrint(
        '❌ Not enough expense transactions (need at least $_minDataPoints, have ${expenses.length})',
      );
      return SpendingForecastResult.insufficient();
    }

    // Group expenses by month and calculate monthly spending
    final monthlySpending = _groupExpensesByMonth(expenses);
    debugPrint('📅 Unique months with expenses: ${monthlySpending.length}');
    debugPrint(
      '📅 Monthly spending data: ${monthlySpending.entries.map((e) => '${e.key.year}-${e.key.month.toString().padLeft(2, '0')}: \$${e.value.toStringAsFixed(2)}').join(', ')}',
    );

    if (monthlySpending.length < _minDataPoints) {
      debugPrint(
        '❌ Not enough unique months with expenses (need at least $_minDataPoints months, have ${monthlySpending.length})',
      );
      return SpendingForecastResult.insufficient();
    }

    // Generate actual data points for the chart
    final actualData = _generateActualDataPoints(monthlySpending);
    debugPrint(
      '📈 Actual monthly data points: ${actualData.map((d) => d.toStringAsFixed(2)).join(', ')}',
    );

    // Apply logistic regression for prediction
    final predictedData = _applyLogisticRegression(actualData);
    debugPrint(
      '🔮 Predicted monthly data points: ${predictedData.map((d) => d.toStringAsFixed(2)).join(', ')}',
    );

    // Generate category forecasts
    final categoryForecasts = _generateCategoryForecasts(expenses);
    debugPrint(
      '🏷️ Category forecasts: ${categoryForecasts.length} categories',
    );

    debugPrint('✅ Monthly forecast generation successful!');
    return SpendingForecastResult.success(
      actualData: actualData,
      predictedData: predictedData,
      categoryForecasts: categoryForecasts,
    );
  }

  /// Group expenses by month and calculate monthly totals
  static Map<DateTime, double> _groupExpensesByMonth(
    List<Transaction> expenses,
  ) {
    final monthlySpending = <DateTime, double>{};

    for (final expense in expenses) {
      final monthKey = DateTime(
        expense.date.year,
        expense.date.month,
        1, // First day of the month
      );
      monthlySpending[monthKey] =
          (monthlySpending[monthKey] ?? 0) + expense.amount;
    }

    return monthlySpending;
  }

  /// Generate actual data points for visualization
  static List<double> _generateActualDataPoints(
    Map<DateTime, double> monthlySpending,
  ) {
    final sortedMonths = monthlySpending.keys.toList()..sort();

    // Use the last 6 months if available, otherwise use all available months
    final monthsToUse =
        sortedMonths.length >= 6
            ? sortedMonths.sublist(sortedMonths.length - 6)
            : sortedMonths;

    final dataPoints =
        monthsToUse.map((month) => monthlySpending[month] ?? 0).toList();

    // If we have very few data points, pad with zeros to ensure we have at least 3 points for the chart
    while (dataPoints.length < 3 && dataPoints.length < 6) {
      dataPoints.insert(0, 0.0); // Add zeros at the beginning
    }

    debugPrint(
      '📊 Generated ${dataPoints.length} monthly data points from ${sortedMonths.length} months of data',
    );
    return dataPoints;
  }

  /// Apply logistic regression for spending prediction
  static List<double> _applyLogisticRegression(List<double> actualData) {
    if (actualData.isEmpty) return [];

    // Calculate trend and parameters for logistic function
    final trend = _calculateTrend(actualData);
    final lastValue = actualData.last;

    // Find max value safely
    double maxValue = 0.0;
    for (final value in actualData) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    // Logistic regression parameters for monthly data
    final L =
        (maxValue * 1.3 > lastValue * 1.5)
            ? maxValue * 1.3
            : lastValue *
                1.5; // Upper asymptote (more conservative for monthly)
    final k = trend > 0 ? 0.2 : -0.15; // Growth rate (slower for monthly data)
    final x0 = 2.0; // Midpoint (adjusted for monthly predictions)

    // Generate predicted values for next 3 months using logistic function
    final predictedData = <double>[];
    for (int i = 0; i < 3; i++) {
      final x = i.toDouble();
      final logisticValue = L / (1 + math.exp(-k * (x - x0)));

      // Blend with trend-based prediction for more realistic results
      final trendValue = lastValue + (trend * (i + 1));
      final blendedValue = (logisticValue * 0.7) + (trendValue * 0.3);

      // Add some realistic variance (±8% for monthly data)
      final variance =
          blendedValue * 0.08 * (math.Random().nextDouble() - 0.5) * 2;
      final finalValue = blendedValue + variance;
      if (finalValue < 0) {
        predictedData.add(0.0);
      } else {
        predictedData.add(finalValue);
      }
    }

    return predictedData;
  }

  /// Calculate trend from historical data
  static double _calculateTrend(List<double> data) {
    if (data.length < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = data.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i];
      sumXY += i * data[i];
      sumX2 += i * i;
    }

    // Linear regression slope
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Generate category-specific forecasts
  static List<CategoryForecast> _generateCategoryForecasts(
    List<Transaction> expenses,
  ) {
    // Group expenses by category
    final categorySpending = <String, List<double>>{};
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    for (final expense in expenses) {
      final category = expense.categoryName ?? 'Other';
      categorySpending.putIfAbsent(
        category,
        () => [0, 0],
      ); // [thisMonth, lastMonth]

      if (expense.date.isAfter(thisMonth)) {
        categorySpending[category]![0] += expense.amount;
      } else if (expense.date.isAfter(lastMonth) &&
          expense.date.isBefore(thisMonth)) {
        categorySpending[category]![1] += expense.amount;
      }
    }

    // Generate forecasts for top categories
    final forecasts = <CategoryForecast>[];
    final sortedCategories =
        categorySpending.entries.toList()
          ..sort((a, b) => b.value[0].compareTo(a.value[0]));

    final maxCategories =
        sortedCategories.length < 3 ? sortedCategories.length : 3;
    for (int i = 0; i < maxCategories; i++) {
      final entry = sortedCategories[i];
      final categoryName = entry.key;
      final thisMonthSpending = entry.value[0];
      final lastMonthSpending = entry.value[1];

      // Simple forecast based on trend
      final change =
          lastMonthSpending > 0
              ? ((thisMonthSpending - lastMonthSpending) / lastMonthSpending)
              : 0.1; // Default to 10% increase if no last month data

      double changeConstrained = change;
      if (changeConstrained < -0.5) changeConstrained = -0.5;
      if (changeConstrained > 0.5) changeConstrained = 0.5;

      final forecastAmount = thisMonthSpending * (1 + changeConstrained);
      final changePercent =
          ((forecastAmount - thisMonthSpending) / thisMonthSpending) * 100;

      forecasts.add(
        CategoryForecast(
          category: categoryName,
          current: thisMonthSpending,
          forecast: forecastAmount,
          changePercent: changePercent,
        ),
      );
    }

    return forecasts;
  }
}

/// Result of spending forecast analysis
class SpendingForecastResult {
  final bool isSuccess;
  final List<double> actualData;
  final List<double> predictedData;
  final List<CategoryForecast> categoryForecasts;
  final String? errorMessage;

  const SpendingForecastResult({
    required this.isSuccess,
    required this.actualData,
    required this.predictedData,
    required this.categoryForecasts,
    this.errorMessage,
  });

  factory SpendingForecastResult.success({
    required List<double> actualData,
    required List<double> predictedData,
    required List<CategoryForecast> categoryForecasts,
  }) {
    return SpendingForecastResult(
      isSuccess: true,
      actualData: actualData,
      predictedData: predictedData,
      categoryForecasts: categoryForecasts,
    );
  }

  factory SpendingForecastResult.insufficient() {
    return const SpendingForecastResult(
      isSuccess: false,
      actualData: [],
      predictedData: [],
      categoryForecasts: [],
      errorMessage: 'Insufficient data for forecast',
    );
  }

  factory SpendingForecastResult.error(String message) {
    return SpendingForecastResult(
      isSuccess: false,
      actualData: [],
      predictedData: [],
      categoryForecasts: [],
      errorMessage: message,
    );
  }
}

/// Category-specific forecast data
class CategoryForecast {
  final String category;
  final double current;
  final double forecast;
  final double changePercent;

  const CategoryForecast({
    required this.category,
    required this.current,
    required this.forecast,
    required this.changePercent,
  });

  bool get isIncrease => changePercent > 0;
}
