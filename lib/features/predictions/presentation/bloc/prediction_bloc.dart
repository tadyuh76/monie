import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/predictions/data/datasources/prediction_datasource.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_event.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_state.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

/// BLoC for managing spending predictions
class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final PredictionDataSource _dataSource;
  final TransactionRepository _transactionRepository;

  PredictionBloc({
    required PredictionDataSource dataSource,
    required TransactionRepository transactionRepository,
  })  : _dataSource = dataSource,
        _transactionRepository = transactionRepository,
        super(PredictionInitial()) {
    on<GeneratePredictionEvent>(_onGeneratePrediction);
    on<RefreshPredictionEvent>(_onRefreshPrediction);
    on<ClearPredictionEvent>(_onClearPrediction);
  }

  Future<void> _onGeneratePrediction(
    GeneratePredictionEvent event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(PredictionLoading());
      debugPrint('🔮 PredictionBloc: Generating prediction...');

      // Get all transactions
      final transactions =
          await _transactionRepository.getTransactions(event.userId);

      debugPrint('🔮 PredictionBloc: Found ${transactions.length} total transactions');

      if (transactions.isEmpty) {
        emit(const PredictionNoData('No transactions found'));
        return;
      }
      
      // Need at least 5 transactions for any kind of prediction
      if (transactions.length < 5) {
        emit(PredictionNoData(
          'At least 5 transactions are needed for prediction. Found: ${transactions.length}',
        ));
        return;
      }

      // Generate prediction
      final prediction = await _dataSource.predictSpending(
        transactions: transactions,
        period: event.period,
      );

      debugPrint('✅ PredictionBloc: Prediction generated');
      emit(PredictionLoaded(prediction));
    } catch (e) {
      debugPrint('❌ PredictionBloc Error: $e');
      emit(PredictionError(e.toString()));
    }
  }

  Future<void> _onRefreshPrediction(
    RefreshPredictionEvent event,
    Emitter<PredictionState> emit,
  ) async {
    add(GeneratePredictionEvent(
      userId: event.userId,
      period: event.period,
    ));
  }

  Future<void> _onClearPrediction(
    ClearPredictionEvent event,
    Emitter<PredictionState> emit,
  ) async {
    emit(PredictionInitial());
  }
}
