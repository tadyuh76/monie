import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/ai_insights/domain/repositories/ai_insights_repository.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_event.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_state.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

/// BLoC for managing spending pattern analysis
class SpendingPatternBloc
    extends Bloc<SpendingPatternEvent, SpendingPatternState> {
  final AIInsightsRepository _aiInsightsRepository;
  final TransactionRepository _transactionRepository;

  SpendingPatternBloc({
    required AIInsightsRepository aiInsightsRepository,
    required TransactionRepository transactionRepository,
  })  : _aiInsightsRepository = aiInsightsRepository,
        _transactionRepository = transactionRepository,
        super(SpendingPatternInitial()) {
    on<AnalyzeSpendingPatternEvent>(_onAnalyzePattern);
    on<ClearSpendingPatternCacheEvent>(_onClearCache);
    on<RefreshSpendingPatternEvent>(_onRefreshPattern);
  }

  Future<void> _onAnalyzePattern(
    AnalyzeSpendingPatternEvent event,
    Emitter<SpendingPatternState> emit,
  ) async {
    try {
      emit(SpendingPatternLoading());
      debugPrint('📊 SpendingPatternBloc: Starting analysis...');

      // Get transactions for the period filtered by userId
      final transactions = await _transactionRepository.getTransactionsByDateRange(
        event.userId,
        event.startDate,
        event.endDate,
      );

      if (transactions.isEmpty) {
        debugPrint('❌ SpendingPatternBloc: No transactions found');
        emit(const SpendingPatternNoData());
        return;
      }

      // Check minimum data requirement
      if (transactions.length < 5) {
        debugPrint('❌ SpendingPatternBloc: Not enough transactions');
        emit(const SpendingPatternNoData(
          'At least 5 transactions are needed for AI analysis',
        ));
        return;
      }

      // Analyze patterns
      final pattern = await _aiInsightsRepository.analyzeSpendingPatterns(
        userId: event.userId,
        transactions: transactions,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      debugPrint('✅ SpendingPatternBloc: Analysis complete');
      emit(SpendingPatternLoaded(pattern));
    } catch (e) {
      debugPrint('❌ SpendingPatternBloc Error: $e');
      emit(SpendingPatternError(e.toString()));
    }
  }

  Future<void> _onClearCache(
    ClearSpendingPatternCacheEvent event,
    Emitter<SpendingPatternState> emit,
  ) async {
    await _aiInsightsRepository.clearCache(event.userId);
    emit(SpendingPatternInitial());
  }

  Future<void> _onRefreshPattern(
    RefreshSpendingPatternEvent event,
    Emitter<SpendingPatternState> emit,
  ) async {
    // Clear cache first, then analyze
    await _aiInsightsRepository.clearCache(event.userId);
    add(AnalyzeSpendingPatternEvent(
      userId: event.userId,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
  }
}
