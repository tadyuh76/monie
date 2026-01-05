import 'package:equatable/equatable.dart';
import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';

/// States for SpendingPatternBloc
abstract class SpendingPatternState extends Equatable {
  const SpendingPatternState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SpendingPatternInitial extends SpendingPatternState {}

/// Loading state
class SpendingPatternLoading extends SpendingPatternState {}

/// Success state with loaded pattern
class SpendingPatternLoaded extends SpendingPatternState {
  final SpendingPattern pattern;

  const SpendingPatternLoaded(this.pattern);

  @override
  List<Object?> get props => [pattern];
}

/// Error state
class SpendingPatternError extends SpendingPatternState {
  final String message;

  const SpendingPatternError(this.message);

  @override
  List<Object?> get props => [message];
}

/// No data available state
class SpendingPatternNoData extends SpendingPatternState {
  final String message;

  const SpendingPatternNoData([this.message = 'Not enough transaction data to analyze']);

  @override
  List<Object?> get props => [message];
}
