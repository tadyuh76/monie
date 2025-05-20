import 'package:equatable/equatable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetsEvent extends BudgetEvent {
  final String userId;

  const LoadBudgetsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadBudgetByIdEvent extends BudgetEvent {
  final String budgetId;

  const LoadBudgetByIdEvent(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

class CreateBudgetEvent extends BudgetEvent {
  final Budget budget;

  const CreateBudgetEvent(this.budget);

  @override
  List<Object?> get props => [budget];
}

class UpdateBudgetEvent extends BudgetEvent {
  final Budget budget;

  const UpdateBudgetEvent(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudgetEvent extends BudgetEvent {
  final String budgetId;

  const DeleteBudgetEvent(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}
