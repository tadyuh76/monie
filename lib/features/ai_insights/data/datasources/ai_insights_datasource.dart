import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/services/gemini_service.dart';
import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Data source for AI insights using Gemini
class AIInsightsDataSource {
  final GeminiService _geminiService;

  AIInsightsDataSource(this._geminiService);

  Future<SpendingPattern> analyzeSpendingPatterns({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    debugPrint('🤖 AIInsightsDataSource: Analyzing spending patterns...');

    // Calculate spending metrics
    final expenses = transactions.where((t) => t.amount < 0).toList();
    final income = transactions.where((t) => t.amount > 0).toList();

    final totalSpending = expenses.fold<double>(
      0,
      (sum, t) => sum + t.amount.abs(),
    );

    final totalIncome = income.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final days = endDate.difference(startDate).inDays;
    final avgDailySpending = days > 0 ? totalSpending / days : totalSpending;

    // Calculate savings rate
    final savingsRate = totalIncome > 0
        ? (totalIncome - totalSpending) / totalIncome
        : 0.0;

    // Build category breakdown
    final categoryBreakdown = <String, double>{};
    for (final expense in expenses) {
      final category = expense.categoryName ?? 'Other';
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + expense.amount.abs();
    }

    // Calculate category percentages
    final categoryWithPercentage = <String, CategorySpending>{};
    categoryBreakdown.forEach((category, amount) {
      categoryWithPercentage[category] = CategorySpending(
        amount: amount,
        percentage: totalSpending > 0 ? (amount / totalSpending) * 100 : 0,
      );
    });

    // Find peak spending day
    final daySpending = <int, double>{};
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      daySpending[weekday] = (daySpending[weekday] ?? 0) + expense.amount.abs();
    }
    final peakDay = daySpending.entries.isNotEmpty
        ? daySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 1;
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final peakSpendingDay = dayNames[peakDay - 1];

    // Find peak spending hour
    final hourSpending = <int, double>{};
    for (final expense in expenses) {
      final hour = expense.date.hour;
      hourSpending[hour] = (hourSpending[hour] ?? 0) + expense.amount.abs();
    }
    final peakHour = hourSpending.entries.isNotEmpty
        ? hourSpending.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 12;
    final peakSpendingHour = '${peakHour.toString().padLeft(2, '0')}:00';

    // Call Gemini API
    final dateFormat = DateFormat('yyyy-MM-dd');
    final result = await _geminiService.analyzeSpendingPatterns(
      startDate: dateFormat.format(startDate),
      endDate: dateFormat.format(endDate),
      totalSpending: totalSpending,
      avgDailySpending: avgDailySpending,
      transactionCount: transactions.length,
      categoryBreakdown: categoryBreakdown,
      totalIncome: totalIncome,
      savingsRate: savingsRate,
    );

    if (result == null) {
      debugPrint('❌ AIInsightsDataSource: Failed to get AI response');
      // Return default pattern if AI fails
      return _buildDefaultPattern(
        categoryBreakdown: categoryBreakdown,
        categoryWithPercentage: categoryWithPercentage,
        totalSpending: totalSpending,
        totalIncome: totalIncome,
        avgDailySpending: avgDailySpending,
        peakSpendingDay: peakSpendingDay,
        peakSpendingHour: peakSpendingHour,
        startDate: startDate,
        endDate: endDate,
      );
    }

    debugPrint('✅ AIInsightsDataSource: Analysis complete');
    
    // Parse AI response and add calculated fields
    final pattern = SpendingPattern.fromJson(result);
    return pattern.copyWith(
      totalSpending: totalSpending,
      dailyAverage: avgDailySpending,
      peakSpendingDay: peakSpendingDay,
      peakSpendingHour: peakSpendingHour,
      periodStart: startDate,
      periodEnd: endDate,
      categoryBreakdown: categoryWithPercentage,
      aiSummary: result['aiSummary'] ?? result['summary'],
    );
  }

  SpendingPattern _buildDefaultPattern({
    required Map<String, double> categoryBreakdown,
    required Map<String, CategorySpending> categoryWithPercentage,
    required double totalSpending,
    required double totalIncome,
    required double avgDailySpending,
    required String peakSpendingDay,
    required String peakSpendingHour,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Find top category
    String topCategory = 'General';
    double maxAmount = 0;
    categoryBreakdown.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    // Calculate basic health score
    final savingsRate = totalIncome > 0
        ? (totalIncome - totalSpending) / totalIncome
        : 0.0;
    final healthScore = (savingsRate * 100).clamp(0, 100).toInt();

    return SpendingPattern(
      summary: 'Based on your recent transactions, you spent \$${totalSpending.toStringAsFixed(2)} across ${categoryBreakdown.length} categories.',
      topCategory: topCategory,
      spendingTrend: SpendingTrend.stable,
      unusualPatterns: [],
      recommendations: [
        'Track your spending regularly',
        'Set budgets for top categories',
        'Review subscriptions monthly',
      ],
      financialHealthScore: healthScore,
      insights: SpendingInsights(
        bestPerformingArea: 'Consistent tracking',
        areasForImprovement: ['Budget adherence', 'Emergency savings'],
        seasonalObservations: 'Continue monitoring your spending patterns.',
      ),
      analyzedAt: DateTime.now(),
      totalSpending: totalSpending,
      dailyAverage: avgDailySpending,
      peakSpendingDay: peakSpendingDay,
      peakSpendingHour: peakSpendingHour,
      periodStart: startDate,
      periodEnd: endDate,
      categoryBreakdown: categoryWithPercentage,
    );
  }
}
