import 'package:equatable/equatable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetsLoaded extends BudgetState {
  final List<Budget> budgets;

  const BudgetsLoaded(this.budgets);

  @override
  List<Object?> get props => [budgets];
}

class BudgetLoaded extends BudgetState {
  final Budget budget;

  const BudgetLoaded(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetCreated extends BudgetState {
  final Budget budget;

  const BudgetCreated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetUpdated extends BudgetState {
  final Budget budget;

  const BudgetUpdated(this.budget);

  @override
  List<Object?> get props => [budget];
}

class BudgetDeleted extends BudgetState {
  final String budgetId;

  const BudgetDeleted(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}
