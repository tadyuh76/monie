import 'package:equatable/equatable.dart';

/// Events for SpendingPatternBloc
abstract class SpendingPatternEvent extends Equatable {
  const SpendingPatternEvent();

  @override
  List<Object?> get props => [];
}

/// Event to analyze spending patterns
class AnalyzeSpendingPatternEvent extends SpendingPatternEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const AnalyzeSpendingPatternEvent({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Event to clear cached analysis
class ClearSpendingPatternCacheEvent extends SpendingPatternEvent {
  final String userId;

  const ClearSpendingPatternCacheEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh analysis
class RefreshSpendingPatternEvent extends SpendingPatternEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const RefreshSpendingPatternEvent({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}
