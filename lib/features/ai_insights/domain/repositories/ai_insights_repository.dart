import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Repository interface for AI insights operations
abstract class AIInsightsRepository {
  /// Analyze spending patterns for a user
  Future<SpendingPattern> analyzeSpendingPatterns({
    required String userId,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get cached spending pattern if available
  Future<SpendingPattern?> getCachedPattern(String userId);

  /// Clear cached pattern
  Future<void> clearCache(String userId);
}
