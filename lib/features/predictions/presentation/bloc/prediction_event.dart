import 'package:equatable/equatable.dart';

/// Events for PredictionBloc
abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to generate spending prediction
class GeneratePredictionEvent extends PredictionEvent {
  final String userId;
  final String period;

  const GeneratePredictionEvent({
    required this.userId,
    this.period = 'next_month',
  });

  @override
  List<Object?> get props => [userId, period];
}

/// Event to refresh prediction
class RefreshPredictionEvent extends PredictionEvent {
  final String userId;
  final String period;

  const RefreshPredictionEvent({
    required this.userId,
    this.period = 'next_month',
  });

  @override
  List<Object?> get props => [userId, period];
}

/// Event to clear prediction
class ClearPredictionEvent extends PredictionEvent {
  const ClearPredictionEvent();
}
