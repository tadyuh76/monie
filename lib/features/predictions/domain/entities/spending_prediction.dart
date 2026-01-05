import 'package:equatable/equatable.dart';

/// Entity representing spending prediction
class SpendingPrediction extends Equatable {
  final double predictedAmount;
  final int confidenceScore;
  final String period;
  final SpendingTrendType trend;
  final Map<String, CategoryPrediction> categoryPredictions;
  final List<String> insights;
  final DateTime predictedAt;

  const SpendingPrediction({
    required this.predictedAmount,
    required this.confidenceScore,
    required this.period,
    required this.trend,
    required this.categoryPredictions,
    required this.insights,
    required this.predictedAt,
  });

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    final categoryPredictionsJson =
        json['categoryPredictions'] as Map<String, dynamic>? ?? {};
    final categoryPredictions = <String, CategoryPrediction>{};

    categoryPredictionsJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        categoryPredictions[key] = CategoryPrediction.fromJson(value);
      }
    });

    return SpendingPrediction(
      predictedAmount: (json['predictedAmount'] ?? 0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 50).toInt(),
      period: json['period'] ?? 'next_month',
      trend: SpendingTrendType.fromString(json['trend'] ?? 'stable'),
      categoryPredictions: categoryPredictions,
      insights: List<String>.from(json['insights'] ?? []),
      predictedAt: DateTime.now(),
    );
  }

  String get confidenceLabel {
    if (confidenceScore >= 80) return 'High';
    if (confidenceScore >= 60) return 'Medium';
    return 'Low';
  }

  @override
  List<Object?> get props => [
        predictedAmount,
        confidenceScore,
        period,
        trend,
        categoryPredictions,
        insights,
        predictedAt,
      ];
}

enum SpendingTrendType {
  increasing('increasing'),
  decreasing('decreasing'),
  stable('stable');

  final String value;
  const SpendingTrendType(this.value);

  static SpendingTrendType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'increasing':
        return SpendingTrendType.increasing;
      case 'decreasing':
        return SpendingTrendType.decreasing;
      default:
        return SpendingTrendType.stable;
    }
  }
}

class CategoryPrediction extends Equatable {
  final double amount;
  final double changePercent;

  const CategoryPrediction({
    required this.amount,
    required this.changePercent,
  });

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      amount: (json['amount'] ?? 0).toDouble(),
      changePercent: (json['change'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [amount, changePercent];
}
