import 'package:flutter/foundation.dart';
import 'package:monie/features/ai_insights/data/datasources/ai_insights_datasource.dart';
import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/ai_insights/domain/repositories/ai_insights_repository.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Implementation of AIInsightsRepository
class AIInsightsRepositoryImpl implements AIInsightsRepository {
  final AIInsightsDataSource _dataSource;
  
  // Simple in-memory cache
  final Map<String, SpendingPattern> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheValidityDuration = Duration(hours: 24);

  AIInsightsRepositoryImpl(this._dataSource);

  @override
  Future<SpendingPattern> analyzeSpendingPatterns({
    required String userId,
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    debugPrint('📊 AIInsightsRepository: Analyzing patterns for user $userId');

    // Check cache first
    final cached = await getCachedPattern(userId);
    if (cached != null) {
      debugPrint('✅ AIInsightsRepository: Returning cached pattern');
      return cached;
    }

    // Get fresh analysis
    final pattern = await _dataSource.analyzeSpendingPatterns(
      transactions: transactions,
      startDate: startDate,
      endDate: endDate,
    );

    // Cache the result
    _cache[userId] = pattern;
    _cacheTimestamps[userId] = DateTime.now();

    return pattern;
  }

  @override
  Future<SpendingPattern?> getCachedPattern(String userId) async {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return null;

    final age = DateTime.now().difference(timestamp);
    if (age > _cacheValidityDuration) {
      // Cache expired
      _cache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }

    return _cache[userId];
  }

  @override
  Future<void> clearCache(String userId) async {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
    debugPrint('🗑️ AIInsightsRepository: Cache cleared for user $userId');
  }
}
