import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/ai_insights/domain/repositories/ai_insights_repository.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Use case for analyzing spending patterns
class AnalyzeSpendingPatternUseCase {
  final AIInsightsRepository repository;

  AnalyzeSpendingPatternUseCase(this.repository);

  Future<SpendingPattern> call({
    required String userId,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return repository.analyzeSpendingPatterns(
      userId: userId,
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
