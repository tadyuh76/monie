import 'package:flutter/foundation.dart';
import 'package:monie/core/services/gemini_service.dart';
import 'package:monie/features/predictions/domain/entities/spending_prediction.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Data source for spending predictions
class PredictionDataSource {
  final GeminiService _geminiService;

  PredictionDataSource(this._geminiService);

  Future<SpendingPrediction> predictSpending({
    required List<Transaction> transactions,
    required String period,
  }) async {
    debugPrint('🔮 PredictionDataSource: Generating prediction...');
    debugPrint('🔮 PredictionDataSource: Total transactions: ${transactions.length}');

    // Build historical data by month
    final monthlyData = _buildMonthlyData(transactions);
    final categoryTrends = _buildCategoryTrends(transactions);

    debugPrint('🔮 PredictionDataSource: Monthly data points: ${monthlyData.length}');
    debugPrint('🔮 PredictionDataSource: Monthly data: $monthlyData');

    // If not enough monthly data, still generate a basic prediction
    if (monthlyData.isEmpty) {
      debugPrint('⚠️ PredictionDataSource: No monthly data, using default');
      return _buildDefaultPrediction(transactions);
    }

    // Call Gemini for prediction
    final result = await _geminiService.predictSpending(
      historicalData: monthlyData,
      period: period,
      categoryTrends: categoryTrends,
    );

    if (result == null) {
      debugPrint('⚠️ PredictionDataSource: AI prediction failed, using default');
      return _buildDefaultPrediction(transactions);
    }

    debugPrint('✅ PredictionDataSource: Prediction complete');
    return SpendingPrediction.fromJson(result);
  }

  List<Map<String, dynamic>> _buildMonthlyData(List<Transaction> transactions) {
    final monthlyTotals = <String, double>{};

    // Try to find expenses - could be negative OR positive amounts
    // First check if we have negative amounts (standard expense representation)
    final negativeAmounts = transactions.where((t) => t.amount < 0).toList();
    final positiveAmounts = transactions.where((t) => t.amount > 0).toList();
    
    debugPrint('🔮 _buildMonthlyData: Negative amounts: ${negativeAmounts.length}, Positive amounts: ${positiveAmounts.length}');
    
    // Use all transactions for now - amounts will be treated as spending
    for (final t in transactions) {
      final monthKey =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      // Use absolute value to handle both positive and negative amounts
      monthlyTotals[monthKey] =
          (monthlyTotals[monthKey] ?? 0) + t.amount.abs();
    }

    // Sort by month and convert to list
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    return sortedMonths.map((month) {
      return {
        'month': month,
        'amount': monthlyTotals[month],
      };
    }).toList();
  }

  Map<String, double> _buildCategoryTrends(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};

    // Get last 3 months of data
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    final recentTransactions = transactions.where(
      (t) => t.date.isAfter(threeMonthsAgo),
    );

    for (final t in recentTransactions) {
      final category = t.categoryName ?? 'Other';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + t.amount.abs();
    }

    // Calculate monthly averages
    final categoryAverages = <String, double>{};
    categoryTotals.forEach((category, total) {
      categoryAverages[category] = total / 3; // Divide by 3 months
    });

    return categoryAverages;
  }

  SpendingPrediction _buildDefaultPrediction(List<Transaction> transactions) {
    // Calculate simple average from available data - use all transactions
    final totalExpenses =
        transactions.fold<double>(0, (sum, t) => sum + t.amount.abs());

    // Get unique months
    final months = <String>{};
    for (final t in transactions) {
      months.add('${t.date.year}-${t.date.month}');
    }

    final monthCount = months.isNotEmpty ? months.length : 1;
    final avgMonthlySpending = totalExpenses / monthCount;

    // Build category predictions
    final categoryTotals = <String, double>{};
    for (final t in transactions) {
      final category = t.categoryName ?? 'Other';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + t.amount.abs();
    }

    final categoryPredictions = <String, CategoryPrediction>{};
    categoryTotals.forEach((category, total) {
      categoryPredictions[category] = CategoryPrediction(
        amount: total / monthCount,
        changePercent: 0,
      );
    });

    return SpendingPrediction(
      predictedAmount: avgMonthlySpending,
      confidenceScore: 50,
      period: 'next_month',
      trend: SpendingTrendType.stable,
      categoryPredictions: categoryPredictions,
      insights: [
        'Prediction based on historical average',
        'Add more transactions for better accuracy',
      ],
      predictedAt: DateTime.now(),
    );
  }
}
