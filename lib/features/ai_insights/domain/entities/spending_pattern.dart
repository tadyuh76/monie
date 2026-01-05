import 'package:equatable/equatable.dart';

/// Entity representing spending pattern analysis results
class SpendingPattern extends Equatable {
  final String summary;
  final String topCategory;
  final SpendingTrend spendingTrend;
  final List<String> unusualPatterns;
  final List<String> recommendations;
  final int financialHealthScore;
  final SpendingInsights insights;
  final DateTime analyzedAt;
  
  // New fields for enhanced spending analysis
  final double totalSpending;
  final double dailyAverage;
  final String peakSpendingDay;
  final String peakSpendingHour;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, CategorySpending> categoryBreakdown;
  final String? aiSummary;
  final bool isCached;

  const SpendingPattern({
    required this.summary,
    required this.topCategory,
    required this.spendingTrend,
    required this.unusualPatterns,
    required this.recommendations,
    required this.financialHealthScore,
    required this.insights,
    required this.analyzedAt,
    this.totalSpending = 0,
    this.dailyAverage = 0,
    this.peakSpendingDay = '',
    this.peakSpendingHour = '',
    DateTime? periodStart,
    DateTime? periodEnd,
    this.categoryBreakdown = const {},
    this.aiSummary,
    this.isCached = false,
  })  : periodStart = periodStart ?? const _DefaultDateTime(),
        periodEnd = periodEnd ?? const _DefaultDateTime();

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      summary: json['summary'] ?? '',
      topCategory: json['topCategory'] ?? '',
      spendingTrend: SpendingTrend.fromString(json['spendingTrend'] ?? 'stable'),
      unusualPatterns: List<String>.from(json['unusualPatterns'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      financialHealthScore: (json['financialHealthScore'] ?? 50).toInt(),
      insights: SpendingInsights.fromJson(json['insights'] ?? {}),
      analyzedAt: DateTime.now(),
      totalSpending: (json['totalSpending'] ?? 0).toDouble(),
      dailyAverage: (json['dailyAverage'] ?? 0).toDouble(),
      peakSpendingDay: json['peakSpendingDay'] ?? '',
      peakSpendingHour: json['peakSpendingHour'] ?? '',
      periodStart: json['periodStart'] != null 
          ? DateTime.parse(json['periodStart']) 
          : DateTime.now(),
      periodEnd: json['periodEnd'] != null 
          ? DateTime.parse(json['periodEnd']) 
          : DateTime.now(),
      categoryBreakdown: (json['categoryBreakdown'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, CategorySpending.fromJson(v))) ?? {},
      aiSummary: json['aiSummary'],
      isCached: json['isCached'] ?? false,
    );
  }

  /// Get health score message based on score
  String get healthScoreMessage {
    if (financialHealthScore >= 80) {
      return "Excellent! You're managing your finances very well.";
    } else if (financialHealthScore >= 60) {
      return "You're doing well! There's room for some improvements to optimize your spending.";
    } else if (financialHealthScore >= 40) {
      return "Fair performance. Consider reviewing your spending habits.";
    } else {
      return "Needs attention. Let's work on improving your financial health.";
    }
  }

  /// Get health score label
  String get healthScoreLabel {
    if (financialHealthScore >= 80) return 'Excellent';
    if (financialHealthScore >= 60) return 'Good';
    if (financialHealthScore >= 40) return 'Fair';
    return 'Needs Work';
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'topCategory': topCategory,
      'spendingTrend': spendingTrend.value,
      'unusualPatterns': unusualPatterns,
      'recommendations': recommendations,
      'financialHealthScore': financialHealthScore,
      'insights': insights.toJson(),
      'analyzedAt': analyzedAt.toIso8601String(),
      'totalSpending': totalSpending,
      'dailyAverage': dailyAverage,
      'peakSpendingDay': peakSpendingDay,
      'peakSpendingHour': peakSpendingHour,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'categoryBreakdown': categoryBreakdown.map((k, v) => MapEntry(k, v.toJson())),
      'aiSummary': aiSummary,
      'isCached': isCached,
    };
  }

  SpendingPattern copyWith({
    String? summary,
    String? topCategory,
    SpendingTrend? spendingTrend,
    List<String>? unusualPatterns,
    List<String>? recommendations,
    int? financialHealthScore,
    SpendingInsights? insights,
    DateTime? analyzedAt,
    double? totalSpending,
    double? dailyAverage,
    String? peakSpendingDay,
    String? peakSpendingHour,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, CategorySpending>? categoryBreakdown,
    String? aiSummary,
    bool? isCached,
  }) {
    return SpendingPattern(
      summary: summary ?? this.summary,
      topCategory: topCategory ?? this.topCategory,
      spendingTrend: spendingTrend ?? this.spendingTrend,
      unusualPatterns: unusualPatterns ?? this.unusualPatterns,
      recommendations: recommendations ?? this.recommendations,
      financialHealthScore: financialHealthScore ?? this.financialHealthScore,
      insights: insights ?? this.insights,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      totalSpending: totalSpending ?? this.totalSpending,
      dailyAverage: dailyAverage ?? this.dailyAverage,
      peakSpendingDay: peakSpendingDay ?? this.peakSpendingDay,
      peakSpendingHour: peakSpendingHour ?? this.peakSpendingHour,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      aiSummary: aiSummary ?? this.aiSummary,
      isCached: isCached ?? this.isCached,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        topCategory,
        spendingTrend,
        unusualPatterns,
        recommendations,
        financialHealthScore,
        insights,
        analyzedAt,
        totalSpending,
        dailyAverage,
        peakSpendingDay,
        peakSpendingHour,
        periodStart,
        periodEnd,
        categoryBreakdown,
        aiSummary,
        isCached,
      ];
}

/// Helper class for default DateTime in const constructor
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

/// Category spending breakdown
class CategorySpending extends Equatable {
  final double amount;
  final double percentage;

  const CategorySpending({
    required this.amount,
    required this.percentage,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'percentage': percentage,
    };
  }

  @override
  List<Object?> get props => [amount, percentage];
}

enum SpendingTrend {
  increasing('increasing'),
  decreasing('decreasing'),
  stable('stable');

  final String value;
  const SpendingTrend(this.value);

  static SpendingTrend fromString(String value) {
    switch (value.toLowerCase()) {
      case 'increasing':
        return SpendingTrend.increasing;
      case 'decreasing':
        return SpendingTrend.decreasing;
      default:
        return SpendingTrend.stable;
    }
  }
}

class SpendingInsights extends Equatable {
  final String bestPerformingArea;
  final List<String> areasForImprovement;
  final String seasonalObservations;

  const SpendingInsights({
    required this.bestPerformingArea,
    required this.areasForImprovement,
    required this.seasonalObservations,
  });

  factory SpendingInsights.fromJson(Map<String, dynamic> json) {
    return SpendingInsights(
      bestPerformingArea: json['bestPerformingArea'] ?? '',
      areasForImprovement: List<String>.from(json['areasForImprovement'] ?? []),
      seasonalObservations: json['seasonalObservations'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestPerformingArea': bestPerformingArea,
      'areasForImprovement': areasForImprovement,
      'seasonalObservations': seasonalObservations,
    };
  }

  @override
  List<Object?> get props => [
        bestPerformingArea,
        areasForImprovement,
        seasonalObservations,
      ];
}
