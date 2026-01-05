import 'package:equatable/equatable.dart';
import 'package:monie/features/predictions/domain/entities/spending_prediction.dart';

/// States for PredictionBloc
abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PredictionInitial extends PredictionState {}

/// Loading state
class PredictionLoading extends PredictionState {}

/// Loaded state with prediction
class PredictionLoaded extends PredictionState {
  final SpendingPrediction prediction;

  const PredictionLoaded(this.prediction);

  @override
  List<Object?> get props => [prediction];
}

/// Error state
class PredictionError extends PredictionState {
  final String message;

  const PredictionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// No data available
class PredictionNoData extends PredictionState {
  final String message;

  const PredictionNoData([this.message = 'Not enough data for prediction']);

  @override
  List<Object?> get props => [message];
}
